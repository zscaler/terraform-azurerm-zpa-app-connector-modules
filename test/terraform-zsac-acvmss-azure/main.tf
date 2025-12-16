################################################################################
# Azure Provider Configuration
################################################################################
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.56.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.0"
    }
  }
  required_version = ">= 1.0.0"
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Random name allows parallel runs on the same cloud account
resource "random_pet" "this" {
  prefix = var.name_prefix
  length = 2
}

locals {
  name_prefix  = "${var.name_prefix}-${random_pet.this.id}"
  resource_tag = var.resource_tag
}

################################################################################
# Test Infrastructure - Resource Group
################################################################################
resource "azurerm_resource_group" "this" {
  name     = "${local.name_prefix}-rg"
  location = var.arm_location

  tags = {
    Environment = "test"
    Purpose     = "terratest"
    Module      = "terraform-zsac-acvmss-azure"
  }
}

################################################################################
# Test Infrastructure - Network (VNet and Subnet)
################################################################################
resource "azurerm_virtual_network" "this" {
  name                = "${local.name_prefix}-vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  address_space       = ["10.0.0.0/16"]

  tags = {
    Environment = "test"
    Purpose     = "terratest"
    Module      = "terraform-zsac-acvmss-azure"
  }
}

resource "azurerm_subnet" "this" {
  name                 = "${local.name_prefix}-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.1.0/24"]
}

################################################################################
# Test Infrastructure - NSG
################################################################################
resource "azurerm_network_security_group" "this" {
  name                = "${local.name_prefix}-nsg"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  tags = {
    Environment = "test"
    Purpose     = "terratest"
    Module      = "terraform-zsac-acvmss-azure"
  }
}

################################################################################
# Test Infrastructure - SSH Key
################################################################################
resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

################################################################################
# Test Module - ACVMSS Infrastructure
################################################################################
module "acvmss" {
  source = "../../modules/terraform-zsac-acvmss-azure"

  name_prefix    = local.name_prefix
  resource_tag   = local.resource_tag
  resource_group = azurerm_resource_group.this.name
  location       = var.arm_location

  ac_subnet_id = [azurerm_subnet.this.id]
  ssh_key      = tls_private_key.this.public_key_openssh
  ac_nsg_id    = azurerm_network_security_group.this.id

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo "Test user data for VMSS"
  EOF
  )

  acvm_instance_type = var.acvm_instance_type
  vmss_default_acs   = var.vmss_default_acs
  vmss_min_acs       = var.vmss_min_acs
  vmss_max_acs       = var.vmss_max_acs
  zones_enabled      = var.zones_enabled
  zones              = var.zones

  global_tags = {
    Environment = "test"
    Purpose     = "terratest"
    Module      = "terraform-zsac-acvmss-azure"
  }
}
