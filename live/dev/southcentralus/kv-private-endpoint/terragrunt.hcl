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
  source = "/home/pplavetzki/development/practice/terraform/azure-aks-terraform/modules/private-endpoint"
}

dependency "kv" {
  config_path = "../../global/kv"
  
  mock_outputs = {
    keyvault_id = "/subscriptions/mock/resourceGroups/mock/providers/Microsoft.KeyVault/vaults/mock"
  }
  mock_outputs_allowed_terraform_commands = ["destroy", "plan"]
}

dependency "network" {
  config_path = "../virtual-network"
  
  mock_outputs = {
    resource_group_name = "rg-aks-dev-scus"
    subnet_ids = {
      "snet-private-endpoints" = "/subscriptions/mock/resourceGroups/mock/providers/Microsoft.Network/virtualNetworks/mock/subnets/mock"
    }
  }
  mock_outputs_allowed_terraform_commands = ["destroy", "plan"]
}

inputs = {
  private_endpoint_name          = "pe-kv-${local.environment}-${local.location_short}"
  location                       = local.location
  resource_group_name            = dependency.network.outputs.resource_group_name
  subnet_id                      = dependency.network.outputs.subnet_ids["snet-private-endpoints"]
  private_connection_resource_id = dependency.kv.outputs.keyvault_id
  subresource_names              = ["vault"]
  
  tags = merge(
    local.common_tags,
    {
      Component = "Private Connectivity"
    }
  )
}
