################################################################################
# ZPA Provider Configuration
################################################################################
terraform {
  required_providers {
    zpa = {
      source  = "zscaler/zpa"
      version = "~> 4.0"
    }
  }
  required_version = ">= 0.13.7, < 2.0.0"
}

# Configure the ZPA Provider
provider "zpa" {
  # ZPA provider configuration will be set via environment variables:
  # ZSCALER_CLIENT_ID, ZSCALER_CLIENT_SECRET, ZSCALER_VANITY_DOMAIN, ZPA_CUSTOMER_ID, ZSCALER_CLOUD
}

################################################################################
# Test Module - Provisioning Key
################################################################################
module "zpa_provisioning_key" {
  source = "../../modules/terraform-zpa-provisioning-key"

  # Required parameters
  enrollment_cert        = var.enrollment_cert
  provisioning_key_name  = var.provisioning_key_name
  app_connector_group_id = var.app_connector_group_id

  # Optional parameters
  provisioning_key_enabled          = var.provisioning_key_enabled
  provisioning_key_association_type = var.provisioning_key_association_type
  provisioning_key_max_usage        = var.provisioning_key_max_usage
  byo_provisioning_key              = var.byo_provisioning_key
  byo_provisioning_key_name         = var.byo_provisioning_key_name
}
