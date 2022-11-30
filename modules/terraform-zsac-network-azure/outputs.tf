output "resource_group_name" {
  description = "Azure Resource Group Name"
  value       = data.azurerm_resource_group.rg_selected.name
}

output "ac_subnet_ids" {
  description = "App Connector Subnet ID"
  value       = data.azurerm_subnet.ac_subnet_selected[*].id
}

output "public_ip_address" {
  description = "Azure Public IP Address"
  value       = data.azurerm_public_ip.pip_selected[*].ip_address
}

output "bastion_subnet_ids" {
  description = "Bastion Host Subnet ID"
  value       = azurerm_subnet.bastion_subnet[*].id
}

output "virtual_network_id" {
  description = "Azure Virtual Network ID"
  value       = data.azurerm_virtual_network.vnet_selected.id
}
