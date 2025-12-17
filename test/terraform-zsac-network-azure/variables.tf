variable "name_prefix" {
  type        = string
  description = "A prefix to associate to all the module resources"
  default     = "tnet"
}

variable "resource_tag" {
  type        = string
  description = "A tag to associate to all the module resources"
  default     = "test"
}

variable "arm_location" {
  type        = string
  description = "Azure region"
  default     = "westus2"
}

variable "network_address_space" {
  type        = string
  description = "VNet IP CIDR Range"
  default     = "10.1.0.0/16"
}

variable "ac_subnets" {
  type        = list(string)
  description = "App Connector Subnets to create in VNet"
  default     = null
}

variable "public_subnets" {
  type        = list(string)
  description = "Public/Bastion Subnets to create in VNet"
  default     = null
}

variable "zones_enabled" {
  type        = bool
  description = "Enable zone-aware deployment"
  default     = false
}

variable "zones" {
  type        = list(string)
  description = "Availability zones"
  default     = ["1"]
}
