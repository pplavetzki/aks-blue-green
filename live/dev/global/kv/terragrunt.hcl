include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  
  environment    = local.env_vars.locals.environment
  location       = local.region_vars.locals.location
  location_short = local.region_vars.locals.location_short
  common_tags    = local.env_vars.locals.common_tags
  
  # TODO: Replace with your deployment IP - get via: curl ifconfig.me
  deployment_ip = "136.62.145.185/32"  # <-- ADD YOUR IP HERE
}

terraform {
  source = "/home/pplavetzki/development/practice/terraform/azure-aks-terraform/modules/kv"
}

dependency "resource_group" {
  config_path = "../resource-group"
  
  mock_outputs = {
    name = "rg-aks-dev-global"
  }
  mock_outputs_allowed_terraform_commands = ["destroy", "plan"]
}

inputs = {
  resource_group_name = dependency.resource_group.outputs.name
  location            = local.location
  keyvault_name       = "kv-aks-${local.environment}-${local.location_short}"
  sku_name            = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  default_network_action     = "Deny"                    # <-- CHANGED
  allowed_ip_ranges          = [local.deployment_ip]     # <-- ADDED
  rbac_authorization_enabled = true                     # <-- ADDED
  
  tags = merge(
    local.common_tags,
    {
      Component = "Secrets Management"
    }
  )

  secrets = {
    "db-connection-string" = "Server=localhost;Database=test"
    "api-key"              = "test-api-key-12345"
    "app-secret"           = "my-test-secret"
  }

}
