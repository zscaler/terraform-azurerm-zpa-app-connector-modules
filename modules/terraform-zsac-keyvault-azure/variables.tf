variable "name_prefix" {
  type        = string
  description = "A prefix to associate to all the Key Vault module resources"
}

variable "resource_tag" {
  type        = string
  description = "A tag to associate to all the Key Vault module resources"
  default     = ""
}

variable "global_tags" {
  type        = map(string)
  description = "Populate any custom user defined tags from a map"
  default     = {}
}

variable "key_vault_name" {
  type        = string
  description = "Explicit Key Vault name. Provided by the caller so the name can also be injected into VM user_data without creating a dependency cycle. Must be globally unique, 3-24 chars, alphanumeric and dashes."
}

variable "resource_group" {
  type        = string
  description = "Main Resource Group Name"
}

variable "location" {
  type        = string
  description = "Key Vault Azure Region"
}

variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID that the Key Vault is associated with"
}

variable "vm_identity_principal_ids" {
  type        = list(string)
  description = "System-assigned Managed Identity principal IDs of the App Connector VMs/VMSS that must be allowed to write OAuth2 secrets to the Key Vault"
  default     = []
}

variable "deployer_object_id" {
  type        = string
  description = "Object ID of the Terraform deployer (current client) granted read/write access to manage OAuth2 secrets during apply"
}

variable "soft_delete_retention_days" {
  type        = number
  description = "Number of days that soft-deleted Key Vault secrets are retained"
  default     = 7
}

variable "purge_protection_enabled" {
  type        = bool
  description = "Whether purge protection is enabled. Disabled by default so ephemeral test/CI vaults can be fully destroyed."
  default     = false
}

variable "rbac_propagation_wait" {
  type        = string
  description = "How long to wait after creating the deployer's Key Vault Secrets Officer role assignment before secrets are created/read, to absorb Azure RBAC eventual-consistency (ForbiddenByRbac) lag."
  default     = "120s"
}
