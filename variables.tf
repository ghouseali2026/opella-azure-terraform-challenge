variable "name" {
  description = "Name of the Virtual Network."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-_.]{1,62}[a-zA-Z0-9_]$", var.name))
    error_message = "VNET name must be 2-64 characters, start/end with alphanumeric and contain only letters, numbers, hyphens, underscores, and periods."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group in which to create the VNET."
  type        = string
}

variable "location" {
  description = "Azure region where the VNET will be created (e.g. 'eastus', 'westeurope')."
  type        = string
}

variable "address_space" {
  description = "List of CIDR address spaces for the VNET."
  type        = list(string)

  validation {
    condition     = length(var.address_space) > 0
    error_message = "At least one address space CIDR must be provided."
  }
}

variable "dns_servers" {
  description = "Optional list of custom DNS server IP addresses. Defaults to Azure-provided DNS when empty."
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = <<-EOT
    Map of subnet definitions. Each key is the subnet name; each value is an object with:
    - address_prefixes           (required) list of CIDR strings
    - service_endpoints          (optional) list of Azure service endpoint strings
    - delegation                 (optional) object with { name, service_delegation_name, service_delegation_actions }
    - nsg_rules                  (optional) map of NSG rule objects (used when create_nsgs = true)

    NSG rule object attributes:
    - priority, direction, access, protocol, source_port_range,
      destination_port_range, source_address_prefix, destination_address_prefix
  EOT
  type        = any
  default     = {}
}

variable "create_nsgs" {
  description = "When true, creates a Network Security Group for each subnet and associates it."
  type        = bool
  default     = true
}

variable "ddos_protection_plan_id" {
  description = "Resource ID of an existing DDoS protection plan to associate with the VNET. Set to null to disable."
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to apply to all resources created by this module."
  type        = map(string)
  default     = {}
}
