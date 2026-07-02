################################################################################
# Key Vault used to relay OAuth2 user codes from App Connector VMs back to
# Terraform. App Connector VMs (via system-assigned Managed Identity) write
# their /etc/issue OAuth2 code into a per-instance secret; Terraform reads the
# secrets back and enrolls the connectors into the App Connector Group.
#
# RBAC authorization is used (modern Azure default) instead of legacy access
# policies. The VM identities receive "Key Vault Secrets Officer" (write) and
# the Terraform deployer receives the same role so it can create placeholder
# secrets and read the codes back during apply.
################################################################################

locals {
  # Fold the module's name_prefix / resource_tag into the resource tags so the
  # Key Vault carries the same identifying metadata as the rest of the
  # deployment's resources.
  kv_tags = merge(
    var.global_tags,
    { Name = trim("${var.name_prefix}-keyvault-${var.resource_tag}", "-") },
  )
}

resource "azurerm_key_vault" "oauth" {
  name                       = var.key_vault_name
  location                   = var.location
  resource_group_name        = var.resource_group
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  purge_protection_enabled   = var.purge_protection_enabled
  soft_delete_retention_days = var.soft_delete_retention_days

  tags = local.kv_tags
}

################################################################################
# Grant the Terraform deployer permission to manage/read OAuth2 secrets.
################################################################################
resource "azurerm_role_assignment" "deployer_secrets_officer" {
  scope                = azurerm_key_vault.oauth.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.deployer_object_id
}

# Azure RBAC role assignments are eventually consistent: the data-plane (Key
# Vault) can return 403 ForbiddenByRbac for up to a minute or two after the
# assignment is created. Without this wait the very first placeholder-secret
# write in the same apply races the propagation and fails. Consumers depend on
# the `deployer_rbac_ready` output before touching secrets.
resource "time_sleep" "wait_for_deployer_rbac" {
  depends_on      = [azurerm_role_assignment.deployer_secrets_officer]
  create_duration = var.rbac_propagation_wait
}

################################################################################
# Grant each App Connector VM/VMSS Managed Identity permission to write its
# OAuth2 user code secret.
################################################################################
resource "azurerm_role_assignment" "vm_secrets_officer" {
  count                = length(var.vm_identity_principal_ids)
  scope                = azurerm_key_vault.oauth.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.vm_identity_principal_ids[count.index]
}

# Absorb RBAC eventual-consistency for the VM identity grants the same way the
# deployer grant does. The App Connector VMs must NOT boot until this has
# propagated, otherwise the connector's first `az keyvault secret set` at boot
# races the role assignment and fails with 403 ForbiddenByRbac (the VM script
# retries, but pushing the grant ahead of boot makes onboarding deterministic).
# Consumers depend on the `vm_rbac_ready` output before creating the VMs.
resource "time_sleep" "wait_for_vm_rbac" {
  count           = length(var.vm_identity_principal_ids) > 0 ? 1 : 0
  depends_on      = [azurerm_role_assignment.vm_secrets_officer]
  create_duration = var.rbac_propagation_wait
}
