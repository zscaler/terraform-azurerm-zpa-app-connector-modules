variable "arm_location" {
  type        = string
  description = "The Azure Region where resources are to be deployed"
  default     = "westus2"
}

variable "custom_name" {
  type        = string
  description = "The full name of the resource. If provided, this will override name_prefix and resource_tag."
  default     = null
}

variable "name_prefix" {
  type        = string
  description = "The name prefix for all your resources"
  default     = "zsac"
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

variable "bastion_nsg_source_prefix" {
  type        = string
  description = "User input for locking down SSH access to bastion to a specific IP or CIDR range. Defaults to any IP"
  default     = "*"
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
  description = "App Connector Image size. Default is Standard_D4s_v5 (4 vCPU Intel). AMD alternatives (Standard_D4as_v5) are typically 10-15% cheaper. For AppProtection workloads, use 8-core instances (Standard_D8s_v5 or Standard_D8as_v5)."
  default     = "Standard_D4s_v5"
  validation {
    condition = contains([
      # 4-core Intel instances (standard workloads) - Zscaler recommended
      "Standard_F4s_v2", # Zscaler recommended (retiring Nov 2028)
      "Standard_D4s_v3", # Zscaler recommended
      "Standard_D4s_v4",
      "Standard_D4s_v5",
      # 4-core AMD instances (cost-optimized, standard workloads)
      "Standard_D4as_v5",
      # 8-core Intel instances (AppProtection workloads)
      "Standard_D8s_v5",
      # 8-core AMD instances (AppProtection workloads, cost-optimized)
      "Standard_D8as_v5"
    ], var.acvm_instance_type)
    error_message = "Input acvm_instance_type must be set to an approved vm size. Valid options: Standard_F4s_v2, Standard_D4s_v3, Standard_D4s_v4, Standard_D4s_v5, Standard_D4as_v5, Standard_D8s_v5, Standard_D8as_v5."
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
  description = "Azure Marketplace App Connector Image Version. Pinned by default to a known-good version for reproducible plans; set to \"latest\" to always track the newest published image (may introduce plan drift)."
  default     = "2025.11.12"
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

variable "encryption_at_host_enabled" {
  type        = bool
  description = "User input for enabling or disabling host encryption"
  default     = true
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

# ZPA App Connector onboarding method selection
variable "onboarding_method" {
  type        = string
  description = "App Connector onboarding method. \"oauth\" (default, recommended) enrolls connectors via OAuth2 user codes relayed through Azure Key Vault. \"provisioning_key\" uses the legacy provisioning key flow."
  default     = "oauth"

  validation {
    condition     = var.onboarding_method == "oauth" || var.onboarding_method == "provisioning_key"
    error_message = "Input onboarding_method must be either \"oauth\" or \"provisioning_key\"."
  }
}

variable "app_connector_group_name" {
  type        = string
  description = "Optional name for the App Connector Group. Supports {region}, {name_prefix}, {random_suffix} substitution. If empty, a default name is generated."
  default     = ""
}

variable "provisioning_key_name" {
  type        = string
  description = "Optional name for the Provisioning Key. If empty, the App Connector Group name is used."
  default     = ""
}

variable "app_connector_group_city_country" {
  type        = string
  description = "Optional: City and country of this App Connector Group. example 'San Jose, US'"
  default     = ""
}

variable "use_zscaler_image" {
  type        = bool
  description = "Whether to use the Zscaler App Connector Marketplace image (true) or a RHEL9 base image bootstrapped via the Zscaler yum repo (false)"
  default     = true
}

################################################################################
# OAuth2 onboarding variables (Key Vault relay)
################################################################################
variable "byo_key_vault" {
  type        = bool
  description = "Bring your own Azure Key Vault for the OAuth2 token relay. If false, a new RBAC-enabled Key Vault is created for the OAuth2 flow."
  default     = false
}

variable "byo_key_vault_name" {
  type        = string
  description = "Existing Key Vault name to relay OAuth2 user codes through. Required if byo_key_vault is true."
  default     = ""
}

variable "byo_key_vault_rg" {
  type        = string
  description = "Resource group of the existing Key Vault. Required if byo_key_vault is true."
  default     = ""
}

variable "oauth_token_wait_seconds" {
  type        = number
  description = "How long to wait (seconds) for App Connector scale-set instances to publish their OAuth2 user codes to Key Vault before Terraform reads them back."
  default     = 420
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


################################################################################
# Auto Scaling (VMSS) variables list
################################################################################
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
