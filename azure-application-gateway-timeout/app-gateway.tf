# Public IP for Application Gateway
resource "azurerm_public_ip" "appgw_pip" {
  name                = "${var.prefix}-appgw-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Application Gateway
resource "azurerm_application_gateway" "main" {
  name                = "${var.prefix}-appgw"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = azurerm_subnet.appgw_subnet.id
  }

  frontend_port {
    name = "port-80"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "appgw-public-ip-config"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  frontend_ip_configuration {
    name                          = "appgw-private-ip-config"
    subnet_id                     = azurerm_subnet.appgw_subnet.id
    private_ip_address            = local.appgw_private_ip_address
    private_ip_address_allocation = "Static"
  }

  backend_address_pool {
    name = "server-vm-backend-pool"
    ip_addresses = [
      azurerm_network_interface.server_vm_nic.private_ip_address
    ]
  }

  probe {
    name                                      = "health-probe-port-999"
    protocol                                  = "Http"
    path                                      = "/"
    host                                      = "127.0.0.1"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = false
    port                                      = 999
  }

  backend_http_settings {
    name                                = "http-settings"
    cookie_based_affinity               = "Disabled"
    path                                = "/"
    port                                = 80
    protocol                            = "Http"
    request_timeout                     = 600  # 10 minutes to handle the 450 second delay
    probe_name                          = "health-probe-port-999"
    pick_host_name_from_backend_address = false
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "appgw-public-ip-config"
    frontend_port_name             = "port-80"
    protocol                       = "Http"
  }

  http_listener {
    name                           = "http-listener-private"
    frontend_ip_configuration_name = "appgw-private-ip-config"
    frontend_port_name             = "port-80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "http-rule"
    rule_type                  = "Basic"
    priority                   = 100
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "server-vm-backend-pool"
    backend_http_settings_name = "http-settings"
  }

  request_routing_rule {
    name                       = "http-rule-private"
    rule_type                  = "Basic"
    priority                   = 200
    http_listener_name         = "http-listener-private"
    backend_address_pool_name  = "server-vm-backend-pool"
    backend_http_settings_name = "http-settings"
  }

  depends_on = [
    azurerm_public_ip.appgw_pip,
    azurerm_network_interface.server_vm_nic
  ]
}

