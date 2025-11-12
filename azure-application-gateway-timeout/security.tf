# Network Security Group for VMs
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "${var.prefix}-vm-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-all-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow outbound traffic
  security_rule {
    name                       = "allow-all-outbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSG to NICs
resource "azurerm_network_interface_security_group_association" "client_vm_nic_nsg" {
  network_interface_id      = azurerm_network_interface.client_vm_nic.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

resource "azurerm_network_interface_security_group_association" "server_vm_nic_nsg" {
  network_interface_id      = azurerm_network_interface.server_vm_nic.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

