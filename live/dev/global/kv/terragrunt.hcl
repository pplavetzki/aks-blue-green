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
}

terraform {
  source = "/home/pplavetzki/development/practice/terraform/azure-aks-terraform/modules/kv"
}

dependency "resource_group" {
  config_path = "../resource-group"
}

inputs = {
  resource_group_name = dependency.resource_group.outputs.name
  location            = local.location
  keyvault_name       = "kv-aks-${local.environment}-${local.location_short}"
  sku_name            = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  default_network_action     = "Allow"
  
  tags = merge(
    local.common_tags,
    {
      Component = "Secrets Management"
    }
  )
}