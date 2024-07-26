variable "arm_location" {
  type        = string
  description = "The Azure Region where resources are to be deployed"
  default     = "westus2"
}

variable "name_prefix" {
  type        = string
  description = "The name prefix for all your resources"
  default     = "zsdemo"
}

variable "network_address_space" {
  type        = string
  description = "VNet IP CIDR Range. All subnet resources that might get created (public, app connector) are derived from this /16 CIDR. If you require creating a VNet smaller than /16, you may need to explicitly define all other subnets via public_subnets and ac_subnets variables"
  default     = "10.1.0.0/16"
}

variable "ac_subnets" {
  type        = list(string)
  description = "App Connector Subnets to create in VNet. This is only required if you want to override the default subnets that this code creates via network_address_space variable."
  default     = null
}

variable "public_subnets" {
  type        = list(string)
  description = "Public/Bastion Subnets to create in VNet. This is only required if you want to override the default subnets that this code creates via network_address_space variable."
  default     = null
}

variable "environment" {
  type        = string
  description = "Customer defined environment tag. ie: Dev, QA, Prod, etc."
  default     = "Development"
}

variable "owner_tag" {
  type        = string
  description = "Customer defined owner tag value. ie: Org, Dept, username, etc."
  default     = "zsac-admin"
}

variable "tls_key_algorithm" {
  type        = string
  description = "algorithm for tls_private_key resource"
  default     = "RSA"
}

variable "acvm_instance_type" {
  type        = string
  description = "App Connector Image size"
  default     = "Standard_D4s_v3"
  validation {
    condition = (
      var.acvm_instance_type == "Standard_D4s_v3" ||
      var.acvm_instance_type == "Standard_F4s_v2"
    )
    error_message = "Input acvm_instance_type must be set to an approved vm size."
  }
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

variable "ac_count" {
  type        = number
  description = "The number of App Connectors to deploy.  Validation assumes max for /24 subnet but could be smaller or larger as long as subnet can accommodate"
  default     = 2
  validation {
    condition     = var.ac_count >= 1 && var.ac_count <= 250
    error_message = "Input ac_count must be a whole number between 1 and 250."
  }
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

variable "reuse_nsg" {
  type        = bool
  description = "Specifies whether the NSG module should create 1:1 network security groups per instance or 1 network security group for all instances"
  default     = "false"
}

variable "bastion_nsg_source_prefix" {
  type        = string
  description = "user input for locking down SSH access to bastion to a specific IP or CIDR range"
  default     = "*"
}

# ZPA Provider specific variables for App Connector Group and Provisioning Key creation
variable "byo_provisioning_key" {
  type        = bool
  description = "Bring your own App Connector Provisioning Key. Setting this variable to true will effectively instruct this module to not create any resources and only reference data resources from values provided in byo_provisioning_key_name"
  default     = false
}

variable "byo_provisioning_key_name" {
  type        = string
  description = "Existing App Connector Provisioning Key name"
  default     = "provisioning-key-tf"
}

variable "enrollment_cert" {
  type        = string
  description = "Get name of ZPA enrollment cert to be used for App Connector provisioning"
  default     = "Connector"

  validation {
    condition = (
      var.enrollment_cert == "Root" ||
      var.enrollment_cert == "Client" ||
      var.enrollment_cert == "Connector" ||
      var.enrollment_cert == "Service Edge" ||
      var.enrollment_cert == "Isolation Client"
    )
    error_message = "Input enrollment_cert must be set to an approved value."
  }
}

variable "app_connector_group_description" {
  type        = string
  description = "Optional: Description of the App Connector Group"
  default     = "This App Connector Group belongs to: "
}

variable "app_connector_group_enabled" {
  type        = bool
  description = "Whether this App Connector Group is enabled or not"
  default     = true
}

variable "app_connector_group_country_code" {
  type        = string
  description = "Optional: Country code of this App Connector Group. example 'US'"
  default     = "US"
}

variable "app_connector_group_latitude" {
  type        = string
  description = "Latitude of the App Connector Group. Integer or decimal. With values in the range of -90 to 90"
  default     = "37.33874"
}

variable "app_connector_group_longitude" {
  type        = string
  description = "Longitude of the App Connector Group. Integer or decimal. With values in the range of -90 to 90"
  default     = "-121.8852525"
}

variable "app_connector_group_location" {
  type        = string
  description = "location of the App Connector Group in City, State, Country format. example: 'San Jose, CA, USA'"
  default     = "San Jose, CA, USA"
}

variable "app_connector_group_upgrade_day" {
  type        = string
  description = "Optional: App Connectors in this group will attempt to update to a newer version of the software during this specified day. Default value: SUNDAY. List of valid days (i.e., SUNDAY, MONDAY, etc)"
  default     = "SUNDAY"
}

variable "app_connector_group_upgrade_time_in_secs" {
  type        = string
  description = "Optional: App Connectors in this group will attempt to update to a newer version of the software during this specified time. Default value: 66600. Integer in seconds (i.e., 66600). The integer should be greater than or equal to 0 and less than 86400, in 15 minute intervals"
  default     = "66600"
}

variable "app_connector_group_override_version_profile" {
  type        = bool
  description = "Optional: Whether the default version profile of the App Connector Group is applied or overridden. Default: false"
  default     = true
}

variable "app_connector_group_version_profile_id" {
  type        = string
  description = "Optional: ID of the version profile. To learn more, see Version Profile Use Cases. https://help.zscaler.com/zpa/configuring-version-profile"
  default     = "2"

  validation {
    condition = (
      var.app_connector_group_version_profile_id == "0" || #Default = 0
      var.app_connector_group_version_profile_id == "1" || #Previous Default = 1
      var.app_connector_group_version_profile_id == "2"    #New Release = 2
    )
    error_message = "Input app_connector_group_version_profile_id must be set to an approved value."
  }
}

variable "app_connector_group_dns_query_type" {
  type        = string
  description = "Whether to enable IPv4 or IPv6, or both, for DNS resolution of all applications in the App Connector Group"
  default     = "IPV4_IPV6"

  validation {
    condition = (
      var.app_connector_group_dns_query_type == "IPV4_IPV6" ||
      var.app_connector_group_dns_query_type == "IPV4" ||
      var.app_connector_group_dns_query_type == "IPV6"
    )
    error_message = "Input app_connector_group_dns_query_type must be set to an approved value."
  }
}

variable "provisioning_key_enabled" {
  type        = bool
  description = "Whether the provisioning key is enabled or not. Default: true"
  default     = true
}

variable "provisioning_key_association_type" {
  type        = string
  description = "Specifies the provisioning key type for App Connectors or ZPA Private Service Edges. The supported values are CONNECTOR_GRP and SERVICE_EDGE_GRP"
  default     = "CONNECTOR_GRP"

  validation {
    condition = (
      var.provisioning_key_association_type == "CONNECTOR_GRP" ||
      var.provisioning_key_association_type == "SERVICE_EDGE_GRP"
    )
    error_message = "Input provisioning_key_association_type must be set to an approved value."
  }
}

variable "provisioning_key_max_usage" {
  type        = number
  description = "The maximum number of instances where this provisioning key can be used for enrolling an App Connector or Service Edge"
  default     = 10
}
