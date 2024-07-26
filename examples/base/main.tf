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
  filename        = "./${var.name_prefix}-key-${random_string.suffix.result}.pem"
  file_permission = "0600"
}

################################################################################
# 1. Create/reference all network infrastructure resource dependencies for all 
#    child modules (Resource Group, VNet, Subnets, NAT Gateway, Route Tables)
################################################################################
module "network" {
  source                = "../../modules/terraform-zsac-network-azure"
  name_prefix           = var.name_prefix
  resource_tag          = random_string.suffix.result
  global_tags           = local.global_tags
  location              = var.arm_location
  network_address_space = var.network_address_space
  public_subnets        = var.public_subnets
  zones_enabled         = var.zones_enabled
  zones                 = var.zones
  base_only             = true
  bastion_enabled       = true
}


################################################################################
# 2. Create Bastion Host for workload and AC SSH jump access
################################################################################
module "bastion" {
  source                    = "../../modules/terraform-zsac-bastion-azure"
  location                  = var.arm_location
  name_prefix               = var.name_prefix
  resource_tag              = random_string.suffix.result
  global_tags               = local.global_tags
  resource_group            = module.network.resource_group_name
  public_subnet_id          = module.network.bastion_subnet_ids[0]
  ssh_key                   = tls_private_key.key.public_key_openssh
  bastion_nsg_source_prefix = var.bastion_nsg_source_prefix
}
