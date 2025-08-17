resource "azurerm_virtual_network" "spoke2" {
  name                = "${var.prefix}-spoke2-vnet"
  address_space       = ["172.16.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "spoke2_subnet" {
  name                 = "spoke2-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke2.name
  address_prefixes     = ["172.16.1.0/24"]
}

resource "azurerm_virtual_network_peering" "spoke2_to_hub" {
  name                         = "${var.prefix}-spoke2-to-hub"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.spoke2.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

resource "azurerm_route_table" "spoke2_rt" {
  name                = "${var.prefix}-spoke2-rt"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  route {
    name                   = "default-to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.azfw.ip_configuration[0].private_ip_address
  }

  route {
    name           = "to-your-public-ip"
    address_prefix = "1.2.3.4/32"
    next_hop_type  = "Internet"
  }
}

resource "azurerm_subnet_route_table_association" "spoke2_assoc" {
  subnet_id      = azurerm_subnet.spoke2_subnet.id
  route_table_id = azurerm_route_table.spoke2_rt.id
} 