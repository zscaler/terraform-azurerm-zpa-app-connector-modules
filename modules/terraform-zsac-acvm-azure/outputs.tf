output "private_ip" {
  description = "Instance Management Interface Private IP Address"
  value       = azurerm_network_interface.ac_nic[*].private_ip_address
}

output "ac_hostname" {
  description = "Instance Host Name"
  value       = azurerm_linux_virtual_machine.ac_vm[*].computer_name
}

output "ac_vm_identity_principal_ids" {
  description = "System-assigned Managed Identity principal IDs for each App Connector VM. Used to grant Key Vault access for the OAuth2 onboarding flow."
  value       = [for vm in azurerm_linux_virtual_machine.ac_vm : vm.identity[0].principal_id]
}
