# Create a public IP for the NVA
resource "azurerm_public_ip" "nva_public_ip" {
  name                = "nva-test-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create a network interface for the NVA
resource "azurerm_network_interface" "nva_nic" {
  name                          = "nva-test-nic"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  ip_forwarding_enabled          = true  # Required for NVA functionality
  #enable_accelerated_networking = true  # Optional but recommended for better performance

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.hub_subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address           = "10.0.1.4"  # Assign a static IP in hub_subnet1
    public_ip_address_id         = azurerm_public_ip.nva_public_ip.id
  }
}

# Create the Ubuntu NVA VM
resource "azurerm_linux_virtual_machine" "nva_vm" {
  name                = "nva-test"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B2s"
  admin_username      = "admin"
  network_interface_ids = [
    azurerm_network_interface.nva_nic.id
  ]

  admin_ssh_key {
    username   = "admin"
    public_key = file("~/.ssh/id_rsa.pub")  # Make sure you have this key or change to your key
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

  # Enable IP forwarding in Ubuntu
  custom_data = base64encode(<<-EOF
    #!/bin/bash
    # Enable IP forwarding
    echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
    
    # Install FRR for BGP
    sudo apt-get update
    sudo apt-get install -y frr
    
    # Enable BGP in FRR
    sudo sed -i 's/bgpd=no/bgpd=yes/' /etc/frr/daemons
    sudo systemctl restart frr
    
    # Configure BGP
    sudo vtysh -c 'configure terminal' \
    -c 'router bgp 65020' \
    -c 'bgp router-id 10.0.1.4' \
    -c 'no bgp ebgp-requires-policy' \
    -c 'no bgp network import-check' \
    -c 'neighbor 10.0.3.4 remote-as 65515' \
    -c 'neighbor 10.0.3.5 remote-as 65515' \
    -c 'address-family ipv4 unicast' \
    -c 'network 10.0.0.0/8' \
    -c 'exit' \
    -c 'exit' \
    -c 'write memory'
    EOF
  )
}

# Create Route Server BGP Connection with the NVA
resource "azurerm_route_server_bgp_connection" "nva_bgp" {
  name            = "nva-test-bgp"
  route_server_id = azurerm_route_server.route_server.id
  peer_asn        = 65020
  peer_ip         = azurerm_network_interface.nva_nic.private_ip_address
}

# Create NSG for the NVA
resource "azurerm_network_security_group" "nva_nsg" {
  name                = "nva-nsg"
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
}

# Associate NSG with NVA's NIC
resource "azurerm_network_interface_security_group_association" "nva_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nva_nic.id
  network_security_group_id = azurerm_network_security_group.nva_nsg.id
} 
