output "azure_resource_group" {
  value = azurerm_resource_group.rg.name
}

output "azure_vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "azure_vm_public_ip" {
  value = azurerm_public_ip.vm.ip_address
}

output "azure_vm_private_ip" {
  value = azurerm_network_interface.vm.private_ip_address
}

output "aws_vpc_id" {
  value = aws_vpc.vpc.id
}

output "aws_vm_public_ip" {
  value = aws_instance.vm.public_ip
}

output "aws_vm_private_ip" {
  value = aws_instance.vm.private_ip
}

output "interconnect_aws_connection_id" {
  value = awscc_interconnect_connection.azure.connection_id
}

output "interconnect_aws_state" {
  value = awscc_interconnect_connection.azure.state
}

output "interconnect_azure_circuit_id" {
  value = azapi_resource.interconnect_circuit.id
}

output "interconnect_activation_key" {
  value     = azapi_resource.interconnect_circuit.output.activation_key
  sensitive = true
}

output "ping_tests" {
  value = <<-EOT

    # From the Azure VM
    ping -c 3 ${aws_instance.vm.private_ip}

    # From the AWS VM
    ping -c 3 ${azurerm_network_interface.vm.private_ip_address}
  EOT
}

output "ssh_commands" {
  value = <<-EOT

    ssh ${var.admin_username}@${azurerm_public_ip.vm.ip_address}   # Azure VM
    ssh ubuntu@${aws_instance.vm.public_ip}   # AWS VM
  EOT
}
