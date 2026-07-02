output "vmss_names" {
  description = "VMSS Names"
  value       = azurerm_orchestrated_virtual_machine_scale_set.ac_vmss[*].name
}

output "vmss_ids" {
  description = "VMSS IDs"
  value       = azurerm_orchestrated_virtual_machine_scale_set.ac_vmss[*].id
}

output "vmss_identity_ids" {
  description = "User-assigned Managed Identity resource IDs attached to each App Connector scale set (echoes the identity_ids input)."
  value       = var.identity_ids
}
