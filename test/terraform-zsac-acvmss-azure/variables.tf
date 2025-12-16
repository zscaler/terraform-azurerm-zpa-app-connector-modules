variable "name_prefix" {
  type        = string
  description = "A prefix to associate to all the VMSS module resources"
  default     = "zsac-vmss-test"
}

variable "resource_tag" {
  type        = string
  description = "A tag to associate to all the VMSS module resources"
  default     = "terratest"
}

variable "arm_location" {
  type        = string
  description = "Azure Region"
  default     = "westus2"
}

variable "acvm_instance_type" {
  type        = string
  description = "App Connector Image size"
  default     = "Standard_D4s_v5"
}

variable "vmss_default_acs" {
  type        = number
  description = "Default number of ACs in vmss"
  default     = 2
}

variable "vmss_min_acs" {
  type        = number
  description = "Minimum number of ACs in vmss"
  default     = 2
}

variable "vmss_max_acs" {
  type        = number
  description = "Maximum number of ACs in vmss"
  default     = 4
}

variable "zones_enabled" {
  type        = bool
  description = "Enable zones for VMSS"
  default     = false
}

variable "zones" {
  type        = list(string)
  description = "Availability zones"
  default     = ["1"]
}
