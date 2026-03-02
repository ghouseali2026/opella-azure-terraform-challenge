/**
 * # Azure Virtual Network Module
 *
 * A reusable Terraform module that provisions an Azure Virtual Network (VNET)
 * with configurable subnets, optional DDoS protection, optional Network Security
 * Groups (NSG), and optional service endpoints.
 *
 * ## Usage
 *
 * ```hcl
 * module "vnet" {
 *   source = "../../modules/vnet"
 *
 *   name                = "my-vnet"
 *   resource_group_name = "my-rg"
 *   location            = "eastus"
 *   address_space       = ["10.0.0.0/16"]
 *
 *   subnets = {
 *     default = {
 *       address_prefixes  = ["10.0.1.0/24"]
 *       service_endpoints = ["Microsoft.Storage"]
 *     }
 *     app = {
 *       address_prefixes = ["10.0.2.0/24"]
 *     }
 *   }
 *
 *   tags = {
 *     environment = "dev"
 *     project     = "my-project"
 *   }
 * }
 * ```
 */

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.3.0"
}

# ──────────────────────────────────────────────
# Virtual Network
# ──────────────────────────────────────────────
resource "azurerm_virtual_network" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  dns_servers         = var.dns_servers

  dynamic "ddos_protection_plan" {
    for_each = var.ddos_protection_plan_id != null ? [1] : []
    content {
      id     = var.ddos_protection_plan_id
      enable = true
    }
  }

  tags = var.tags
}

# ──────────────────────────────────────────────
# Subnets
# ──────────────────────────────────────────────
resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = lookup(each.value, "service_endpoints", [])

  dynamic "delegation" {
    for_each = lookup(each.value, "delegation", null) != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation_name
        actions = delegation.value.service_delegation_actions
      }
    }
  }
}

# ──────────────────────────────────────────────
# Network Security Groups (optional, one per subnet)
# ──────────────────────────────────────────────
resource "azurerm_network_security_group" "this" {
  for_each = var.create_nsgs ? var.subnets : {}

  name                = "${var.name}-${each.key}-nsg"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_network_security_rule" "this" {
  for_each = {
    for rule in local.nsg_rules : "${rule.subnet_name}-${rule.rule_name}" => rule
    if var.create_nsgs
  }

  name                        = each.value.rule_name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this[each.value.subnet_name].name
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = var.create_nsgs ? var.subnets : {}

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}

# ──────────────────────────────────────────────
# Locals
# ──────────────────────────────────────────────
locals {
  # Flatten NSG rules from the subnets map so we can iterate over them
  nsg_rules = flatten([
    for subnet_name, subnet in var.subnets : [
      for rule_name, rule in lookup(subnet, "nsg_rules", {}) : merge(rule, {
        subnet_name = subnet_name
        rule_name   = rule_name
      })
    ]
  ])
}
