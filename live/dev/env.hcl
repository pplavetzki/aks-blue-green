# azure-aks-live/dev/env.hcl
locals {
  environment     = "dev"
  subscription_id = "ff193431-e44a-4701-9970-faf2210d232a"
  
  # Common tags for dev
  common_tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
    Project     = "AKS-Demo"
  }
}
