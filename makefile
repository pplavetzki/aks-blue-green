.PHONY: destroy-all destroy-global destroy-network destroy-aks destroy-aks-rbac destroy-aks-identity clean help
.PHONY: deploy-nginx get-kubeconfig install-nginx-ingress deploy-nginx-app get-nginx-ip undeploy-nginx

# ============================================================================
# INFRASTRUCTURE TARGETS
# ============================================================================

# Destroy everything in correct dependency order
# Add to destroy-all target (after destroy-aks-identity):
destroy-all: destroy-aks destroy-aks-rbac destroy-aks-identity destroy-kv-pe destroy-network destroy-regional-rg destroy-global clean
	@echo "✓ All resources destroyed"

# Add new target:
destroy-kv-pe:
	@echo "Destroying Key Vault private endpoint..."
	-cd live/dev/southcentralus/kv-private-endpoint && terragrunt destroy -auto-approve

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

create-all: create-global create-network create-aks-identity create-aks create-aks-rbac create-kv-pe
	@echo "✓ All resources created"

create-kv-pe:
	@echo "Creating Key Vault private endpoint..."
	cd live/dev/southcentralus/kv-private-endpoint && terragrunt apply -auto-approve

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

# ============================================================================
# KUBERNETES DEPLOYMENT TARGETS
# ============================================================================

# Get kubeconfig and deploy NGINX
deploy-nginx: get-kubeconfig install-nginx-ingress deploy-nginx-app
	@echo ""
	@echo "✓ NGINX deployed and accessible"

# Get AKS credentials
get-kubeconfig:
	@echo "Getting AKS credentials..."
	az aks get-credentials \
		--resource-group rg-aks-dev-scus \
		--name aks-dev-scus-slot1 \
		--overwrite-existing \
		--admin
	@echo "✓ Kubeconfig updated"

# Install NGINX Ingress Controller via Helm
install-nginx-ingress:
	@echo "Installing NGINX Ingress Controller..."
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo update
	helm upgrade --install nginx-ingress ingress-nginx/ingress-nginx \
		--namespace ingress-nginx \
		--create-namespace \
		--set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
		--wait
	@echo "✓ NGINX Ingress Controller installed"

# Deploy sample NGINX application
deploy-nginx-app:
	@echo "Deploying sample NGINX application..."
	kubectl apply -f k8s/nginx-demo.yaml
	@echo "Waiting for LoadBalancer IP..."
	@bash -c 'while [ -z "$$(kubectl get svc nginx-ingress-ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)" ]; do echo "Waiting..."; sleep 5; done'
	@echo ""
	@echo "✓ NGINX deployed successfully!"
	@echo ""
	@echo "Access your application at:"
	@echo "  http://$$(kubectl get svc nginx-ingress-ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"

# Get ingress IP
get-nginx-ip:
	@echo "NGINX Ingress IP:"
	@kubectl get svc nginx-ingress-ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
	@echo ""

# Remove NGINX App
remove-nginx-app:
	@echo "Removing NGINX application..."
	-kubectl delete -f k8s/nginx-demo.yaml
	@echo "✓ NGINX application removed"

# Remove NGINX deployment
undeploy-nginx:
	@echo "Removing NGINX application..."
	-kubectl delete -f k8s/nginx-demo.yaml
	@echo "Uninstalling NGINX Ingress Controller..."
	-helm uninstall nginx-ingress -n ingress-nginx
	-kubectl delete namespace ingress-nginx
	@echo "✓ NGINX removed"

# ============================================================================
# HELP
# ============================================================================

help:
	@echo "Available targets:"
	@echo ""
	@echo "Infrastructure:"
	@echo "  make create-all      - Create all infrastructure"
	@echo "  make destroy-all     - Destroy all resources in correct order"
	@echo "  make destroy-global  - Destroy only global resources"
	@echo "  make destroy-network - Destroy only network resources"
	@echo "  make clean           - Clean local Terragrunt cache"
	@echo ""
	@echo "Kubernetes:"
	@echo "  make deploy-nginx    - Deploy NGINX with ingress controller"
	@echo "  make get-nginx-ip    - Show NGINX ingress public IP"
	@echo "  make undeploy-nginx  - Remove NGINX deployment"
	@echo "  make get-kubeconfig  - Get AKS cluster credentials"
