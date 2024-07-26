################################################################################
# Make sure that ZPA App Connector image terms have been accepted
################################################################################
resource "azurerm_marketplace_agreement" "zs_image_agreement" {
  offer     = var.acvm_image_offer
  plan      = var.acvm_image_sku
  publisher = var.acvm_image_publisher
}


################################################################################
# Create App Connector Interface and associate NSG
################################################################################
# Create App Connector interface
resource "azurerm_network_interface" "ac_nic" {
  count               = var.ac_count
  name                = "${var.name_prefix}-ac-nic-${count.index + 1}-${var.resource_tag}"
  location            = var.location
  resource_group_name = var.resource_group

  ip_configuration {
    name                          = "${var.name_prefix}-ac-nic-conf-${var.resource_tag}"
    subnet_id                     = element(var.ac_subnet_id, count.index)
    private_ip_address_allocation = "Dynamic"
    primary                       = true
  }

  tags = var.global_tags
}


################################################################################
# Associate App Connector interface to NSG
################################################################################
resource "azurerm_network_interface_security_group_association" "ac_nic_association" {
  count                     = var.ac_count
  network_interface_id      = azurerm_network_interface.ac_nic[count.index].id
  network_security_group_id = element(var.ac_nsg_id, count.index)

  depends_on = [azurerm_network_interface.ac_nic]
}


################################################################################
# Create App Connector VM
################################################################################
resource "azurerm_linux_virtual_machine" "ac_vm" {
  count               = var.ac_count
  name                = "${var.name_prefix}-acvm-${count.index + 1}-${var.resource_tag}"
  location            = var.location
  resource_group_name = var.resource_group
  size                = var.acvm_instance_type
  availability_set_id = local.zones_supported == false ? azurerm_availability_set.ac_availability_set[0].id : null
  zone                = local.zones_supported ? element(var.zones, count.index) : null

  network_interface_ids = [
    azurerm_network_interface.ac_nic[count.index].id,
  ]

  computer_name  = "${var.name_prefix}-acvm-${count.index + 1}-${var.resource_tag}"
  admin_username = var.ac_username
  custom_data    = base64encode(var.user_data)

  admin_ssh_key {
    username   = var.ac_username
    public_key = "${trimspace(var.ssh_key)} ${var.ac_username}@me.io"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = var.acvm_image_publisher
    offer     = var.acvm_image_offer
    sku       = var.acvm_image_sku
    version   = var.acvm_image_version
  }

  plan {
    publisher = var.acvm_image_publisher
    name      = var.acvm_image_sku
    product   = var.acvm_image_offer
  }

  tags = var.global_tags

  depends_on = [
    azurerm_network_interface_security_group_association.ac_nic_association,
    azurerm_marketplace_agreement.zs_image_agreement,
  ]
}


################################################################################
# If AC zones are not manually defined, create availability set.
# If zones_enabled is set to true and the Azure region supports zones, this
# resource will not be created.
################################################################################
resource "azurerm_availability_set" "ac_availability_set" {
  count                       = local.zones_supported == false ? 1 : 0
  name                        = "${var.name_prefix}-acvm-availability-set-${var.resource_tag}"
  location                    = var.location
  resource_group_name         = var.resource_group
  platform_fault_domain_count = local.max_fd_supported == true ? 3 : 2

  tags = var.global_tags
}
