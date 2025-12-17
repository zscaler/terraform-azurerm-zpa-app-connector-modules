################################################################################
# Test Outputs
################################################################################
output "ac_nsg_id" {
  description = "NSG IDs from module"
  value       = module.nsg.ac_nsg_id
}

output "nsg_id_valid" {
  description = "Validation that NSG ID is valid"
  value       = length(module.nsg.ac_nsg_id) > 0 ? "true" : "false"
}

output "nsg_count_correct" {
  description = "Validation that NSG count is correct"
  value       = length(module.nsg.ac_nsg_id) == var.nsg_count ? "true" : "false"
}

output "test_variables_set_correctly" {
  description = "Validation that test variables are set correctly"
  value       = var.name_prefix != "" && var.resource_tag != "" ? "true" : "false"
}
