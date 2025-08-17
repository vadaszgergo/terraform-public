output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "Resource group name"
}

output "hub_vnet_id" {
  value       = azurerm_virtual_network.hub.id
  description = "Hub VNet resource ID"
}

output "spoke1_vnet_id" {
  value       = azurerm_virtual_network.spoke1.id
  description = "Spoke1 VNet resource ID"
}

output "spoke2_vnet_id" {
  value       = azurerm_virtual_network.spoke2.id
  description = "Spoke2 VNet resource ID"
}

output "firewall_private_ip" {
  value       = azurerm_firewall.azfw.ip_configuration[0].private_ip_address
  description = "Azure Firewall private IP address"
}

output "firewall_public_ip" {
  value       = azurerm_public_ip.azfw_pip.ip_address
  description = "Azure Firewall public IP address"
}

output "spoke1_vm_public_ip" {
  value       = azurerm_public_ip.spoke1_vm_pip.ip_address
  description = "Public IP of the Spoke1 VM"
}

output "spoke2_vm_public_ip" {
  value       = azurerm_public_ip.spoke2_vm_pip.ip_address
  description = "Public IP of the Spoke2 VM"
} 