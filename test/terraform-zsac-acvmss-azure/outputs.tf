################################################################################
# Test Outputs
################################################################################
output "vmss_names" {
  description = "VMSS Names from module"
  value       = module.acvmss.vmss_names
}

output "vmss_ids" {
  description = "VMSS IDs from module"
  value       = module.acvmss.vmss_ids
}

output "vmss_ids_valid" {
  description = "Validation that VMSS IDs are valid"
  value       = length(module.acvmss.vmss_ids) > 0 ? "true" : "false"
}

output "test_variables_set_correctly" {
  description = "Validation that test variables are set correctly"
  value       = var.name_prefix != "" && var.resource_tag != "" ? "true" : "false"
}
