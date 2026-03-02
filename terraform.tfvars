# ──────────────────────────────────────────────
# Dev Environment — non-secret variable values
# Secrets (vm_admin_ssh_public_key) are set via
# GitHub Actions secrets / TF_VAR_ env vars.
# ──────────────────────────────────────────────

environment = "dev"
project     = "myapp"
location    = "eastus"
cost_center = "cc-0001"

vnet_address_space = ["10.10.0.0/16"]

subnet_address_prefixes = {
  default = "10.10.1.0/24"
}

vm_size           = "Standard_B1s"
vm_admin_username = "azureuser"
admin_source_ip   = "10.0.0.0/8" # Replace with your actual IP in real usage

tags = {
  team       = "platform"
  repository = "azure-infra"
}
