################################################################################
# Variables for ZPA Provisioning Key Test
################################################################################

# App Connector Group variables (required to create provisioning key)
variable "app_connector_group_name" {
  type        = string
  description = "Name of the App Connector Group"
  default     = "test-ac-group"
}

variable "app_connector_group_description" {
  type        = string
  description = "Description of the App Connector Group"
  default     = "Test App Connector Group for Terratest"
}

variable "app_connector_group_enabled" {
  type        = bool
  description = "Whether the App Connector Group is enabled"
  default     = true
}

variable "app_connector_group_latitude" {
  type        = string
  description = "Latitude of the App Connector Group"
  default     = "37.3382082"
}

variable "app_connector_group_longitude" {
  type        = string
  description = "Longitude of the App Connector Group"
  default     = "-121.8863286"
}

variable "app_connector_group_location" {
  type        = string
  description = "Location of the App Connector Group"
  default     = "San Jose, CA, USA"
}

variable "app_connector_group_country_code" {
  type        = string
  description = "Country code of the App Connector Group"
  default     = "US"
}

# Provisioning Key variables
variable "enrollment_cert" {
  type        = string
  description = "Enrollment certificate name"
  default     = "Connector"
}

variable "provisioning_key_name" {
  type        = string
  description = "Name of the provisioning key"
  default     = "test-prov-key"
}

variable "provisioning_key_enabled" {
  type        = bool
  description = "Whether the provisioning key is enabled"
  default     = true
}

variable "provisioning_key_association_type" {
  type        = string
  description = "Association type for the provisioning key"
  default     = "CONNECTOR_GRP"
}

variable "provisioning_key_max_usage" {
  type        = string
  description = "Maximum usage for the provisioning key"
  default     = "10"
}

variable "byo_provisioning_key" {
  type        = bool
  description = "Whether to use an existing provisioning key"
  default     = false
}

variable "byo_provisioning_key_name" {
  type        = string
  description = "Name of existing provisioning key to use"
  default     = ""
}
