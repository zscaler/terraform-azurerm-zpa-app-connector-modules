locals {

  testbedconfig = <<TB
***Disclaimer***
By default, these templates store two critical files to the "examples" directory. DO NOT delete/lose these files:
1. Terraform State file (terraform.tfstate) - Terraform must store state about your managed infrastructure and configuration. 
   This state is used by Terraform to map real world resources to your configuration, keep track of metadata, and to improve performance for large infrastructures.

   Terraform uses state to determine which changes to make to your infrastructure. 
   Prior to any operation, Terraform does a refresh to update the state with the real infrastructure.

   If this file is missing, you will NOT be able to make incremental changes to the environment resources without first importing state back to terraform manually.

2. SSH Private Key (.pem) file - Zscaler templates will attempt to create a new local private/public key pair for VM access (if a pre-existing one is not specified). 
   You (and subsequently Zscaler) will NOT be able to remotely access these VMs once deployed without valid SSH access.
***Disclaimer***

Resource Group: 
${module.network.resource_group_name}

All App Connector Management IPs. Username "zsroot"
${join("\n", module.ac_vm.private_ip)}

All NAT GW Public IPs:
${join("\n", module.network.public_ip_address)}

TB
}

output "testbedconfig" {
  description = "Azure Testbed results"
  value       = local.testbedconfig
}

resource "local_file" "testbed" {
  content  = local.testbedconfig
  filename = "../testbed.txt"
}

output "onboarding_method" {
  description = "The onboarding method used for App Connector enrollment (oauth or provisioning_key)"
  value       = local.use_provisioning_key ? "provisioning_key" : "oauth"
}

output "app_connector_group_id" {
  description = "ID of the created ZPA App Connector Group"
  value       = local.use_provisioning_key ? try(module.zpa_app_connector_group_pk[0].app_connector_group_id, null) : try(module.zpa_app_connector_group[0].app_connector_group_id, null)
}

output "oauth_key_vault_name" {
  description = "Name of the Key Vault used to relay OAuth2 user codes (empty when onboarding via provisioning key)"
  value       = local.key_vault_name
}
