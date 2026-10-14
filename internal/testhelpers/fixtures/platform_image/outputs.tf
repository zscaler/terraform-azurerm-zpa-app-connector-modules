output "image_id" {
  description = "Resolved platform image ID"
  value       = data.azurerm_platform_image.this.id
}
