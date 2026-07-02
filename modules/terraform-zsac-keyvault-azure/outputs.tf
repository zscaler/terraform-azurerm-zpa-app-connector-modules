output "key_vault_id" {
  description = "Resource ID of the OAuth2 Key Vault"
  value       = azurerm_key_vault.oauth.id
}

output "key_vault_name" {
  description = "Name of the OAuth2 Key Vault (passed into VM user_data so connectors know where to write their OAuth2 code)"
  value       = azurerm_key_vault.oauth.name
}

output "key_vault_uri" {
  description = "URI of the OAuth2 Key Vault"
  value       = azurerm_key_vault.oauth.vault_uri
}

output "deployer_rbac_ready" {
  description = "Sentinel that resolves once the deployer's Key Vault Secrets Officer role assignment has had time to propagate. Depend on this before creating/reading secrets to avoid ForbiddenByRbac races."
  value       = time_sleep.wait_for_deployer_rbac.id
}

output "vm_rbac_ready" {
  description = "Sentinel that resolves once the App Connector VM identity's Key Vault Secrets Officer role assignment has had time to propagate. Depend on this before booting the VMs so the connector's first OAuth2 secret write does not race the grant and 403."
  value       = try(time_sleep.wait_for_vm_rbac[0].id, "")
}
