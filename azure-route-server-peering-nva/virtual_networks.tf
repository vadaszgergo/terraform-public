# Create the Hub VNet
resource "azurerm_virtual_network" "hub_vnet" {
  name                = "hub-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnets in the Hub VNet
resource "azurerm_subnet" "hub_subnet1" {
  name                 = "hub-subnet1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.1.0/24"]  # First available /24 subnet
}

resource "azurerm_subnet" "hub_subnet2" {
  name                 = "hub-subnet2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.2.0/24"]  # Second available /24 subnet
}

# Create a dedicated subnet for Azure Route Server
resource "azurerm_subnet" "route_server_subnet" {
  name                 = "RouteServerSubnet"  # Must be named "RouteServerSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.3.0/27"]  # Dedicated /24 subnet for Route Server
}

/* # Create a dedicated subnet for VPN Gateway
resource "azurerm_subnet" "gateway_subnet" {
  name                 = "GatewaySubnet"  # Must be named "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.4.0/27"]  # Dedicated /27 subnet for VPN Gateway
} */

# Create a public IP for the Azure Route Server
resource "azurerm_public_ip" "route_server_public_ip" {
  name                = "route-server-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create the Azure Route Server
resource "azurerm_route_server" "route_server" {
  name                = "hub-route-server"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  public_ip_address_id = azurerm_public_ip.route_server_public_ip.id
  subnet_id           = azurerm_subnet.route_server_subnet.id
  branch_to_branch_traffic_enabled = true
  hub_routing_preference = "ASPath" # Other options are "ExpressRoute" or "VpnGateway". Default is "ExpressRoute"
}

# Create the first Spoke VNet
resource "azurerm_virtual_network" "spoke1_vnet" {
  name                = "spoke1-vnet"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnets in the first Spoke VNet
resource "azurerm_subnet" "spoke1_subnet1" {
  name                 = "spoke1-subnet1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke1_vnet.name
  address_prefixes     = ["10.1.1.0/24"]  # First available /24 subnet
}

resource "azurerm_subnet" "spoke1_subnet2" {
  name                 = "spoke1-subnet2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke1_vnet.name
  address_prefixes     = ["10.1.2.0/24"]  # Second available /24 subnet
}

# Create the second Spoke VNet
resource "azurerm_virtual_network" "spoke2_vnet" {
  name                = "spoke2-vnet"
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnets in the second Spoke VNet
resource "azurerm_subnet" "spoke2_subnet1" {
  name                 = "spoke2-subnet1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke2_vnet.name
  address_prefixes     = ["10.2.1.0/24"]  # First available /24 subnet
}

resource "azurerm_subnet" "spoke2_subnet2" {
  name                 = "spoke2-subnet2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke2_vnet.name
  address_prefixes     = ["10.2.2.0/24"]  # Second available /24 subnet
}