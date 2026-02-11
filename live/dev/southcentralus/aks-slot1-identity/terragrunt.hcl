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
  
  slot_name = "slot1"
}

terraform {
  source = "/home/pplavetzki/development/practice/terraform/azure-aks-terraform/modules/managed-identity"
}

dependency "network" {
  config_path = "../virtual-network"
  
  mock_outputs = {
    resource_group_name = "rg-aks-dev-scus"
  }
  mock_outputs_allowed_terraform_commands = ["destroy", "plan"]
}

inputs = {
  identity_name       = "id-aks-${local.environment}-${local.location_short}-${local.slot_name}"
  resource_group_name = dependency.network.outputs.resource_group_name
  location            = local.location
  
  tags = merge(
    local.common_tags,
    {
      Component = "AKS Identity"
      Slot      = local.slot_name
    }
  )
}
