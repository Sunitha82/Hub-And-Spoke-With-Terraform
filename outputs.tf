# Outputs
output "hub_vnet_id" {
  description = "The ID of the Hub Virtual Network"
  value       = azurerm_virtual_network.hub.id
}

output "spoke1_vnet_id" {
  description = "The ID of Spoke 1 Virtual Network"
  value       = azurerm_virtual_network.spoke1.id
}

output "spoke2_vnet_id" {
  description = "The ID of Spoke 2 Virtual Network"
  value       = azurerm_virtual_network.spoke2.id
}

output "firewall_private_ip" {
  description = "The private IP of the Azure Firewall"
  value       = azurerm_firewall.hub.ip_configuration[0].private_ip_address
}

output "firewall_public_ip" {
  description = "The public IP of the Azure Firewall"
  value       = azurerm_public_ip.fw_pip.ip_address
}
