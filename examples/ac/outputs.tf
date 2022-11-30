locals {

  testbedconfig = <<TB

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
