############################
# AWS Interconnect - multicloud <-> Azure Multicloud Interconnect (both in preview)
#
# Flow (Azure-initiated):
#   1. Azure: create an ExpressRoute circuit with the MultiCloud SKU. Azure generates an activation key.
#   2. AWS:   accept that activation key, attaching the interconnect to a Direct Connect gateway.
#   3. Azure: connect the circuit to the VNET through an ExpressRoute gateway.
#   4. AWS:   associate the Direct Connect gateway with the VPC's virtual private gateway.
############################

data "aws_caller_identity" "current" {}

############################
# 1. Azure: Multicloud Interconnect circuit
############################

resource "azapi_resource" "interconnect_circuit" {
  type      = "Microsoft.Network/expressRouteCircuits@2025-09-01"
  name      = "${var.prefix}-interconnect"
  parent_id = azurerm_resource_group.rg.id
  location  = azurerm_resource_group.rg.location

  body = {
    sku = {
      name   = "MultiCloud_MeteredData"
      tier   = "MultiCloud"
      family = "MeteredData"
    }
    properties = {
      serviceProviderProperties = {
        serviceProviderName = "AWS"
        peeringLocation     = var.interconnect_peering_location
        bandwidthInMbps     = var.interconnect_bandwidth_mbps
      }
      # AWS account that is allowed to redeem the activation key
      partnerAccountId = data.aws_caller_identity.current.account_id
    }
  }

  # The MultiCloud SKU and partnerAccountId are newer than the schema bundled with azapi
  schema_validation_enabled = false

  response_export_values = {
    activation_key = "properties.activationKey"
    service_key    = "properties.serviceKey"
  }
}

############################
# 2. AWS: Direct Connect gateway + accept the interconnect
############################

resource "aws_dx_gateway" "interconnect" {
  name            = "${var.prefix}-dxgw"
  amazon_side_asn = var.aws_dxgw_asn
}

resource "awscc_interconnect_connection" "azure" {
  description    = "${var.prefix} interconnect to Azure"
  activation_key = azapi_resource.interconnect_circuit.output.activation_key

  attach_point = {
    direct_connect_gateway = aws_dx_gateway.interconnect.id
  }

  tags = [{
    key   = "Project"
    value = var.prefix
  }]
}

############################
# 3. Azure: ExpressRoute gateway + connection to the circuit
############################

resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet" # name is mandatory for gateway subnets
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [local.azure_gateway_subnet_cidr]
}

# Takes 30-45 minutes to deploy
resource "azurerm_virtual_network_gateway" "ergw" {
  name                = "${var.prefix}-ergw"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  type                = "ExpressRoute"
  sku                 = var.azure_ergw_sku

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.gateway.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_network_gateway_connection" "interconnect" {
  name                       = "${var.prefix}-ergw-to-interconnect"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  type                       = "ExpressRoute"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.ergw.id
  express_route_circuit_id   = azapi_resource.interconnect_circuit.id

  # The circuit is only provisioned once AWS has accepted the activation key
  depends_on = [awscc_interconnect_connection.azure]
}

############################
# 4. AWS: virtual private gateway + Direct Connect gateway association
############################

resource "aws_vpn_gateway" "vgw" {
  vpc_id          = aws_vpc.vpc.id
  amazon_side_asn = var.aws_vgw_asn

  tags = {
    Name = "${var.prefix}-vgw"
  }
}

resource "aws_dx_gateway_association" "vgw" {
  dx_gateway_id         = aws_dx_gateway.interconnect.id
  associated_gateway_id = aws_vpn_gateway.vgw.id

  # Prefixes advertised from AWS towards Azure
  allowed_prefixes = [local.aws_vpc_cidr]
}

# Without this the Azure routes never reach the subnet route table
resource "aws_vpn_gateway_route_propagation" "vm" {
  vpn_gateway_id = aws_vpn_gateway.vgw.id
  route_table_id = aws_route_table.vm.id
}
