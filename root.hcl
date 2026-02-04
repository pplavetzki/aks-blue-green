# azure-aks-live/root.hcl
locals {
  # Parse the file path to extract environment info
  parsed_path = regex(".*/(?P<env>[^/]+)/(?P<region>[^/]+)/(?P<resource>.*)", get_terragrunt_dir())
  
  environment = try(local.parsed_path.env, "")
  region      = try(local.parsed_path.region, "")
  
  # Load environment config to get subscription_id
  env_config_path = find_in_parent_folders("env.hcl", "${get_terragrunt_dir()}/fallback.hcl")
  env_vars        = fileexists(local.env_config_path) ? read_terragrunt_config(local.env_config_path) : null
  subscription_id = local.env_vars != null ? local.env_vars.locals.subscription_id : ""
}

# Configure Terraform to use Azure Storage as backend
remote_state {
  backend = "azurerm"
  
  config = {
    resource_group_name  = "terraform-state"
    storage_account_name = "pareidoliaaksbluegreen"
    container_name       = "tfstate"
    key                  = "${path_relative_to_include()}/terraform.tfstate"
  }
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Generate provider configuration with subscription_id hardcoded
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "azurerm" {
  features {}
  subscription_id = "${local.subscription_id}"
}
EOF
}

# Configure Terraform settings
terraform {
  extra_arguments "common_vars" {
    commands = get_terraform_commands_that_need_vars()
  }
}
