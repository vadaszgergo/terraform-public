resource "azurerm_firewall_network_rule_collection" "spoke_to_spoke" {
  name                = "${var.prefix}-spokes-allow"
  azure_firewall_name = azurerm_firewall.azfw.name
  resource_group_name = azurerm_resource_group.rg.name
  priority            = 150
  action              = "Allow"

  # Spoke1 -> Spoke2 TCP
  rule {
    name                  = "spoke1-to-spoke2-tcp"
    source_addresses      = [azurerm_subnet.spoke1_subnet.address_prefixes[0]]
    destination_addresses = [azurerm_subnet.spoke2_subnet.address_prefixes[0]]
    destination_ports     = ["22", "80", "443"]
    protocols             = ["TCP"]
  }

  # Spoke1 -> Spoke2 ICMP
  rule {
    name                  = "spoke1-to-spoke2-icmp"
    source_addresses      = [azurerm_subnet.spoke1_subnet.address_prefixes[0]]
    destination_addresses = [azurerm_subnet.spoke2_subnet.address_prefixes[0]]
    destination_ports     = ["*"]
    protocols             = ["ICMP"]
  }

  # Spoke2 -> Spoke1 TCP
  rule {
    name                  = "spoke2-to-spoke1-tcp"
    source_addresses      = [azurerm_subnet.spoke2_subnet.address_prefixes[0]]
    destination_addresses = [azurerm_subnet.spoke1_subnet.address_prefixes[0]]
    destination_ports     = ["22", "80", "443"]
    protocols             = ["TCP"]
  }

  # Spoke2 -> Spoke1 ICMP
  rule {
    name                  = "spoke2-to-spoke1-icmp"
    source_addresses      = [azurerm_subnet.spoke2_subnet.address_prefixes[0]]
    destination_addresses = [azurerm_subnet.spoke1_subnet.address_prefixes[0]]
    destination_ports     = ["*"]
    protocols             = ["ICMP"]
  }
}

resource "azurerm_firewall_network_rule_collection" "spokes_to_internet" {
  name                = "${var.prefix}-spokes-to-internet"
  azure_firewall_name = azurerm_firewall.azfw.name
  resource_group_name = azurerm_resource_group.rg.name
  priority            = 200
  action              = "Allow"

  rule {
    name                  = "spokes-to-internet-web"
    source_addresses      = [
      azurerm_subnet.spoke1_subnet.address_prefixes[0],
      azurerm_subnet.spoke2_subnet.address_prefixes[0]
    ]
    destination_addresses = ["*"]
    destination_ports     = ["80", "443"]
    protocols             = ["TCP"]
  }
}

resource "azurerm_firewall_application_rule_collection" "deny_cnn" {
  name                = "${var.prefix}-deny-cnn"
  azure_firewall_name = azurerm_firewall.azfw.name
  resource_group_name = azurerm_resource_group.rg.name
  priority            = 100
  action              = "Deny"

  rule {
    name             = "deny-cnn"
    source_addresses = [
      azurerm_subnet.spoke1_subnet.address_prefixes[0],
      azurerm_subnet.spoke2_subnet.address_prefixes[0]
    ]

    protocol {
      type = "Http"
      port = 80
    }

    protocol {
      type = "Https"
      port = 443
    }

    target_fqdns = [
      "cnn.com"
    ]
  }
} 