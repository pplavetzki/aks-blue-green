include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  environment    = local.env_vars.locals.environment
  location       = local.region_vars.locals.location
  location_short = local.region_vars.locals.location_short
  tenant_id      = local.env_vars.locals.tenant_id
}

terraform {
  source = "/home/pplavetzki/development/practice/terraform/azure-aks-terraform/modules/k8s-secret-test"
}

dependency "aks" {
  config_path = "../aks-slot1"

  mock_outputs = {
    cluster_name = "aks-dev-scus-slot1"
    key_vault_secrets_provider = {
      client_id = "00000000-0000-0000-0000-000000000000"
    }
  }
  mock_outputs_allowed_terraform_commands = ["destroy", "plan"]
}

dependency "network" {
  config_path = "../virtual-network"

  mock_outputs = {
    resource_group_name = "rg-aks-dev-scus"
  }
  mock_outputs_allowed_terraform_commands = ["destroy", "plan"]
}

dependency "kv" {
  config_path = "../../global/kv"

  mock_outputs = {
    keyvault_name = "kv-aks-dev-scus"
  }
  mock_outputs_allowed_terraform_commands = ["destroy", "plan"]
}

dependency "acr" {
  config_path = "../../global/acr"

  mock_outputs = {
    acr_login_server = "acraksdevscus.azurecr.io"
  }
  mock_outputs_allowed_terraform_commands = ["destroy", "plan"]
}

inputs = {
  cluster_name                  = dependency.aks.outputs.cluster_name
  resource_group_name           = dependency.network.outputs.resource_group_name
  keyvault_name                 = dependency.kv.outputs.keyvault_name
  kv_secrets_provider_client_id = dependency.aks.outputs.key_vault_secrets_provider.client_id
  tenant_id                     = local.env_vars.locals.tenant_id
  acr_login_server              = dependency.acr.outputs.acr_login_server
  namespace                     = "demo"
}
