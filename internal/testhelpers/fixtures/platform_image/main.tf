provider "azurerm" {
  features {}
}

# Fails the plan when the version is not published (or has been deprecated) in
# the region, which is what Azure would otherwise only report at apply time.
data "azurerm_platform_image" "this" {
  location  = var.location
  publisher = var.publisher
  offer     = var.offer
  sku       = var.sku
  version   = var.image_version
}
