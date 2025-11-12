output "client_vm_public_ip" {
  description = "Public IP address of the client VM"
  value       = azurerm_public_ip.client_vm_pip.ip_address
}

output "server_vm_public_ip" {
  description = "Public IP address of the server VM"
  value       = azurerm_public_ip.server_vm_pip.ip_address
}

output "client_vm_ssh_command" {
  description = "SSH command to connect to client VM"
  value       = "ssh gergo@${azurerm_public_ip.client_vm_pip.ip_address}"
}

output "server_vm_ssh_command" {
  description = "SSH command to connect to server VM"
  value       = "ssh gergo@${azurerm_public_ip.server_vm_pip.ip_address}"
}

output "server_vm_nginx_url" {
  description = "URL to access nginx on server VM"
  value       = "http://${azurerm_public_ip.server_vm_pip.ip_address}:999"
}

output "server_vm_flask_url" {
  description = "URL to access Flask webserver on server VM (delays 450 seconds)"
  value       = "http://${azurerm_public_ip.server_vm_pip.ip_address}:80"
}

output "appgw_public_ip" {
  description = "Public IP address of Application Gateway"
  value       = azurerm_public_ip.appgw_pip.ip_address
}

output "appgw_public_url" {
  description = "URL to access Application Gateway (public frontend)"
  value       = "http://${azurerm_public_ip.appgw_pip.ip_address}"
}

output "appgw_private_ip" {
  description = "Private IP address of Application Gateway frontend"
  value       = local.appgw_private_ip_address
}

output "appgw_private_url" {
  description = "URL to access Application Gateway (private frontend)"
  value       = "http://${local.appgw_private_ip_address}"
}
