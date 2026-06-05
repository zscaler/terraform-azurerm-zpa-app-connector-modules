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

resource "azurerm_key_vault" "oauth" {
  name                       = var.key_vault_name
  location                   = var.location
  resource_group_name        = var.resource_group
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  purge_protection_enabled   = var.purge_protection_enabled
  soft_delete_retention_days = var.soft_delete_retention_days

  tags = var.global_tags
}

################################################################################
# Grant the Terraform deployer permission to manage/read OAuth2 secrets.
################################################################################
resource "azurerm_role_assignment" "deployer_secrets_officer" {
  scope                = azurerm_key_vault.oauth.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.deployer_object_id
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
