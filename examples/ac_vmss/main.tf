################################################################################
# Generate a unique random string for resource name assignment and key pair
################################################################################
resource "random_string" "suffix" {
  length  = 8
  upper   = false
  special = false
}


################################################################################
# Map default tags with values to be assigned to all tagged resources
################################################################################
locals {
  global_tags = {
    Owner       = var.owner_tag
    ManagedBy   = "terraform"
    Vendor      = "Zscaler"
    Environment = var.environment
  }

  # Onboarding method switch. Default is OAuth2; set onboarding_method to
  # "provisioning_key" (or byo_provisioning_key = true) to use the legacy
  # provisioning key flow instead.
  use_provisioning_key = var.onboarding_method == "provisioning_key" || var.byo_provisioning_key
}

# Current client/tenant context for Key Vault tenant + deployer RBAC grants.
data "azurerm_client_config" "current" {}


################################################################################
# Generate a new SSH key pair and store the PEM file locally. Not recommended
# for production; pass your own public key for real deployments.
################################################################################
resource "tls_private_key" "key" {
  algorithm = var.tls_key_algorithm
}

resource "local_file" "private_key" {
  content         = tls_private_key.key.private_key_pem
  filename        = coalesce(var.custom_name, "../${var.name_prefix}-key-${random_string.suffix.result}.pem")
  file_permission = "0600"
}


################################################################################
# 1. Create/reference all network infrastructure resource dependencies
################################################################################
module "network" {
  source                = "../../modules/terraform-zsac-network-azure"
  name_prefix           = coalesce(var.custom_name, var.name_prefix)
  resource_tag          = random_string.suffix.result
  global_tags           = local.global_tags
  location              = var.arm_location
  network_address_space = var.network_address_space
  ac_subnets            = var.ac_subnets
  public_subnets        = var.public_subnets
  zones_enabled         = var.zones_enabled
  zones                 = var.zones

  byo_rg                             = var.byo_rg
  byo_rg_name                        = var.byo_rg_name
  byo_vnet                           = var.byo_vnet
  byo_vnet_name                      = var.byo_vnet_name
  byo_subnets                        = var.byo_subnets
  byo_subnet_names                   = var.byo_subnet_names
  byo_vnet_subnets_rg_name           = var.byo_vnet_subnets_rg_name
  byo_pips                           = var.byo_pips
  byo_pip_names                      = var.byo_pip_names
  byo_pip_rg                         = var.byo_pip_rg
  byo_nat_gws                        = var.byo_nat_gws
  byo_nat_gw_names                   = var.byo_nat_gw_names
  byo_nat_gw_rg                      = var.byo_nat_gw_rg
  existing_nat_gw_pip_association    = var.existing_nat_gw_pip_association
  existing_nat_gw_subnet_association = var.existing_nat_gw_subnet_association
}


################################################################################
# 2. Generate App Connector Group name with template variable support
################################################################################
locals {
  default_ac_group_name = "${var.arm_location}-${module.network.resource_group_name}"

  custom_ac_group_name = var.app_connector_group_name != "" ? replace(
    replace(
      replace(var.app_connector_group_name, "{region}", var.arm_location),
      "{name_prefix}", var.name_prefix
    ),
    "{random_suffix}", random_string.suffix.result
  ) : coalesce(var.custom_name, local.default_ac_group_name)

  # Unique per-deployment prefix used to name OAuth2 secrets written by each
  # scale-set instance. Each instance appends its own Azure resource name at
  # boot so concurrent scale-out instances never collide.
  oauth_secret_prefix = "${var.name_prefix}-${var.arm_location}-acvmss-${random_string.suffix.result}"
}


################################################################################
# 3. (Provisioning key flow only) Create the ZPA App Connector Group and
#    Provisioning Key up front so the key can be baked into the VMSS user_data.
################################################################################
module "zpa_app_connector_group_pk" {
  count                                        = local.use_provisioning_key && var.byo_provisioning_key == false ? 1 : 0
  source                                       = "../../modules/terraform-zpa-app-connector-group"
  app_connector_group_name                     = local.custom_ac_group_name
  app_connector_group_description              = "${var.app_connector_group_description}-${var.arm_location}-${module.network.resource_group_name}"
  app_connector_group_enabled                  = var.app_connector_group_enabled
  app_connector_group_country_code             = var.app_connector_group_country_code
  app_connector_group_city_country             = var.app_connector_group_city_country
  app_connector_group_latitude                 = var.app_connector_group_latitude
  app_connector_group_longitude                = var.app_connector_group_longitude
  app_connector_group_location                 = var.app_connector_group_location
  app_connector_group_upgrade_day              = var.app_connector_group_upgrade_day
  app_connector_group_upgrade_time_in_secs     = var.app_connector_group_upgrade_time_in_secs
  app_connector_group_override_version_profile = var.app_connector_group_override_version_profile
  app_connector_group_version_profile_id       = var.app_connector_group_version_profile_id
  app_connector_group_dns_query_type           = var.app_connector_group_dns_query_type
}

module "zpa_provisioning_key" {
  count                             = local.use_provisioning_key ? 1 : 0
  source                            = "../../modules/terraform-zpa-provisioning-key"
  provisioning_key_name             = var.provisioning_key_name != "" ? var.provisioning_key_name : local.custom_ac_group_name
  provisioning_key_enabled          = var.provisioning_key_enabled
  provisioning_key_association_type = var.provisioning_key_association_type
  provisioning_key_max_usage        = var.provisioning_key_max_usage
  app_connector_group_id            = try(module.zpa_app_connector_group_pk[0].app_connector_group_id, "")
  byo_provisioning_key              = var.byo_provisioning_key
  byo_provisioning_key_name         = var.byo_provisioning_key_name
}


################################################################################
# 4. (OAuth2 flow only) Create a Key Vault to relay OAuth2 user codes. A
#    User-assigned Managed Identity is created up front (orchestrated VMSS only
#    supports UserAssigned identities) and granted Key Vault access; scale-set
#    instances assume it to write their /etc/issue code. Terraform reads the
#    codes back by listing secrets that match the deployment prefix.
################################################################################
locals {
  generated_kv_name = substr("zsac-kv-${random_string.suffix.result}", 0, 24)

  key_vault_name = local.use_provisioning_key ? "" : (
    var.byo_key_vault ? var.byo_key_vault_name : local.generated_kv_name
  )
}

# User-assigned identity attached to the scale set for the OAuth2 flow.
resource "azurerm_user_assigned_identity" "vmss_oauth" {
  count               = local.use_provisioning_key ? 0 : 1
  name                = "${var.name_prefix}-acvmss-oauth-${random_string.suffix.result}"
  resource_group_name = module.network.resource_group_name
  location            = var.arm_location
  tags                = local.global_tags
}

module "oauth_key_vault" {
  count          = local.use_provisioning_key || var.byo_key_vault ? 0 : 1
  source         = "../../modules/terraform-zsac-keyvault-azure"
  name_prefix    = coalesce(var.custom_name, var.name_prefix)
  resource_tag   = random_string.suffix.result
  global_tags    = local.global_tags
  key_vault_name = local.generated_kv_name

  resource_group            = module.network.resource_group_name
  location                  = var.arm_location
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  deployer_object_id        = data.azurerm_client_config.current.object_id
  vm_identity_principal_ids = [azurerm_user_assigned_identity.vmss_oauth[0].principal_id]
}


################################################################################
# 5. Generate VMSS user_data via the centralized scripts. All instances share
#    the same script; each derives a unique Key Vault secret name at boot.
################################################################################
locals {
  provisioning_key_value = local.use_provisioning_key ? try(module.zpa_provisioning_key[0].provisioning_key, "") : ""
  user_data_script       = var.use_zscaler_image ? "${path.module}/../../scripts/user_data_zscaler.sh" : "${path.module}/../../scripts/user_data_rhel9.sh"

  appuserdata = templatefile(local.user_data_script, {
    onboarding_method          = local.use_provisioning_key ? "provisioning_key" : "oauth"
    provisioning_key           = local.provisioning_key_value
    key_vault_name             = local.key_vault_name
    secret_name                = ""
    secret_name_prefix         = local.oauth_secret_prefix
    is_vmss                    = true
    managed_identity_client_id = local.use_provisioning_key ? "" : azurerm_user_assigned_identity.vmss_oauth[0].client_id
  })
}


################################################################################
# 6. Create the App Connector VM Scale Set
################################################################################
module "ac_vmss" {
  source                     = "../../modules/terraform-zsac-acvmss-azure"
  name_prefix                = coalesce(var.custom_name, "${var.name_prefix}-${var.arm_location}-${module.network.resource_group_name}")
  resource_tag               = random_string.suffix.result
  global_tags                = local.global_tags
  resource_group             = module.network.resource_group_name
  ac_subnet_id               = module.network.ac_subnet_ids
  ssh_key                    = tls_private_key.key.public_key_openssh
  user_data                  = local.appuserdata
  location                   = var.arm_location
  zones_enabled              = var.zones_enabled
  zones                      = var.zones
  acvm_instance_type         = var.acvm_instance_type
  acvm_image_publisher       = var.acvm_image_publisher
  acvm_image_offer           = var.acvm_image_offer
  acvm_image_sku             = var.acvm_image_sku
  acvm_image_version         = var.acvm_image_version
  ac_nsg_id                  = module.ac_nsg.ac_nsg_id[0]
  encryption_at_host_enabled = var.encryption_at_host_enabled
  identity_ids               = local.use_provisioning_key ? [] : [azurerm_user_assigned_identity.vmss_oauth[0].id]

  vmss_default_acs            = var.vmss_default_acs
  vmss_min_acs                = var.vmss_min_acs
  vmss_max_acs                = var.vmss_max_acs
  scale_out_threshold         = var.scale_out_threshold
  scale_in_threshold          = var.scale_in_threshold
  scale_out_cooldown          = var.scale_out_cooldown
  scale_in_cooldown           = var.scale_in_cooldown
  scale_out_evaluation_period = var.scale_out_evaluation_period
  scale_in_evaluation_period  = var.scale_in_evaluation_period
  scale_in_count              = var.scale_in_count
  scale_out_count             = var.scale_out_count

  scheduled_scaling_enabled         = var.scheduled_scaling_enabled
  scheduled_scaling_vmss_min_acs    = var.scheduled_scaling_vmss_min_acs
  scheduled_scaling_timezone        = var.scheduled_scaling_timezone
  scheduled_scaling_days_of_week    = var.scheduled_scaling_days_of_week
  scheduled_scaling_start_time_hour = var.scheduled_scaling_start_time_hour
  scheduled_scaling_start_time_min  = var.scheduled_scaling_start_time_min
  scheduled_scaling_end_time_hour   = var.scheduled_scaling_end_time_hour
  scheduled_scaling_end_time_min    = var.scheduled_scaling_end_time_min

  depends_on = [
    module.zpa_provisioning_key,
    # Boot the scale set only after the connector identity's Key Vault grant has
    # been created and given time to propagate, so an instance's first OAuth2
    # secret write at boot does not race the RBAC assignment and fail with 403.
    module.oauth_key_vault,
  ]
}


################################################################################
# 7. Create Network Security Group(s) for the App Connector interface(s)
################################################################################
module "ac_nsg" {
  source         = "../../modules/terraform-zsac-nsg-azure"
  nsg_count      = 1
  name_prefix    = coalesce(var.custom_name, "${var.name_prefix}-${var.arm_location}-${module.network.resource_group_name}")
  resource_tag   = random_string.suffix.result
  resource_group = var.byo_nsg == false ? module.network.resource_group_name : var.byo_nsg_rg
  location       = var.arm_location
  global_tags    = local.global_tags

  byo_nsg       = var.byo_nsg
  byo_nsg_names = var.byo_nsg_names
}


################################################################################
# 8. (OAuth2 flow only) Wait for scale-set instances to publish their OAuth2
#    user codes to Key Vault, then list and read back all secrets matching the
#    deployment prefix and create the App Connector Group with the codes.
################################################################################
resource "time_sleep" "wait_for_oauth_tokens" {
  count           = local.use_provisioning_key ? 0 : 1
  depends_on      = [module.ac_vmss, module.oauth_key_vault]
  create_duration = "${var.oauth_token_wait_seconds}s"
}

# Discover and read back every OAuth2 user code that the scale-set instances
# published to Key Vault. VMSS instance names are not known at plan time, so we
# cannot enumerate per-secret data sources with for_each (the key set would be
# unknown until apply, which Terraform rejects). Instead a single external data
# source uses the Azure CLI to list secrets by this deployment's prefix and read
# their values, returning them comma-joined. The value is unknown at plan
# (allowed for a single data source) and resolves at apply, mirroring the AWS
# ASG SSM discovery pattern.
data "external" "oauth_tokens" {
  count = local.use_provisioning_key ? 0 : 1

  program = ["bash", "-c", <<-EOT
    set -o pipefail
    VAULT="${local.key_vault_name}"
    PREFIX="${local.oauth_secret_prefix}"
    CACHE="${path.module}/.oauth_tokens_${random_string.suffix.result}.json"

    # Idempotence guard: OAuth2 discovery is a one-shot bootstrap step. Once the
    # codes have been read back and cached on the first apply, return them
    # verbatim on every later plan/apply instead of re-polling Key Vault. A data
    # source re-executes on every plan, so without this the idempotence re-plan
    # would re-run the (slow) poll and can blow past the CI step timeout.
    if [ -s "$CACHE" ]; then
      cat "$CACHE"
      exit 0
    fi

    # Poll until at least one matching code is published, or we time out, to
    # absorb the boot lag between an instance reaching ready and writing its
    # /etc/issue code into Key Vault.
    MAX_ATTEMPTS=24   # 24 * 30s = 12 minutes
    ATTEMPT=0
    TOKENS=""

    while [ "$ATTEMPT" -lt "$MAX_ATTEMPTS" ]; do
      NAMES=$(az keyvault secret list \
        --vault-name "$VAULT" \
        --query "[?starts_with(name, '$PREFIX')].name" \
        --output tsv 2>/dev/null || echo "")

      TOKENS=""
      for NAME in $NAMES; do
        VALUE=$(az keyvault secret show \
          --vault-name "$VAULT" \
          --name "$NAME" \
          --query value \
          --output tsv 2>/dev/null || echo "")
        if printf '%s' "$VALUE" | grep -Eq '^[A-Z0-9]{5}-[A-Z0-9]{5}$'; then
          if [ -z "$TOKENS" ]; then TOKENS="$VALUE"; else TOKENS="$TOKENS,$VALUE"; fi
        fi
      done

      if [ -n "$TOKENS" ]; then break; fi
      sleep 30
      ATTEMPT=$((ATTEMPT + 1))
    done

    RESULT=$(printf '{"tokens":"%s"}' "$TOKENS")
    # Only cache a non-empty discovery so a transient empty read is not frozen in.
    if [ -n "$TOKENS" ]; then printf '%s' "$RESULT" > "$CACHE"; fi
    printf '%s' "$RESULT"
  EOT
  ]

  depends_on = [time_sleep.wait_for_oauth_tokens]
}

locals {
  vmss_tokens_raw = local.use_provisioning_key ? "" : try(data.external.oauth_tokens[0].result.tokens, "")
  user_codes      = local.use_provisioning_key ? [] : (local.vmss_tokens_raw != "" ? split(",", local.vmss_tokens_raw) : [])
}


################################################################################
# 9. (OAuth2 flow only) Create the ZPA App Connector Group with the collected
#    OAuth2 user codes.
################################################################################
module "zpa_app_connector_group" {
  count                                        = local.use_provisioning_key ? 0 : 1
  source                                       = "../../modules/terraform-zpa-app-connector-group"
  app_connector_group_name                     = local.custom_ac_group_name
  app_connector_group_description              = "${var.app_connector_group_description}-${var.arm_location}-${module.network.resource_group_name}"
  app_connector_group_enabled                  = var.app_connector_group_enabled
  app_connector_group_country_code             = var.app_connector_group_country_code
  app_connector_group_city_country             = var.app_connector_group_city_country
  app_connector_group_latitude                 = var.app_connector_group_latitude
  app_connector_group_longitude                = var.app_connector_group_longitude
  app_connector_group_location                 = var.app_connector_group_location
  app_connector_group_upgrade_day              = var.app_connector_group_upgrade_day
  app_connector_group_upgrade_time_in_secs     = var.app_connector_group_upgrade_time_in_secs
  app_connector_group_override_version_profile = var.app_connector_group_override_version_profile
  app_connector_group_version_profile_id       = var.app_connector_group_version_profile_id
  app_connector_group_dns_query_type           = var.app_connector_group_dns_query_type
  user_codes                                   = local.user_codes

  depends_on = [
    data.external.oauth_tokens,
  ]
}
