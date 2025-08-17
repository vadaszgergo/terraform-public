# Network Security Group to allow SSH and intra-virtual-network traffic
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "${var.prefix}-vm-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-vnet-inbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

# Public IPs for VMs
resource "azurerm_public_ip" "spoke1_vm_pip" {
  name                = "${var.prefix}-spoke1-vm-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "spoke2_vm_pip" {
  name                = "${var.prefix}-spoke2-vm-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# NICs for VMs
resource "azurerm_network_interface" "spoke1_vm_nic" {
  name                = "${var.prefix}-spoke1-vm-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke1_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.spoke1_vm_pip.id
  }
}

resource "azurerm_network_interface" "spoke2_vm_nic" {
  name                = "${var.prefix}-spoke2-vm-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke2_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.spoke2_vm_pip.id
  }
}

# Associate NSG to NICs
resource "azurerm_network_interface_security_group_association" "spoke1_vm_nic_nsg" {
  network_interface_id      = azurerm_network_interface.spoke1_vm_nic.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

resource "azurerm_network_interface_security_group_association" "spoke2_vm_nic_nsg" {
  network_interface_id      = azurerm_network_interface.spoke2_vm_nic.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

# Linux VMs
resource "azurerm_linux_virtual_machine" "spoke1_vm" {
  name                            = "${var.prefix}-spoke1-vm"
  location                        = var.location
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = "Standard_B1ms"
  admin_username                  = "azureuser"
  admin_password                  = "Password123!"
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.spoke1_vm_nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "spoke2_vm" {
  name                            = "${var.prefix}-spoke2-vm"
  location                        = var.location
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = "Standard_B1ms"
  admin_username                  = "azureuser"
  admin_password                  = "Password123!"
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.spoke2_vm_nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
} 