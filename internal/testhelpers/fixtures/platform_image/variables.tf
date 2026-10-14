variable "location" {
  type        = string
  description = "Azure region to look the image up in"
}

variable "publisher" {
  type        = string
  description = "Image publisher"
}

variable "offer" {
  type        = string
  description = "Image offer"
}

variable "sku" {
  type        = string
  description = "Image SKU"
}

variable "image_version" {
  type        = string
  description = "Image version. null resolves the latest published version."
  default     = null
}
