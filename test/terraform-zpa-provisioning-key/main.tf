################################################################################
# ZPA Provider Configuration
################################################################################
terraform {
  required_providers {
    zpa = {
      source  = "zscaler/zpa"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
  required_version = ">= 0.13.7, < 2.0.0"
}

# Configure the ZPA Provider
provider "zpa" {
  # ZPA provider configuration will be set via environment variables:
  # ZSCALER_CLIENT_ID, ZSCALER_CLIENT_SECRET, ZSCALER_VANITY_DOMAIN, ZPA_CUSTOMER_ID, ZSCALER_CLOUD
}

# Random suffix for unique names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

locals {
  name_suffix = random_string.suffix.result
}

################################################################################
# Create App Connector Group first (required for Provisioning Key)
################################################################################
module "zpa_app_connector_group" {
  source = "../../modules/terraform-zpa-app-connector-group"

  app_connector_group_name         = "${var.app_connector_group_name}-${local.name_suffix}"
  app_connector_group_description  = var.app_connector_group_description
  app_connector_group_enabled      = var.app_connector_group_enabled
  app_connector_group_latitude     = var.app_connector_group_latitude
  app_connector_group_longitude    = var.app_connector_group_longitude
  app_connector_group_location     = var.app_connector_group_location
  app_connector_group_country_code = var.app_connector_group_country_code
}

################################################################################
# Test Module - Provisioning Key (depends on App Connector Group)
################################################################################
module "zpa_provisioning_key" {
  source = "../../modules/terraform-zpa-provisioning-key"

  # Required parameters
  enrollment_cert        = var.enrollment_cert
  provisioning_key_name  = "${var.provisioning_key_name}-${local.name_suffix}"
  app_connector_group_id = module.zpa_app_connector_group.app_connector_group_id

  # Optional parameters
  provisioning_key_enabled          = var.provisioning_key_enabled
  provisioning_key_association_type = var.provisioning_key_association_type
  provisioning_key_max_usage        = var.provisioning_key_max_usage
  byo_provisioning_key              = var.byo_provisioning_key
  byo_provisioning_key_name         = var.byo_provisioning_key_name
}
