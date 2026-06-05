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
