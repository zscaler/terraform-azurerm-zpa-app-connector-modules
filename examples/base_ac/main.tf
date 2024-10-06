################################################################################
# Generate a unique random string for resource name assignment and key pair
################################################################################
resource "random_string" "suffix" {
  length  = 8
  upper   = false
  special = false
}


################################################################################
# Map default tags with values to be assigned to all tagged resources
################################################################################
locals {
  global_tags = {
    Owner       = var.owner_tag
    ManagedBy   = "terraform"
    Vendor      = "Zscaler"
    Environment = var.environment
  }
}


################################################################################
# The following lines generates a new SSH key pair and stores the PEM file 
# locally. The public key output is used as the instance_key passed variable 
# to the vm modules for admin_ssh_key public_key authentication.
# This is not recommended for production deployments. Please consider modifying 
# to pass your own custom public key file located in a secure location.   
################################################################################
# private key for login
resource "tls_private_key" "key" {
  algorithm = var.tls_key_algorithm
}

# write private key to local pem file
resource "local_file" "private_key" {
  content         = tls_private_key.key.private_key_pem
  filename        = coalesce(var.custom_name, "./${var.name_prefix}-key-${random_string.suffix.result}.pem")
  file_permission = "0600"
}


################################################################################
# 1. Create/reference all network infrastructure resource dependencies for all 
#    child modules (Resource Group, VNet, Subnets, NAT Gateway, Route Tables)
################################################################################
module "network" {
  source                = "../../modules/terraform-zsac-network-azure"
  name_prefix           = coalesce(var.custom_name, var.name_prefix)
  resource_tag          = random_string.suffix.result
  global_tags           = local.global_tags
  location              = var.arm_location
  network_address_space = var.network_address_space
  ac_subnets            = var.ac_subnets
  public_subnets        = var.public_subnets
  zones_enabled         = var.zones_enabled
  zones                 = var.zones
  bastion_enabled       = true
}


################################################################################
# 2. Create Bastion Host for workload and AC SSH jump access
################################################################################
module "bastion" {
  source                    = "../../modules/terraform-zsac-bastion-azure"
  location                  = var.arm_location
  name_prefix               = coalesce(var.custom_name, "${var.name_prefix}-${var.arm_location}-${module.network.resource_group_name}")
  resource_tag              = random_string.suffix.result
  global_tags               = local.global_tags
  resource_group            = module.network.resource_group_name
  public_subnet_id          = module.network.bastion_subnet_ids[0]
  ssh_key                   = tls_private_key.key.public_key_openssh
  bastion_nsg_source_prefix = var.bastion_nsg_source_prefix
}


################################################################################
# 3. Create ZPA App Connector Group
################################################################################
module "zpa_app_connector_group" {
  count                                        = var.byo_provisioning_key == true ? 0 : 1 # Only use this module if a new provisioning key is needed
  source                                       = "../../modules/terraform-zpa-app-connector-group"
  app_connector_group_name                     = coalesce(var.custom_name, "${var.name_prefix}-${var.arm_location}-${module.network.resource_group_name}")
  app_connector_group_description              = "${var.app_connector_group_description}-${var.arm_location}-${module.network.resource_group_name}"
  app_connector_group_enabled                  = var.app_connector_group_enabled
  app_connector_group_country_code             = var.app_connector_group_country_code
  app_connector_group_latitude                 = var.app_connector_group_latitude
  app_connector_group_longitude                = var.app_connector_group_longitude
  app_connector_group_location                 = var.app_connector_group_location
  app_connector_group_upgrade_day              = var.app_connector_group_upgrade_day
  app_connector_group_upgrade_time_in_secs     = var.app_connector_group_upgrade_time_in_secs
  app_connector_group_override_version_profile = var.app_connector_group_override_version_profile
  app_connector_group_version_profile_id       = var.app_connector_group_version_profile_id
  app_connector_group_dns_query_type           = var.app_connector_group_dns_query_type
}


################################################################################
# 4. Create ZPA Provisioning Key (or reference existing if byo set)
################################################################################
module "zpa_provisioning_key" {
  source                            = "../../modules/terraform-zpa-provisioning-key"
  enrollment_cert                   = var.enrollment_cert
  provisioning_key_name             = coalesce(var.custom_name, "${var.name_prefix}-${var.arm_location}-${module.network.resource_group_name}")
  provisioning_key_enabled          = var.provisioning_key_enabled
  provisioning_key_association_type = var.provisioning_key_association_type
  provisioning_key_max_usage        = var.provisioning_key_max_usage
  app_connector_group_id            = try(module.zpa_app_connector_group[0].app_connector_group_id, "")
  byo_provisioning_key              = var.byo_provisioning_key
  byo_provisioning_key_name         = var.byo_provisioning_key_name
}

################################################################################
# 5. Create specified number of AC VMs per ac_count by default in an
#    availability set for Azure Data Center fault tolerance. Optionally, deployed
#    ACs can automatically span equally across designated availabilty zones 
#    if enabled via "zones_enabled" and "zones" variables. E.g. ac_count set to 
#    4 and 2 zones ['1","2"] will create 2x ACs in AZ1 and 2x ACs in AZ2
################################################################################
# Create the user_data file with necessary bootstrap variables for App Connector registration
locals {
  appuserdata = <<APPUSERDATA
#!/bin/bash
#Stop the App Connector service which was auto-started at boot time
systemctl stop zpa-connector
#Create a file from the App Connector provisioning key created in the ZPA Admin Portal
#Make sure that the provisioning key is between double quotes
echo "${module.zpa_provisioning_key.provisioning_key}" > /opt/zscaler/var/provision_key
#Run a yum update to apply the latest patches
yum update -y
#Start the App Connector service to enroll it in the ZPA cloud
systemctl start zpa-connector
#Wait for the App Connector to download latest build
sleep 60
#Stop and then start the App Connector for the latest build
systemctl stop zpa-connector
systemctl start zpa-connector
APPUSERDATA
}

# Write the file to local filesystem for storage/reference
resource "local_file" "user_data_file" {
  content  = local.appuserdata
  filename = "./user_data"
}

# Create specified number of AC appliances
module "ac_vm" {
  source               = "../../modules/terraform-zsac-acvm-azure"
  ac_count             = var.ac_count
  name_prefix          = coalesce(var.custom_name, "${var.name_prefix}-${var.arm_location}-${module.network.resource_group_name}")
  resource_tag         = random_string.suffix.result
  global_tags          = local.global_tags
  resource_group       = module.network.resource_group_name
  ac_subnet_id         = module.network.ac_subnet_ids
  ssh_key              = tls_private_key.key.public_key_openssh
  user_data            = local.appuserdata
  location             = var.arm_location
  zones_enabled        = var.zones_enabled
  zones                = var.zones
  acvm_instance_type   = var.acvm_instance_type
  acvm_image_publisher = var.acvm_image_publisher
  acvm_image_offer     = var.acvm_image_offer
  acvm_image_sku       = var.acvm_image_sku
  acvm_image_version   = var.acvm_image_version
  ac_nsg_id            = module.ac_nsg.ac_nsg_id

  depends_on = [
    local_file.user_data_file,
  ]
}


################################################################################
# 6. Create Network Security Group and rules to be assigned to AC interface(s). 
#    Default behavior will create 1 of each resource per AC VM.
#    Set variable "reuse_nsg" to true if you would like a single NSG 
#    created and assigned to ALL App Connectors
################################################################################
module "ac_nsg" {
  source         = "../../modules/terraform-zsac-nsg-azure"
  nsg_count      = var.reuse_nsg == false ? var.ac_count : 1
  name_prefix    = coalesce(var.custom_name, "${var.name_prefix}-${var.arm_location}-${module.network.resource_group_name}")
  resource_tag   = random_string.suffix.result
  resource_group = module.network.resource_group_name
  location       = var.arm_location
  global_tags    = local.global_tags
}
