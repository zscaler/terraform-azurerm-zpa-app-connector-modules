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
# Test Infrastructure - Resource Group
################################################################################
resource "azurerm_resource_group" "this" {
  name     = "${local.name_prefix}-rg"
  location = var.arm_location

  tags = {
    Environment = "test"
    Purpose     = "terratest"
    Module      = "terraform-zsac-nsg-azure"
  }
}

################################################################################
# Test Module - NSG Infrastructure
################################################################################
module "nsg" {
  source = "../../modules/terraform-zsac-nsg-azure"

  nsg_count      = var.nsg_count
  name_prefix    = local.name_prefix
  resource_tag   = local.resource_tag
  resource_group = azurerm_resource_group.this.name
  location       = var.arm_location

  global_tags = {
    Environment = "test"
    Purpose     = "terratest"
    Module      = "terraform-zsac-nsg-azure"
  }
}
