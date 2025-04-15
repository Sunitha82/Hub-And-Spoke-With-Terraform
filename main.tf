# Resource Group
resource "azurerm_resource_group" "hub_spoke" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Hub Virtual Network
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.hub_spoke.location
  resource_group_name = azurerm_resource_group.hub_spoke.name
  tags                = var.tags
}

# Hub Subnets
resource "azurerm_subnet" "hub_gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.hub_spoke.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "hub_firewall" {
  name                 = "AzureFirewallSubnet" # This name is required by Azure
  resource_group_name  = azurerm_resource_group.hub_spoke.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "hub_bastion" {
  name                 = "AzureBastionSubnet" # This name is required by Azure
  resource_group_name  = azurerm_resource_group.hub_spoke.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "hub_management" {
  name                 = "snet-management"
  resource_group_name  = azurerm_resource_group.hub_spoke.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Spoke 1 Virtual Network
resource "azurerm_virtual_network" "spoke1" {
  name                = "vnet-spoke1"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.hub_spoke.location
  resource_group_name = azurerm_resource_group.hub_spoke.name
  tags                = var.tags
}

# Spoke 1 Subnets
resource "azurerm_subnet" "spoke1_workload" {
  name                 = "snet-workload"
  resource_group_name  = azurerm_resource_group.hub_spoke.name
  virtual_network_name = azurerm_virtual_network.spoke1.name
  address_prefixes     = ["10.1.0.0/24"]
}

resource "azurerm_subnet" "spoke1_management" {
  name                 = "snet-management"
  resource_group_name  = azurerm_resource_group.hub_spoke.name
  virtual_network_name = azurerm_virtual_network.spoke1.name
  address_prefixes     = ["10.1.1.0/24"]
}

# Spoke 2 Virtual Network
resource "azurerm_virtual_network" "spoke2" {
  name                = "vnet-spoke2"
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.hub_spoke.location
  resource_group_name = azurerm_resource_group.hub_spoke.name
  tags                = var.tags
}

# Spoke 2 Subnets
resource "azurerm_subnet" "spoke2_workload" {
  name                 = "snet-workload"
  resource_group_name  = azurerm_resource_group.hub_spoke.name
  virtual_network_name = azurerm_virtual_network.spoke2.name
  address_prefixes     = ["10.2.0.0/24"]
}

resource "azurerm_subnet" "spoke2_management" {
  name                 = "snet-management"
  resource_group_name  = azurerm_resource_group.hub_spoke.name
  virtual_network_name = azurerm_virtual_network.spoke2.name
  address_prefixes     = ["10.2.1.0/24"]
}

# VNet Peering: Hub to Spoke 1
resource "azurerm_virtual_network_peering" "hub_to_spoke1" {
  name                         = "peer-hub-to-spoke1"
  resource_group_name          = azurerm_resource_group.hub_spoke.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke1.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit       = true
}

# VNet Peering: Spoke 1 to Hub
resource "azurerm_virtual_network_peering" "spoke1_to_hub" {
  name                         = "peer-spoke1-to-hub"
  resource_group_name          = azurerm_resource_group.hub_spoke.name
  virtual_network_name         = azurerm_virtual_network.spoke1.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false # Will be true once Gateway is provisioned
}

# VNet Peering: Hub to Spoke 2
resource "azurerm_virtual_network_peering" "hub_to_spoke2" {
  name                         = "peer-hub-to-spoke2"
  resource_group_name          = azurerm_resource_group.hub_spoke.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke2.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit       = true
}

# VNet Peering: Spoke 2 to Hub
resource "azurerm_virtual_network_peering" "spoke2_to_hub" {
  name                         = "peer-spoke2-to-hub"
  resource_group_name          = azurerm_resource_group.hub_spoke.name
  virtual_network_name         = azurerm_virtual_network.spoke2.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false # Will be true once Gateway is provisioned
}

# Public IP for Azure Firewall
resource "azurerm_public_ip" "fw_pip" {
  name                = "pip-fw"
  location            = azurerm_resource_group.hub_spoke.location
  resource_group_name = azurerm_resource_group.hub_spoke.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Azure Firewall
resource "azurerm_firewall" "hub" {
  name                = "fw-hub"
  location            = azurerm_resource_group.hub_spoke.location
  resource_group_name = azurerm_resource_group.hub_spoke.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  tags                = var.tags

  ip_configuration {
    name                 = "fw-ip-config"
    subnet_id            = azurerm_subnet.hub_firewall.id
    public_ip_address_id = azurerm_public_ip.fw_pip.id
  }
}

# Azure Firewall Network Rules - Allow traffic between spokes
resource "azurerm_firewall_network_rule_collection" "allow_spoke_to_spoke" {
  name                = "allow-spoke-to-spoke"
  azure_firewall_name = azurerm_firewall.hub.name
  resource_group_name = azurerm_resource_group.hub_spoke.name
  priority            = 100
  action              = "Allow"

  rule {
    name                  = "allow-spoke1-to-spoke2"
    source_addresses      = azurerm_virtual_network.spoke1.address_space
    destination_addresses = azurerm_virtual_network.spoke2.address_space
    destination_ports     = ["*"]
    protocols             = ["Any"]
  }

  rule {
    name                  = "allow-spoke2-to-spoke1"
    source_addresses      = azurerm_virtual_network.spoke2.address_space
    destination_addresses = azurerm_virtual_network.spoke1.address_space
    destination_ports     = ["*"]
    protocols             = ["Any"]
  }
}

# Azure Firewall Application Rules - Allow Internet access
resource "azurerm_firewall_application_rule_collection" "allow_internet" {
  name                = "allow-internet"
  azure_firewall_name = azurerm_firewall.hub.name
  resource_group_name = azurerm_resource_group.hub_spoke.name
  priority            = 200
  action              = "Allow"

  rule {
    name             = "allow-http-https"
    source_addresses = concat(
      azurerm_virtual_network.spoke1.address_space,
      azurerm_virtual_network.spoke2.address_space
    )
    target_fqdns     = ["*.microsoft.com", "*.azure.com", "*.windowsupdate.com"]
    protocol {
      port = "443"
      type = "Https"
    }
    protocol {
      port = "80"
      type = "Http"
    }
  }
}

# Route Table for Spoke 1
resource "azurerm_route_table" "spoke1" {
  name                = "rt-spoke1"
  location            = azurerm_resource_group.hub_spoke.location
  resource_group_name = azurerm_resource_group.hub_spoke.name
  tags                = var.tags
}

# Routes for Spoke 1 - Route to Spoke 2 via Firewall
resource "azurerm_route" "spoke1_to_spoke2" {
  name                = "route-to-spoke2"
  resource_group_name = azurerm_resource_group.hub_spoke.name
  route_table_name    = azurerm_route_table.spoke1.name
  address_prefix      = azurerm_virtual_network.spoke2.address_space[0]
  next_hop_type       = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.hub.ip_configuration[0].private_ip_address
}

# Route for Internet Access via Firewall
resource "azurerm_route" "spoke1_to_internet" {
  name                = "route-to-internet"
  resource_group_name = azurerm_resource_group.hub_spoke.name
  route_table_name    = azurerm_route_table.spoke1.name
  address_prefix      = "0.0.0.0/0"
  next_hop_type       = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.hub.ip_configuration[0].private_ip_address
}

# Associate Route Table to Spoke 1 Subnet
resource "azurerm_subnet_route_table_association" "spoke1_workload" {
  subnet_id      = azurerm_subnet.spoke1_workload.id
  route_table_id = azurerm_route_table.spoke1.id
}

resource "azurerm_subnet_route_table_association" "spoke1_management" {
  subnet_id      = azurerm_subnet.spoke1_management.id
  route_table_id = azurerm_route_table.spoke1.id
}

# Route Table for Spoke 2
resource "azurerm_route_table" "spoke2" {
  name                = "rt-spoke2"
  location            = azurerm_resource_group.hub_spoke.location
  resource_group_name = azurerm_resource_group.hub_spoke.name
  tags                = var.tags
}

# Routes for Spoke 2 - Route to Spoke 1 via Firewall
resource "azurerm_route" "spoke2_to_spoke1" {
  name                = "route-to-spoke1"
  resource_group_name = azurerm_resource_group.hub_spoke.name
  route_table_name    = azurerm_route_table.spoke2.name
  address_prefix      = azurerm_virtual_network.spoke1.address_space[0]
  next_hop_type       = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.hub.ip_configuration[0].private_ip_address
}

# Route for Internet Access via Firewall
resource "azurerm_route" "spoke2_to_internet" {
  name                = "route-to-internet"
  resource_group_name = azurerm_resource_group.hub_spoke.name
  route_table_name    = azurerm_route_table.spoke2.name
  address_prefix      = "0.0.0.0/0"
  next_hop_type       = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.hub.ip_configuration[0].private_ip_address
}

# Associate Route Table to Spoke 2 Subnet
resource "azurerm_subnet_route_table_association" "spoke2_workload" {
  subnet_id      = azurerm_subnet.spoke2_workload.id
  route_table_id = azurerm_route_table.spoke2.id
}

resource "azurerm_subnet_route_table_association" "spoke2_management" {
  subnet_id      = azurerm_subnet.spoke2_management.id
  route_table_id = azurerm_route_table.spoke2.id
}
