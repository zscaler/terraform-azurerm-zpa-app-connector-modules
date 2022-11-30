output "ac_nsg_id" {
  description = "Network Security Group ID"
  value       = data.azurerm_network_security_group.ac_nsg_selected[*].id
}
