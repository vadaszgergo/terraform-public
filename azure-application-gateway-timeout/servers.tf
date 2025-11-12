# Public IP for Client VM
resource "azurerm_public_ip" "client_vm_pip" {
  name                = "${var.prefix}-client-vm-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Public IP for Server VM
resource "azurerm_public_ip" "server_vm_pip" {
  name                = "${var.prefix}-server-vm-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# NIC for Client VM
resource "azurerm_network_interface" "client_vm_nic" {
  name                = "${var.prefix}-client-vm-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.client_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.client_vm_pip.id
  }
}

# NIC for Server VM
resource "azurerm_network_interface" "server_vm_nic" {
  name                = "${var.prefix}-server-vm-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.server_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.server_vm_pip.id
  }
}


# Client VM (Ubuntu)
resource "azurerm_linux_virtual_machine" "client_vm" {
  name                            = "${var.prefix}-client-vm"
  location                        = var.location
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = "Standard_B1ms"
  admin_username                  = "gergo"
  admin_password                  = "Password123!"
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.client_vm_nic.id
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

  admin_ssh_key {
    username   = "gergo"
    public_key = file("~/.ssh/id_rsa.pub")
  }
}

# Server VM (Ubuntu)
resource "azurerm_linux_virtual_machine" "server_vm" {
  name                            = "${var.prefix}-server-vm"
  location                        = var.location
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = "Standard_B1ms"
  admin_username                  = "gergo"
  admin_password                  = "Password123!"
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.server_vm_nic.id
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

  admin_ssh_key {
    username   = "gergo"
    public_key = file("~/.ssh/id_rsa.pub")
  }
}

# Custom Script Extension to install and configure nginx and Flask app
resource "azurerm_virtual_machine_extension" "server_vm_setup" {
  name                 = "${var.prefix}-server-vm-setup"
  virtual_machine_id   = azurerm_linux_virtual_machine.server_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = jsonencode({
    script = base64encode(file("${path.module}/install.sh"))
  })
}

