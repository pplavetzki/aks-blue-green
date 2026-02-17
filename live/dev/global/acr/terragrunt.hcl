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
  deployment_ip = "YOUR_IP_HERE"
}

terraform {
  source = "/home/pplavetzki/development/practice/terraform/azure-aks-terraform/modules/acr"
}

dependency "resource_group" {
  config_path = "../resource-group"
  
  mock_outputs = {
    name = "rg-aks-dev-global"
  }
  mock_outputs_allowed_terraform_commands = ["destroy", "plan"]
}

inputs = {
  resource_group_name    = dependency.resource_group.outputs.name
  location               = local.location
  acr_name               = "acraks${local.environment}${local.location_short}"
  sku                    = "Premium"
  admin_enabled          = false
  default_network_action = "Deny"
  allowed_ip_ranges      = [local.deployment_ip]

  tags = merge(
    local.common_tags,
    {
      Component = "Container Registry"
    }
  )
}
