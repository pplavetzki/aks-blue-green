# azure-aks-live/dev/southcentralus/virtual-network/terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Load environment and region variables
locals {
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  
  environment    = local.env_vars.locals.environment
  location       = local.region_vars.locals.location
  location_short = local.region_vars.locals.location_short
  common_tags    = local.env_vars.locals.common_tags
}

# Point to the virtual-network module in GitHub
terraform {
  # Use local path for testing
  source = "/home/pplavetzki/development/practice/terraform/azure-aks-terraform/modules/virtual-network"
#   source = "git::https://github.com/pplavetzki/azure-aks-terraform.git//modules/virtual-network?ref=v0.1.0"
}

# Module inputs
inputs = {
  resource_group_name = "rg-aks-${local.environment}-${local.location_short}"
  location            = local.location
  vnet_name           = "vnet-aks-${local.environment}-${local.location_short}"
  address_space       = ["10.0.0.0/16"]
  
  # ============================================================================
  # BLUE/GREEN DEPLOYMENT SUBNET STRATEGY
  # ============================================================================
  # - Only one slot is active at a time (uncommented)
  # - During blue/green deployment, both slots are active for testing/cutover
  # - After successful cutover, destroy the old slot's cluster and comment out its subnets
  # - Next deployment cycle, uncomment the inactive slot for the new deployment
  #
  # IP Allocation Strategy:
  #   Slot 1: 10.0.0.0/24 (system), 10.0.2.0/23 (user)
  #   Slot 2: 10.0.10.0/24 (system), 10.0.12.0/23 (user)
  #   Shared: 10.0.20.0/24 (services), 10.0.21.0/24 (endpoints)
  #
  # Current State: Initial deployment - slot1 active
  # Last Updated: 2025-02-04
  # Active Slot: slot1
  # ============================================================================
  
  subnets = {
    # ==========================================================================
    # SLOT 1 - AKS Deployment Slot (ACTIVE)
    # Address Range: 10.0.0.0 - 10.0.3.255
    # Status: Currently deployed and serving production traffic
    # ==========================================================================
    "snet-aks-slot1-system" = {
      address_prefix = "10.0.0.0/24"
      service_endpoints = ["Microsoft.KeyVault", "Microsoft.ContainerRegistry"]
    }
    "snet-aks-slot1-apps" = {
      address_prefix = "10.0.2.0/23"
      service_endpoints = ["Microsoft.KeyVault", "Microsoft.ContainerRegistry"]
    }
    
    # ==========================================================================
    # SLOT 2 - AKS Deployment Slot (INACTIVE - Ready for next deployment)
    # Address Range: 10.0.10.0 - 10.0.13.255
    # Status: Not deployed - Uncomment when ready for blue/green deployment
    # ==========================================================================
    "snet-aks-slot2-system" = {
      address_prefix = "10.0.10.0/24"
    }
    "snet-aks-slot2-apps" = {
      address_prefix = "10.0.12.0/23"
    }
    
    # ==========================================================================
    # SHARED INFRASTRUCTURE - Always active, used by both deployment slots
    # ==========================================================================
    
    # Shared services subnet for Application Gateway, Azure Firewall, Bastion
    "snet-shared-services" = {
      address_prefix = "10.0.20.0/24"
    }
    
    # Private endpoints subnet for Azure SQL, Key Vault, ACR, Storage
    "snet-private-endpoints" = {
      address_prefix = "10.0.21.0/24"
    }
  }
  
  tags = merge(
    local.common_tags,
    {
      Component = "Networking"
    }
  )
}
