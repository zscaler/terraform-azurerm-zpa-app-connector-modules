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
}


################################################################################
# 3. (Provisioning key flow only) Create the ZPA App Connector Group and
#    Provisioning Key up front so the key can be baked into the VM user_data.
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
# 4. (OAuth2 flow only) Create a Key Vault to relay OAuth2 user codes. VMs write
#    their /etc/issue code via Managed Identity; Terraform reads it back.
################################################################################
locals {
  # Deterministic Key Vault name computed up front (not from the module output)
  # so it can be injected into VM user_data AND passed to the Key Vault module
  # without creating a dependency cycle (KV -> VM identity -> user_data -> KV).
  # Key Vault names must be globally unique, 3-24 chars, alphanumeric + dashes.
  generated_kv_name = substr("zsac-kv-${random_string.suffix.result}", 0, 24)

  # Key Vault name used by the VM bootstrap to publish OAuth2 codes.
  key_vault_name = local.use_provisioning_key ? "" : (
    var.byo_key_vault ? var.byo_key_vault_name : local.generated_kv_name
  )

  # Per-VM OAuth2 secret names (fixed-VM flow uses pre-defined names).
  oauth_secret_names = [for i in range(var.ac_count) :
    "${var.name_prefix}-${var.arm_location}-ac-${i + 1}-${random_string.suffix.result}"
  ]
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
  vm_identity_principal_ids = module.ac_vm.ac_vm_identity_principal_ids
}


################################################################################
# 5. Generate per-VM user_data via the centralized scripts. The onboarding
#    method flag selects OAuth2 (Key Vault) vs provisioning key bootstrap logic.
################################################################################
locals {
  provisioning_key_value = local.use_provisioning_key ? try(module.zpa_provisioning_key[0].provisioning_key, "") : ""
  user_data_script       = var.use_zscaler_image ? "${path.module}/../../scripts/user_data_zscaler.sh" : "${path.module}/../../scripts/user_data_rhel9.sh"

  appuserdata = [for i in range(var.ac_count) :
    templatefile(local.user_data_script, {
      onboarding_method          = local.use_provisioning_key ? "provisioning_key" : "oauth"
      provisioning_key           = local.provisioning_key_value
      key_vault_name             = local.key_vault_name
      secret_name                = local.use_provisioning_key ? "" : local.oauth_secret_names[i]
      secret_name_prefix         = "" # Not used for fixed VMs
      is_vmss                    = false
      managed_identity_client_id = "" # Fixed VMs use the system-assigned identity
    })
  ]
}


################################################################################
# 6. Create specified number of AC appliances
################################################################################
module "ac_vm" {
  source               = "../../modules/terraform-zsac-acvm-azure"
  ac_count             = var.ac_count
  name_prefix          = coalesce(var.custom_name, "${var.name_prefix}-${var.arm_location}-${module.network.resource_group_name}")
  resource_tag         = random_string.suffix.result
  global_tags          = local.global_tags
  resource_group       = module.network.resource_group_name
  ac_subnet_id         = module.network.ac_subnet_ids
  ssh_key              = tls_private_key.key.public_key_openssh
  user_data            = local.appuserdata
  location             = var.arm_location
  zones_enabled        = var.zones_enabled
  zones                = var.zones
  acvm_instance_type   = var.acvm_instance_type
  acvm_image_publisher = var.acvm_image_publisher
  acvm_image_offer     = var.acvm_image_offer
  acvm_image_sku       = var.acvm_image_sku

  accept_marketplace_agreement = var.accept_marketplace_agreement
  acvm_image_version           = var.acvm_image_version
  ac_nsg_id                    = module.ac_nsg.ac_nsg_id

  depends_on = [
    module.zpa_provisioning_key,
  ]
}


################################################################################
# 7. Create Network Security Group(s) for the App Connector interface(s)
################################################################################
module "ac_nsg" {
  source         = "../../modules/terraform-zsac-nsg-azure"
  nsg_count      = var.reuse_nsg == false ? var.ac_count : 1
  name_prefix    = coalesce(var.custom_name, "${var.name_prefix}-${var.arm_location}-${module.network.resource_group_name}")
  resource_tag   = random_string.suffix.result
  resource_group = var.byo_nsg == false ? module.network.resource_group_name : var.byo_nsg_rg
  location       = var.arm_location
  global_tags    = local.global_tags

  byo_nsg       = var.byo_nsg
  byo_nsg_names = var.byo_nsg_names
}


################################################################################
# 8. (OAuth2 flow only) Wait for VMs to publish their OAuth2 user codes to Key
#    Vault, then read them back and create the App Connector Group with the
#    collected user_codes.
################################################################################
resource "time_sleep" "wait_for_oauth_tokens" {
  count           = local.use_provisioning_key ? 0 : 1
  depends_on      = [module.ac_vm, module.oauth_key_vault]
  create_duration = "${var.oauth_token_wait_seconds}s"
}

data "azurerm_key_vault" "oauth" {
  count               = local.use_provisioning_key ? 0 : 1
  name                = local.key_vault_name
  resource_group_name = var.byo_key_vault ? var.byo_key_vault_rg : module.network.resource_group_name
  depends_on          = [time_sleep.wait_for_oauth_tokens]
}

data "azurerm_key_vault_secret" "oauth_tokens" {
  count        = local.use_provisioning_key ? 0 : var.ac_count
  name         = local.oauth_secret_names[count.index]
  key_vault_id = data.azurerm_key_vault.oauth[0].id
  depends_on   = [time_sleep.wait_for_oauth_tokens]
}

locals {
  user_codes = local.use_provisioning_key ? [] : [for i in range(var.ac_count) : data.azurerm_key_vault_secret.oauth_tokens[i].value]
}


################################################################################
# 9. (OAuth2 flow only) Create the ZPA App Connector Group with OAuth2 user
#    codes. Created AFTER the codes are available in Key Vault.
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
    data.azurerm_key_vault_secret.oauth_tokens,
  ]
}
