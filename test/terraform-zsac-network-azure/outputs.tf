################################################################################
# Test Outputs
################################################################################
output "virtual_network_id" {
  description = "VNet ID from module"
  value       = module.network.virtual_network_id
}

output "ac_subnet_ids" {
  description = "AC Subnet IDs from module"
  value       = module.network.ac_subnet_ids
}

output "bastion_subnet_ids" {
  description = "Bastion Subnet IDs from module"
  value       = module.network.bastion_subnet_ids
}

output "vnet_id_valid" {
  description = "Validation that VNet ID is valid"
  value       = module.network.virtual_network_id != "" ? "true" : "false"
}

output "ac_subnet_ids_valid" {
  description = "Validation that AC Subnet IDs are valid"
  value       = length(module.network.ac_subnet_ids) > 0 ? "true" : "false"
}

output "ac_subnet_count_correct" {
  description = "Validation that AC Subnet count is correct"
  value       = length(module.network.ac_subnet_ids) >= 1 ? "true" : "false"
}

output "test_variables_set_correctly" {
  description = "Validation that test variables are set correctly"
  value       = var.name_prefix != "" && var.resource_tag != "" ? "true" : "false"
}
