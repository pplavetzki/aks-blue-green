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
  source = "/home/pplavetzki/development/practice/terraform/azure-aks-terraform/modules/aks"
}

dependency "network" {
  config_path = "../virtual-network"
}

dependency "identity" {
  config_path = "../aks-slot1-identity"
}

inputs = {
  resource_group_name = dependency.network.outputs.resource_group_name
  location            = local.location
  cluster_name        = "aks-${local.environment}-${local.location_short}-${local.slot_name}"
  dns_prefix          = "aks-${local.environment}-${local.location_short}-${local.slot_name}"
  
  identity_ids = [dependency.identity.outputs.id]
  
  # Default/system node pool
  default_node_pool = {
    name                  = "system"
    vm_size               = "Standard_D2s_v3"
    node_count            = null
    min_count             = 3
    max_count             = 5
    subnet_id             = dependency.network.outputs.subnet_ids["snet-aks-slot1-system"]
    max_pods              = 30
    os_disk_size_gb       = 30
    auto_scaling_enabled  = true
  }
  
  # User node pools (can add multiple)
  user_node_pools = {
    user = {
      vm_size               = "Standard_D2s_v3"
      node_count            = null
      min_count             = 3
      max_count             = 10
      subnet_id             = dependency.network.outputs.subnet_ids["snet-aks-slot1-apps"]
      max_pods              = 30
      os_disk_size_gb       = 30
      auto_scaling_enabled  = true
      mode                  = "User"
      os_type               = "Linux"
      priority              = "Regular"
    }
    # Example: Add a GPU pool later
    # gpu = {
    #   vm_size               = "Standard_NC6s_v3"
    #   node_count            = null
    #   min_count             = 0
    #   max_count             = 3
    #   subnet_id             = dependency.network.outputs.subnet_ids["snet-aks-slot1-apps"]
    #   max_pods              = 30
    #   os_disk_size_gb       = 100
    #   auto_scaling_enabled  = true
    #   mode                  = "User"
    #   os_type               = "Linux"
    #   priority              = "Regular"
    # }
    # Example: Add a spot pool later
    # spot = {
    #   vm_size               = "Standard_D2s_v3"
    #   node_count            = null
    #   min_count             = 0
    #   max_count             = 5
    #   subnet_id             = dependency.network.outputs.subnet_ids["snet-aks-slot1-apps"]
    #   max_pods              = 30
    #   os_disk_size_gb       = 30
    #   auto_scaling_enabled  = true
    #   mode                  = "User"
    #   os_type               = "Linux"
    #   priority              = "Spot"
    # }
  }
  
  network_plugin                    = "azure"
  network_policy                    = null
  enable_key_vault_secrets_provider = true
  enable_workload_identity          = true
  oidc_issuer_enabled               = true
  
  tags = merge(
    local.common_tags,
    {
      Component = "AKS Cluster"
      Slot      = local.slot_name
    }
  )
}
