# Replace subscription ID with your own Azure subscription ID
provider "azurerm" {
  features {}
  subscription_id = "xxxxxxxxxxxxxxxxx"
}

# This section tells Terraform to store the state on Azure backend
terraform {
  backend "azurerm" {}
}

# This creates a new resource group
resource "azurerm_resource_group" "example" {
  name     = "azure-devops-resourcegroup"
  location = "UK South"
}

# This creates a new virtual network
resource "azurerm_virtual_network" "example" {
  name                = "new-vnet"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["192.168.0.0/16"]
}

# This creates a new subnet
resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["192.168.1.0/24"]
}

# Public IP for the Ubuntu VM
resource "azurerm_public_ip" "ubuntu" {
  name                = "ubuntu-public-ip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

# Network Interface without NSG
resource "azurerm_network_interface" "ubuntu" {
  name                = "ubuntu-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ubuntu.id
  }
}

resource "azurerm_linux_virtual_machine" "ubuntu" {
  name                = "ubuntu-vm"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  admin_password      = "P@ssw0rd1234!"  # Replace with a secure password
  network_interface_ids = [
    azurerm_network_interface.ubuntu.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "ubuntu-osdisk"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  disable_password_authentication = false
}
