locals {
  # Private IP address for Application Gateway frontend (10.0.1.10)
  appgw_private_ip_address = cidrhost(azurerm_subnet.appgw_subnet.address_prefixes[0], 10)
}

