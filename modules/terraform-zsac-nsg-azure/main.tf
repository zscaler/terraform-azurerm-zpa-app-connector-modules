################################################################################
# Create NSG and Rules for App Connector interfaces
################################################################################
resource "azurerm_network_security_group" "ac_nsg" {
  count               = var.byo_nsg == false ? var.nsg_count : 0
  name                = "${var.name_prefix}-ac-nsg-${count.index + 1}-${var.resource_tag}"
  location            = var.location
  resource_group_name = var.resource_group

  security_rule {
    name                       = "SSH_VNET"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "ICMP_VNET"
    priority                   = 4001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "OUTBOUND"
    priority                   = 4000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.global_tags
}

# Or use existing NSG
data "azurerm_network_security_group" "ac_nsg_selected" {
  count               = var.byo_nsg == false ? length(azurerm_network_security_group.ac_nsg[*].id) : length(var.byo_nsg_names)
  name                = var.byo_nsg == false ? "${var.name_prefix}-ac-nsg-${count.index + 1}-${var.resource_tag}" : element(var.byo_nsg_names, count.index)
  resource_group_name = var.resource_group
}
