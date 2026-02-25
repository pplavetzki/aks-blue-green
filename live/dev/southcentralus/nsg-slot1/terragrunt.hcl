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
  source = "/home/pplavetzki/development/practice/terraform/azure-aks-terraform/modules/nsg"
}

dependency "network" {
  config_path = "../virtual-network"
  mock_outputs = {
    resource_group_name = "rg-aks-dev-scus"
    subnet_ids = {
      "snet-aks-slot1-system" = "/subscriptions/mock/subnets/mock"
      "snet-aks-slot1-apps"   = "/subscriptions/mock/subnets/mock"
    }
  }
  mock_outputs_allowed_terraform_commands = ["destroy", "plan"]
}

inputs = {
  name                = "nsg-aks-${local.environment}-${local.location_short}-slot1"
  resource_group_name = dependency.network.outputs.resource_group_name
  location            = local.location
  allowed_ip_ranges   = [local.env_vars.locals.deployment_ip]
  subnet_ids = {
    system = dependency.network.outputs.subnet_ids["snet-aks-slot1-system"]
    apps   = dependency.network.outputs.subnet_ids["snet-aks-slot1-apps"]
  }
  tags = merge(local.common_tags, { Component = "NSG", Slot = "slot1" })
}
