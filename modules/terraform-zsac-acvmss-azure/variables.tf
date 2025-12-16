variable "name_prefix" {
  type        = string
  description = "A prefix to associate to all the AC VM module resources"
  default     = null
}

variable "resource_tag" {
  type        = string
  description = "A tag to associate to all the AC VM module resources"
  default     = null
}

variable "fault_domain_count" {
  type        = number
  description = "platformFaultDomainCount must be set to 1 for max spreading or 5 for static fixed spreading. Fixed spreading with 2 or 3 fault domains isn't supported for zonal deployments"
  default     = 1
}

variable "global_tags" {
  type        = map(string)
  description = "Populate any custom user defined tags from a map"
  default     = {}
}

variable "resource_group" {
  type        = string
  description = "Main Resource Group Name"
}

variable "location" {
  type        = string
  description = "App Connector Azure Region"
}

#### module by default pushes the same single subnet ID for both mgmt_subnet_id and service_subnet_id, so they are effectively the same variable
#### leaving each as unique values should customer choose to deploy mgmt and service as individual subnets for additional isolation
variable "ac_subnet_id" {
  type        = list(string)
  description = "App Connector subnet id"
}

variable "ac_username" {
  type        = string
  description = "Default App Connector admin/root username"
  default     = "zsroot"
}

variable "ssh_key" {
  type        = string
  description = "SSH Key for instances"
}

variable "acvm_instance_type" {
  type        = string
  description = "App Connector Image size"
  default     = "Standard_D4s_v5"
  validation {
    condition = (
      var.acvm_instance_type == "Standard_D4s_v3" ||
      var.acvm_instance_type == "Standard_F4s_v2" ||
      var.acvm_instance_type == "Standard_D4s_v4" ||
      var.acvm_instance_type == "Standard_D4s_v5"
    )
    error_message = "Input acvm_instance_type must be set to an approved vm size."
  }
}

variable "user_data" {
  type        = string
  description = "Cloud Init data"
}

variable "acvm_image_publisher" {
  type        = string
  description = "Azure Marketplace Zscaler App Connector Image Publisher"
  default     = "zscaler"
}

variable "acvm_image_offer" {
  type        = string
  description = "Azure Marketplace Zscaler App Connector Image Offer"
  default     = "zscaler-private-access"
}

variable "acvm_image_sku" {
  type        = string
  description = "Azure Marketplace Zscaler App Connector Image SKU"
  default     = "zpa-con-azure"
}

variable "acvm_image_version" {
  type        = string
  description = "Azure Marketplace App Connector Image Version"
  default     = "latest"
}

variable "acvm_source_image_id" {
  type        = string
  description = "Custom App Connector Source Image ID. Set this value to the path of a local subscription Microsoft.Compute image to override the App Connector deployment instead of using the marketplace publisher"
  default     = null
}

variable "backend_address_pool" {
  type        = string
  description = "Azure LB Backend Address Pool ID for NIC association"
  default     = null
}

# Validation to determine if Azure Region selected supports availabilty zones if desired
locals {
  az_supported_regions = ["australiaeast", "Australia East", "brazilsouth", "Brazil South", "canadacentral", "Canada Central", "centralindia", "Central India", "centralus", "Central US", "chinanorth3", "China North 3", "ChinaNorth3", "eastasia", "East Asia", "eastus", "East US", "eastus2", "East US 2", "francecentral", "France Central", "germanywestcentral", "Germany West Central", "japaneast", "Japan East", "koreacentral", "Korea Central", "northeurope", "North Europe", "norwayeast", "Norway East", "southafricanorth", "South Africa North", "southcentralus", "South Central US", "southeastasia", "Southeast Asia", "swedencentral", "Sweden Central", "switzerlandnorth", "Switzerland North", "uaenorth", "UAE North", "uksouth", "UK South", "westeurope", "West Europe", "westus2", "West US 2", "westus3", "West US 3", "usgovvirginia", "US Gov Virginia"]
  zones_supported = (
    contains(local.az_supported_regions, var.location) && var.zones_enabled == true
  )
}

variable "zones_enabled" {
  type        = bool
  description = "Determine whether to provision App Connector VMs explicitly in defined zones (if supported by the Azure region provided in the location variable). If left false, Azure will automatically choose a zone and module will create an availability set resource instead for VM fault tolerance"
  default     = false
}

variable "zones" {
  type        = list(string)
  description = "Specify which availability zone(s) to deploy VM resources in if zones_enabled variable is set to true"
  default     = ["1"]
  validation {
    condition = (
      !contains([for zones in var.zones : contains(["1", "2", "3"], zones)], false)
    )
    error_message = "Input zones variable must be a number 1-3."
  }
}

variable "ac_nsg_id" {
  type        = string
  description = "App Connector management interface nsg id"
}

variable "encryption_at_host_enabled" {
  type        = bool
  description = "User input for enabling or disabling host encryption"
  default     = true
}

variable "vmss_default_acs" {
  type        = number
  description = "Default number of ACs in vmss."
  default     = 2
}

variable "vmss_min_acs" {
  type        = number
  description = "Minimum number of ACs in vmss."
  default     = 2
}

variable "vmss_max_acs" {
  type        = number
  description = "Maximum number of ACs in vmss."
  default     = 10
}

variable "scale_out_evaluation_period" {
  type        = string
  description = "Amount of time the average of scaling metric is evaluated over."
  default     = "PT5M"
}

variable "scale_out_threshold" {
  type        = number
  description = "Metric threshold for determining scale out."
  default     = 70
}

variable "scale_out_count" {
  type        = string
  description = "Number of ACs to bring up on scale out event."
  default     = "1"
}

variable "scale_out_cooldown" {
  type        = string
  description = "Amount of time after scale out before scale out is evaluated again."
  default     = "PT15M"
}

variable "scale_in_evaluation_period" {
  type        = string
  description = "Amount of time the average of scaling metric is evaluated over."
  default     = "PT5M"
}

variable "scale_in_threshold" {
  type        = number
  description = "Metric threshold for determining scale in."
  default     = 50
}

variable "scale_in_count" {
  type        = string
  description = "Number of ACs to bring up on scale in event."
  default     = "1"
}

variable "scale_in_cooldown" {
  type        = string
  description = "Amount of time after scale in before scale in is evaluated again."
  default     = "PT15M"
}

variable "scheduled_scaling_enabled" {
  type        = bool
  description = "Enable scheduled scaling on top of metric scaling."
  default     = false
}

variable "scheduled_scaling_vmss_min_acs" {
  type        = number
  description = "Minimum number of ACs in vmss for scheduled scaling profile."
  default     = 2
}

variable "scheduled_scaling_timezone" {
  type        = string
  description = "Timezone the times for the scheduled scaling profile are specified in."
  default     = "Pacific Standard Time"
}

variable "scheduled_scaling_days_of_week" {
  type        = list(string)
  description = "Days of the week to apply scheduled scaling profile."
  default     = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
}

variable "scheduled_scaling_start_time_hour" {
  type        = number
  description = "Hour to start scheduled scaling profile."
  default     = 9
}

variable "scheduled_scaling_start_time_min" {
  type        = number
  description = "Minute to start scheduled scaling profile."
  default     = 0
}

variable "scheduled_scaling_end_time_hour" {
  type        = number
  description = "Hour to end scheduled scaling profile."
  default     = 17
}

variable "scheduled_scaling_end_time_min" {
  type        = number
  description = "Minute to end scheduled scaling profile."
  default     = 0
}
