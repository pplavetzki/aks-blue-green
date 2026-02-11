.PHONY: destroy-all destroy-global destroy-network destroy-aks destroy-aks-rbac destroy-aks-identity clean help

# Destroy everything in correct dependency order
destroy-all: destroy-aks destroy-aks-rbac destroy-aks-identity destroy-network destroy-regional-rg destroy-global clean
	@echo "✓ All resources destroyed"

# Destroy AKS cluster first
destroy-aks:
	@echo "Destroying AKS Slot 1..."
	-cd live/dev/southcentralus/aks-slot1 && terragrunt destroy -auto-approve

# Destroy RBAC assignments (after AKS is gone)
destroy-aks-rbac:
	@echo "Destroying RBAC for AKS Slot 1 Identity..."
	-cd live/dev/southcentralus/aks-slot1-rbac && terragrunt destroy -auto-approve

# Destroy AKS identity (after RBAC is removed)
destroy-aks-identity:
	@echo "Destroying AKS Slot 1 Identity..."
	-cd live/dev/southcentralus/aks-slot1-identity && terragrunt destroy -auto-approve

# Destroy network resources
destroy-network:
	@echo "Destroying virtual network..."
	-cd live/dev/southcentralus/virtual-network && terragrunt destroy -auto-approve

# Destroy regional resource group
destroy-regional-rg:
	@echo "Destroying regional resource group..."
	-cd live/dev/southcentralus/resource-group && terragrunt destroy -auto-approve

# Destroy global resources
destroy-global: destroy-kv destroy-acr destroy-global-rg
	@echo "✓ Global resources destroyed"

destroy-kv:
	@echo "Destroying Key Vault..."
	-cd live/dev/global/kv && terragrunt destroy -auto-approve

destroy-acr:
	@echo "Destroying ACR..."
	-cd live/dev/global/acr && terragrunt destroy -auto-approve

destroy-global-rg:
	@echo "Destroying global resource group..."
	-cd live/dev/global/resource-group && terragrunt destroy -auto-approve

# Clean local state
clean:
	@echo "Cleaning local Terraform state..."
	find live/dev -type d -name ".terragrunt-cache" -exec rm -rf {} + 2>/dev/null || true

create-all: create-global create-network create-aks-identity create-aks create-aks-rbac
	@echo "✓ All resources created"

create-global:
	@echo "Creating global resource group..."
	cd live/dev/global/resource-group && terragrunt apply -auto-approve
	@echo "Creating Key Vault..."
	cd live/dev/global/kv && terragrunt apply -auto-approve
	@echo "Creating ACR..."
	cd live/dev/global/acr && terragrunt apply -auto-approve

create-network:
	@echo "Creating virtual network..."
	cd live/dev/southcentralus/virtual-network && terragrunt apply -auto-approve

create-aks-identity:
	@echo "Creating AKS Slot 1 Identity..."
	cd live/dev/southcentralus/aks-slot1-identity && terragrunt apply -auto-approve

create-aks-rbac:
	@echo "Creating RBAC for AKS Slot 1 Identity..."
	cd live/dev/southcentralus/aks-slot1-rbac && terragrunt apply -auto-approve

create-aks:
	@echo "Creating AKS Slot 1..."
	cd live/dev/southcentralus/aks-slot1 && terragrunt apply -auto-approve

# Clean local Terragrunt cache
clean:
	@echo "Cleaning local Terragrunt cache..."
	find . -type d -name ".terragrunt-cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@echo "✓ Local cache cleaned"

# Help
help:
	@echo "Available targets:"
	@echo "  make destroy-all     - Destroy all resources in correct order"
	@echo "  make destroy-global  - Destroy only global resources"
	@echo "  make destroy-network - Destroy only network resources"
	@echo "  make clean          - Clean local Terragrunt cache"
