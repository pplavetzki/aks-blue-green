.PHONY: destroy-all destroy-global destroy-network clean help

# Destroy everything in correct dependency order
destroy-all: destroy-global destroy-network clean
	@echo "✓ All resources destroyed"

# Destroy global resources (reverse dependency order)
destroy-global:
	@echo "Destroying Key Vault..."
	cd live/dev/global/kv && terragrunt destroy -auto-approve
	@echo "Destroying ACR..."
	cd live/dev/global/acr && terragrunt destroy -auto-approve
	@echo "Destroying global resource group..."
	cd live/dev/global/resource-group && terragrunt destroy -auto-approve

# Destroy network resources
destroy-network:
	@echo "Destroying virtual network..."
	cd live/dev/southcentralus/virtual-network && terragrunt destroy -auto-approve

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
