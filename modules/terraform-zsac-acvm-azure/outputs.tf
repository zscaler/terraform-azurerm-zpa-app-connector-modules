output "private_ip" {
  description = "Instance Management Interface Private IP Address"
  value       = azurerm_network_interface.ac_nic[*].private_ip_address
}

output "ac_hostname" {
  description = "Instance Host Name"
  value       = azurerm_linux_virtual_machine.ac_vm[*].computer_name
}
