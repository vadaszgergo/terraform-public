resource "azurerm_firewall_network_rule_collection" "spoke_to_spoke" {
  name                = "${var.prefix}-spokes-allow"
  azure_firewall_name = azurerm_firewall.azfw.name
  resource_group_name = azurerm_resource_group.rg.name
  priority            = 100
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