# Public IP for Spoke1 VM
resource "azurerm_public_ip" "spoke1_vm_public_ip" {
  name                = "spoke1-vm-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  depends_on = [azurerm_virtual_network.spoke1_vnet]
}

# Create a VM in Spoke1
resource "azurerm_network_interface" "spoke1_vm_nic" {
  name                = "spoke1-vm-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke1_subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id         = azurerm_public_ip.spoke1_vm_public_ip.id
  }

  depends_on = [azurerm_virtual_network_peering.spoke1_to_hub]

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_linux_virtual_machine" "spoke1_vm" {
  name                = "spoke1-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B1s"  # Small VM size
  admin_username      = "admin"

  network_interface_ids = [
    azurerm_network_interface.spoke1_vm_nic.id
  ]

  admin_ssh_key {
    username   = "admin"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  depends_on = [
    azurerm_network_interface.spoke1_vm_nic,
    azurerm_virtual_network_peering.spoke1_to_hub
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# Public IP for Spoke2 VM
resource "azurerm_public_ip" "spoke2_vm_public_ip" {
  name                = "spoke2-vm-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  depends_on = [azurerm_virtual_network.spoke2_vnet]
}

# Create a VM in Spoke2
resource "azurerm_network_interface" "spoke2_vm_nic" {
  name                = "spoke2-vm-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.spoke2_subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id         = azurerm_public_ip.spoke2_vm_public_ip.id
  }

  depends_on = [azurerm_virtual_network_peering.spoke2_to_hub]

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_linux_virtual_machine" "spoke2_vm" {
  name                = "spoke2-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B1s"  # Small VM size
  admin_username      = "admin"

  network_interface_ids = [
    azurerm_network_interface.spoke2_vm_nic.id
  ]

  admin_ssh_key {
    username   = "admin"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  depends_on = [
    azurerm_network_interface.spoke2_vm_nic,
    azurerm_virtual_network_peering.spoke2_to_hub
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# NSG for Spoke1 VM
resource "azurerm_network_security_group" "spoke1_vm_nsg" {
  name                = "spoke1-vm-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range         = "*"
    destination_port_range    = "22"
    source_address_prefix     = "*"
    destination_address_prefix = "*"
  }

  depends_on = [azurerm_virtual_network.spoke1_vnet]

  lifecycle {
    create_before_destroy = true
  }
}

# Associate NSG with Spoke1 VM's NIC
resource "azurerm_network_interface_security_group_association" "spoke1_vm_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.spoke1_vm_nic.id
  network_security_group_id = azurerm_network_security_group.spoke1_vm_nsg.id

  depends_on = [azurerm_linux_virtual_machine.spoke1_vm]

  lifecycle {
    create_before_destroy = true
  }
}

# NSG for Spoke2 VM
resource "azurerm_network_security_group" "spoke2_vm_nsg" {
  name                = "spoke2-vm-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range         = "*"
    destination_port_range    = "22"
    source_address_prefix     = "*"
    destination_address_prefix = "*"
  }

  depends_on = [azurerm_virtual_network.spoke2_vnet]

  lifecycle {
    create_before_destroy = true
  }
}

# Associate NSG with Spoke2 VM's NIC
resource "azurerm_network_interface_security_group_association" "spoke2_vm_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.spoke2_vm_nic.id
  network_security_group_id = azurerm_network_security_group.spoke2_vm_nsg.id

  depends_on = [azurerm_linux_virtual_machine.spoke2_vm]

  lifecycle {
    create_before_destroy = true
  }
} 
