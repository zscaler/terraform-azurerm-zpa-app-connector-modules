variable "name_prefix" {
  type        = string
  description = "A prefix to associate to all the module resources"
  default     = "tnsg"
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

variable "nsg_count" {
  type        = number
  description = "Number of NSGs to create"
  default     = 1
}
