output "vnet_id" {
  description = "The resource ID of the Virtual Network. Use when peering VNETs or referencing in other modules."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "The name of the Virtual Network."
  value       = azurerm_virtual_network.this.name
}

output "vnet_address_space" {
  description = "The address space of the Virtual Network."
  value       = azurerm_virtual_network.this.address_space
}

output "subnet_ids" {
  description = "Map of subnet name → subnet resource ID. Use to attach VMs, PaaS services, or Private Endpoints."
  value       = { for k, v in azurerm_subnet.this : k => v.id }
}

output "subnet_address_prefixes" {
  description = "Map of subnet name → list of address prefixes."
  value       = { for k, v in azurerm_subnet.this : k => v.address_prefixes }
}

output "nsg_ids" {
  description = "Map of subnet name → NSG resource ID. Only populated when create_nsgs = true."
  value       = { for k, v in azurerm_network_security_group.this : k => v.id }
}
