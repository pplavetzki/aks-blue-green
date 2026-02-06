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
  source = "/home/pplavetzki/development/practice/terraform/azure-aks-terraform/modules/resource-group"
}

inputs = {
  resource_group_name = "rg-global-${local.environment}-${local.location_short}"
  location            = local.location
  
  tags = merge(
    local.common_tags,
    {
      Component = "Global Resources"
    }
  )
}
