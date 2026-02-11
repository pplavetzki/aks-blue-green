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
  source = "/home/pplavetzki/development/practice/terraform/azure-aks-terraform/modules/role-assignment"
}

dependency "aks" {
  config_path = "../aks-slot1"
  
  mock_outputs = {
    kubelet_identity = {
      object_id = "00000000-0000-0000-0000-000000000000"
    }
    key_vault_secrets_provider = {
      object_id = "00000000-0000-0000-0000-000000000000"
    }
  }
  mock_outputs_allowed_terraform_commands = ["destroy", "plan"]
}

dependency "acr" {
  config_path = "../../global/acr"
  
  mock_outputs = {
    acr_id = "/subscriptions/mock/resourceGroups/mock/providers/Microsoft.ContainerRegistry/registries/mock"
  }
  mock_outputs_allowed_terraform_commands = ["destroy", "plan"]
}

dependency "kv" {
  config_path = "../../global/kv"
  
  mock_outputs = {
    keyvault_id = "/subscriptions/mock/resourceGroups/mock/providers/Microsoft.KeyVault/vaults/mock"
  }
  mock_outputs_allowed_terraform_commands = ["destroy", "plan"]
}

inputs = {
  role_assignments = {
    acr_pull = {
      scope                = dependency.acr.outputs.acr_id
      role_definition_name = "AcrPull"
      principal_id         = dependency.aks.outputs.kubelet_identity.object_id
      description          = "Allow AKS ${local.slot_name} to pull images from ACR"
    }
    kv_secrets_user = {
      scope                = dependency.kv.outputs.keyvault_id
      role_definition_name = "Key Vault Secrets User"
      principal_id         = dependency.aks.outputs.key_vault_secrets_provider.object_id
      description          = "Allow AKS ${local.slot_name} Key Vault Secrets Provider to read secrets"
    }
  }
}