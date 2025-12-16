################################################################################
# Azure Provider Configuration
################################################################################
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
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
# Test Module - Network Infrastructure
################################################################################
module "network" {
  source = "../../modules/terraform-zsac-network-azure"

  name_prefix           = local.name_prefix
  resource_tag          = local.resource_tag
  location              = var.arm_location
  network_address_space = var.network_address_space
  ac_subnets            = var.ac_subnets
  public_subnets        = var.public_subnets
  zones_enabled         = var.zones_enabled
  zones                 = var.zones

  global_tags = {
    Environment = "test"
    Purpose     = "terratest"
    Module      = "terraform-zsac-network-azure"
  }
}
