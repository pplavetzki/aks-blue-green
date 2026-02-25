.PHONY: clean help
.PHONY: docker-login docker-build docker-push docker-build-push
.PHONY: create-shared create-global create-network create-pips create-nsgs create-kv-pe create-acr-pe
.PHONY: create-slot1 create-aks-slot1-identity create-aks-slot1 create-aks-slot1-rbac
.PHONY: create-slot2 create-aks-slot2-identity create-aks-slot2 create-aks-slot2-rbac
.PHONY: destroy-shared destroy-global destroy-network destroy-pips destroy-nsgs destroy-kv-pe destroy-acr-pe
.PHONY: destroy-slot1 destroy-aks-slot1-rbac destroy-aks-slot1 destroy-aks-slot1-identity
.PHONY: destroy-slot2 destroy-aks-slot2-rbac destroy-aks-slot2 destroy-aks-slot2-identity
.PHONY: destroy-all
.PHONY: get-kubeconfig-slot1 get-kubeconfig-slot2
.PHONY: install-nginx-ingress-slot1 install-nginx-ingress-slot2
.PHONY: deploy-nginx-slot1 deploy-nginx-slot2
.PHONY: undeploy-nginx-slot1 undeploy-nginx-slot2
.PHONY: create-k8s-test
.PHONY: cutover-slot1 cutover-slot2

# ============================================================================
# VARIABLES
# ============================================================================

ACR_NAME   = acraksdevscus
IMAGE_NAME = kv-secret-test
IMAGE_TAG  ?= latest
ACR_SERVER ?= $(shell az acr show --name $(ACR_NAME) --query loginServer -o tsv)

SLOT1_CLUSTER    = aks-dev-scus-slot1
SLOT2_CLUSTER    = aks-dev-scus-slot2
RESOURCE_GROUP   = rg-aks-dev-scus

ALLOWED_IP     ?= $(shell curl -s ifconfig.me)/32
PIP_NAME_SLOT1 = pip-aks-dev-scus-slot1
PIP_NAME_SLOT2 = pip-aks-dev-scus-slot2
PIP_NAME_LIVE  = pip-aks-dev-scus-live

# ============================================================================
# CONTAINER IMAGE TARGETS
# ============================================================================

docker-login:
	@echo "Logging into ACR..."
	az acr login --name $(ACR_NAME)

docker-build:
	@echo "Building image..."
	docker build -t $(ACR_SERVER)/$(IMAGE_NAME):$(IMAGE_TAG) ./validation/keyvault-access

docker-push:
	@echo "Pushing image to ACR..."
	docker push $(ACR_SERVER)/$(IMAGE_NAME):$(IMAGE_TAG)

docker-build-push: docker-login docker-build docker-push
	@echo "✓ Image built and pushed: $(ACR_SERVER)/$(IMAGE_NAME):$(IMAGE_TAG)"

# ============================================================================
# SHARED INFRASTRUCTURE (persistent - survives cluster teardown)
# ============================================================================

create-shared: create-network create-global create-pips create-nsgs create-kv-pe create-acr-pe
	@echo "✓ Shared infrastructure created"

destroy-shared: destroy-nsgs destroy-pips destroy-acr-pe destroy-kv-pe destroy-global destroy-network
	@echo "✓ Shared infrastructure destroyed"

create-network:
	@echo "Creating virtual network..."
	cd live/dev/southcentralus/virtual-network && terragrunt apply -auto-approve

destroy-network:
	@echo "Destroying virtual network..."
	-cd live/dev/southcentralus/virtual-network && terragrunt destroy -auto-approve

create-global: create-network
	@echo "Creating global resource group..."
	cd live/dev/global/resource-group && terragrunt apply -auto-approve
	@echo "Creating Key Vault..."
	cd live/dev/global/kv && terragrunt apply -auto-approve
	@echo "Creating ACR..."
	cd live/dev/global/acr && terragrunt apply -auto-approve

destroy-global:
	@echo "Destroying ACR..."
	-cd live/dev/global/acr && terragrunt destroy -auto-approve
	@echo "Destroying Key Vault..."
	-cd live/dev/global/kv && terragrunt destroy -auto-approve
	@echo "Destroying global resource group..."
	-cd live/dev/global/resource-group && terragrunt destroy -auto-approve

create-pips:
	@echo "Creating public IPs..."
	cd live/dev/southcentralus/pip-slot1 && terragrunt apply -auto-approve
	cd live/dev/southcentralus/pip-slot2 && terragrunt apply -auto-approve
	cd live/dev/southcentralus/pip-live && terragrunt apply -auto-approve

destroy-pips:
	@echo "Destroying public IPs..."
	-cd live/dev/southcentralus/pip-live && terragrunt destroy -auto-approve
	-cd live/dev/southcentralus/pip-slot2 && terragrunt destroy -auto-approve
	-cd live/dev/southcentralus/pip-slot1 && terragrunt destroy -auto-approve

create-nsgs:
	@echo "Creating NSGs..."
	cd live/dev/southcentralus/nsg-shared && terragrunt apply -auto-approve
	cd live/dev/southcentralus/nsg-slot1 && terragrunt apply -auto-approve
	cd live/dev/southcentralus/nsg-slot2 && terragrunt apply -auto-approve

destroy-nsgs:
	@echo "Destroying NSGs..."
	-cd live/dev/southcentralus/nsg-slot1 && terragrunt destroy -auto-approve
	-cd live/dev/southcentralus/nsg-slot2 && terragrunt destroy -auto-approve
	-cd live/dev/southcentralus/nsg-shared && terragrunt destroy -auto-approve

create-kv-pe:
	@echo "Creating Key Vault private endpoint..."
	cd live/dev/southcentralus/kv-private-endpoint && terragrunt apply -auto-approve

destroy-kv-pe:
	@echo "Destroying Key Vault private endpoint..."
	-cd live/dev/southcentralus/kv-private-endpoint && terragrunt destroy -auto-approve

create-acr-pe:
	@echo "Creating ACR private endpoint..."
	cd live/dev/southcentralus/acr-private-endpoint && terragrunt apply -auto-approve

destroy-acr-pe:
	@echo "Destroying ACR private endpoint..."
	-cd live/dev/southcentralus/acr-private-endpoint && terragrunt destroy -auto-approve

# ============================================================================
# SLOT 1
# ============================================================================

create-slot1: create-aks-slot1-identity create-aks-slot1 create-aks-slot1-rbac
	@echo "✓ Slot 1 created"

destroy-slot1: destroy-aks-slot1-rbac destroy-aks-slot1 destroy-aks-slot1-identity
	@echo "✓ Slot 1 destroyed"

create-aks-slot1-identity:
	@echo "Creating AKS Slot 1 identity..."
	cd live/dev/southcentralus/aks-slot1-identity && terragrunt apply -auto-approve

destroy-aks-slot1-identity:
	@echo "Destroying AKS Slot 1 identity..."
	-cd live/dev/southcentralus/aks-slot1-identity && terragrunt destroy -auto-approve

create-aks-slot1:
	@echo "Creating AKS Slot 1..."
	cd live/dev/southcentralus/aks-slot1 && terragrunt apply -auto-approve

destroy-aks-slot1:
	@echo "Destroying AKS Slot 1..."
	-cd live/dev/southcentralus/aks-slot1 && terragrunt destroy -auto-approve

create-aks-slot1-rbac:
	@echo "Creating RBAC for AKS Slot 1..."
	cd live/dev/southcentralus/aks-slot1-rbac && terragrunt apply -auto-approve

destroy-aks-slot1-rbac:
	@echo "Destroying RBAC for AKS Slot 1..."
	-cd live/dev/southcentralus/aks-slot1-rbac && terragrunt destroy -auto-approve

# ============================================================================
# SLOT 2
# ============================================================================

create-slot2: create-aks-slot2-identity create-aks-slot2 create-aks-slot2-rbac
	@echo "✓ Slot 2 created"

destroy-slot2: destroy-aks-slot2-rbac destroy-aks-slot2 destroy-aks-slot2-identity
	@echo "✓ Slot 2 destroyed"

create-aks-slot2-identity:
	@echo "Creating AKS Slot 2 identity..."
	cd live/dev/southcentralus/aks-slot2-identity && terragrunt apply -auto-approve

destroy-aks-slot2-identity:
	@echo "Destroying AKS Slot 2 identity..."
	-cd live/dev/southcentralus/aks-slot2-identity && terragrunt destroy -auto-approve

create-aks-slot2:
	@echo "Creating AKS Slot 2..."
	cd live/dev/southcentralus/aks-slot2 && terragrunt apply -auto-approve

destroy-aks-slot2:
	@echo "Destroying AKS Slot 2..."
	-cd live/dev/southcentralus/aks-slot2 && terragrunt destroy -auto-approve

create-aks-slot2-rbac:
	@echo "Creating RBAC for AKS Slot 2..."
	cd live/dev/southcentralus/aks-slot2-rbac && terragrunt apply -auto-approve

destroy-aks-slot2-rbac:
	@echo "Destroying RBAC for AKS Slot 2..."
	-cd live/dev/southcentralus/aks-slot2-rbac && terragrunt destroy -auto-approve

# ============================================================================
# DESTROY ALL
# ============================================================================

destroy-all: destroy-slot1 destroy-slot2 destroy-shared clean
	@echo "✓ All resources destroyed"

# ============================================================================
# KUBERNETES TARGETS
# ============================================================================

get-kubeconfig-slot1:
	@echo "Getting credentials for Slot 1..."
	az aks get-credentials \
		--resource-group $(RESOURCE_GROUP) \
		--name $(SLOT1_CLUSTER) \
		--admin
	@echo "✓ Kubeconfig merged for Slot 1"

get-kubeconfig-slot2:
	@echo "Getting credentials for Slot 2..."
	az aks get-credentials \
		--resource-group $(RESOURCE_GROUP) \
		--name $(SLOT2_CLUSTER) \
		--admin
	@echo "✓ Kubeconfig merged for Slot 2"

install-nginx-ingress-slot1: get-kubeconfig-slot1
	$(eval PIP_SLOT1 := $(shell az network public-ip show \
		--resource-group $(RESOURCE_GROUP) \
		--name $(PIP_NAME_SLOT1) \
		--query ipAddress -o tsv))
	@echo "Installing NGINX Ingress on Slot 1 (IP: $(PIP_SLOT1))..."
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo update
	helm upgrade --install nginx-ingress ingress-nginx/ingress-nginx \
		--namespace ingress-nginx \
		--create-namespace \
		--set controller.service.loadBalancerIP=$(PIP_SLOT1) \
		--set controller.service.loadBalancerSourceRanges="{$(ALLOWED_IP)}" \
		--set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
		--set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-resource-group"=$(RESOURCE_GROUP) \
		--wait
	@echo "✓ NGINX Ingress installed on Slot 1"

install-nginx-ingress-slot2: get-kubeconfig-slot2
	$(eval PIP_SLOT2 := $(shell az network public-ip show \
		--resource-group $(RESOURCE_GROUP) \
		--name $(PIP_NAME_SLOT2) \
		--query ipAddress -o tsv))
	@echo "Installing NGINX Ingress on Slot 2 (IP: $(PIP_SLOT2))..."
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo update
	helm upgrade --install nginx-ingress ingress-nginx/ingress-nginx \
		--namespace ingress-nginx \
		--create-namespace \
		--set controller.service.loadBalancerIP=$(PIP_SLOT2) \
		--set controller.service.loadBalancerSourceRanges="{$(ALLOWED_IP)}" \
		--set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
		--set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-resource-group"=$(RESOURCE_GROUP) \
		--wait
	@echo "✓ NGINX Ingress installed on Slot 2"

deploy-nginx-slot1: install-nginx-ingress-slot1
	@echo "Deploying NGINX app on Slot 1..."
	kubectl apply -f k8s/nginx-demo.yaml
	@echo "✓ NGINX deployed on Slot 1"

deploy-nginx-slot2: install-nginx-ingress-slot2
	@echo "Deploying NGINX app on Slot 2..."
	kubectl apply -f k8s/nginx-demo.yaml
	@echo "✓ NGINX deployed on Slot 2"

undeploy-nginx-slot1: get-kubeconfig-slot1
	@echo "Removing NGINX from Slot 1..."
	-kubectl delete -f k8s/nginx-demo.yaml
	-helm uninstall nginx-ingress -n ingress-nginx
	-kubectl delete namespace ingress-nginx
	@echo "✓ NGINX removed from Slot 1"

undeploy-nginx-slot2: get-kubeconfig-slot2
	@echo "Removing NGINX from Slot 2..."
	-kubectl delete -f k8s/nginx-demo.yaml
	-helm uninstall nginx-ingress -n ingress-nginx
	-kubectl delete namespace ingress-nginx
	@echo "✓ NGINX removed from Slot 2"

create-k8s-test:
	@echo "Creating k8s secret test..."
	cd live/dev/southcentralus/k8s-secret-test && terragrunt apply -auto-approve

use-slot1:
	kubectl config use-context aks-dev-scus-slot1-admin

use-slot2:
	kubectl config use-context aks-dev-scus-slot2-admin

cutover-slot1:
	$(eval PIP_LIVE := $(shell az network public-ip show \
		--resource-group $(RESOURCE_GROUP) \
		--name $(PIP_NAME_LIVE) \
		--query ipAddress -o tsv))
	@echo "Removing live ingress from Slot 2 (if exists)..."
	-kubectl --context aks-dev-scus-slot2-admin -n ingress-nginx delete -f k8s/nginx-demo-live.yaml 2>/dev/null || true
	-helm --kube-context aks-dev-scus-slot2-admin uninstall nginx-live -n ingress-nginx 2>/dev/null || true
	@echo "Cutting over live traffic to Slot 1 (IP: $(PIP_LIVE))..."
	kubectl config use-context aks-dev-scus-slot1-admin
	helm upgrade --install nginx-live ingress-nginx/ingress-nginx \
		--namespace ingress-nginx \
		--set controller.ingressClassResource.name=nginx-live \
		--set controller.ingressClassResource.controllerValue="k8s.io/nginx-live" \
		--set controller.ingressClass=nginx-live \
		--set controller.service.loadBalancerIP=$(PIP_LIVE) \
		--set controller.service.loadBalancerSourceRanges="{$(ALLOWED_IP)}" \
		--set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
		--set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-resource-group"=$(RESOURCE_GROUP) \
		--wait
	kubectl apply -f k8s/nginx-demo-live.yaml
	@echo "✓ Live traffic now routed to Slot 1"
	@echo "  http://live-aks-dev-scus.southcentralus.cloudapp.azure.com"

cutover-slot2:
	$(eval PIP_LIVE := $(shell az network public-ip show \
		--resource-group $(RESOURCE_GROUP) \
		--name $(PIP_NAME_LIVE) \
		--query ipAddress -o tsv))
	@echo "Removing live ingress from Slot 1 (if exists)..."
	-kubectl --context aks-dev-scus-slot1-admin -n ingress-nginx delete -f k8s/nginx-demo-live.yaml 2>/dev/null || true
	-helm --kube-context aks-dev-scus-slot1-admin uninstall nginx-live -n ingress-nginx 2>/dev/null || true
	@echo "Cutting over live traffic to Slot 2 (IP: $(PIP_LIVE))..."
	kubectl config use-context aks-dev-scus-slot2-admin
	helm upgrade --install nginx-live ingress-nginx/ingress-nginx \
		--namespace ingress-nginx \
		--set controller.ingressClassResource.name=nginx-live \
		--set controller.ingressClassResource.controllerValue="k8s.io/nginx-live" \
		--set controller.ingressClass=nginx-live \
		--set controller.service.loadBalancerIP=$(PIP_LIVE) \
		--set controller.service.loadBalancerSourceRanges="{$(ALLOWED_IP)}" \
		--set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
		--set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-resource-group"=$(RESOURCE_GROUP) \
		--wait
	kubectl apply -f k8s/nginx-demo-live.yaml
	@echo "✓ Live traffic now routed to Slot 2"
	@echo "  http://live-aks-dev-scus.southcentralus.cloudapp.azure.com"

show-live:
	$(eval PIP_LIVE := $(shell az network public-ip show \
		--resource-group $(RESOURCE_GROUP) \
		--name $(PIP_NAME_LIVE) \
		--query ipAddress -o tsv 2>/dev/null))
	$(eval LB_SLOT1 := $(shell az group show \
		--name mc_rg-aks-dev-scus_aks-dev-scus-slot1_southcentralus \
		> /dev/null 2>&1 && \
		az network lb frontend-ip list \
		--resource-group mc_rg-aks-dev-scus_aks-dev-scus-slot1_southcentralus \
		--lb-name kubernetes \
		--query "[?contains(publicIPAddress.id,'$(PIP_NAME_LIVE)')].name" -o tsv 2>/dev/null))
	$(eval LB_SLOT2 := $(shell az group show \
		--name mc_rg-aks-dev-scus_aks-dev-scus-slot2_southcentralus \
		> /dev/null 2>&1 && \
		az network lb frontend-ip list \
		--resource-group mc_rg-aks-dev-scus_aks-dev-scus-slot2_southcentralus \
		--lb-name kubernetes \
		--query "[?contains(publicIPAddress.id,'$(PIP_NAME_LIVE)')].name" -o tsv 2>/dev/null))
	@echo "Live IP: $(PIP_LIVE)"
	@if [ -n "$(LB_SLOT1)" ]; then echo "✓ Live → Slot 1"; \
	elif [ -n "$(LB_SLOT2)" ]; then echo "✓ Live → Slot 2"; \
	else echo "⚠ Live not currently assigned to any slot"; fi
# ============================================================================
# UTILITY
# ============================================================================

clean:
	@echo "Cleaning Terragrunt cache..."
	find . -type d -name ".terragrunt-cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@echo "✓ Cache cleaned"

# ============================================================================
# HELP
# ============================================================================

help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "Shared Infrastructure (persistent):"
	@echo "  create-shared        - Create all shared infrastructure"
	@echo "  destroy-shared       - Destroy all shared infrastructure"
	@echo "  create-network       - Create virtual network"
	@echo "  create-global        - Create global resources (KV, ACR)"
	@echo "  create-pips          - Create public IPs (slot1, slot2, live)"
	@echo "  create-nsgs          - Create NSGs (slot1, slot2, shared)"
	@echo ""
	@echo "Slot 1:"
	@echo "  create-slot1         - Create Slot 1 AKS cluster"
	@echo "  destroy-slot1        - Destroy Slot 1 AKS cluster"
	@echo "  deploy-nginx-slot1   - Deploy NGINX on Slot 1"
	@echo "  undeploy-nginx-slot1 - Remove NGINX from Slot 1"
	@echo ""
	@echo "Slot 2:"
	@echo "  create-slot2         - Create Slot 2 AKS cluster"
	@echo "  destroy-slot2        - Destroy Slot 2 AKS cluster"
	@echo "  deploy-nginx-slot2   - Deploy NGINX on Slot 2"
	@echo "  undeploy-nginx-slot2 - Remove NGINX from Slot 2"
	@echo ""
	@echo "Destroy All:"
	@echo "  destroy-all          - Destroy everything"
	@echo ""
	@echo "Container:"
	@echo "  docker-build-push    - Build and push image to ACR"
	@echo "  docker-login         - Login to ACR"
	@echo "Cutover:"
	@echo "  make cutover-slot1   - Route live traffic to Slot 1, remove from Slot 2"
	@echo "  make cutover-slot2   - Route live traffic to Slot 2, remove from Slot 1"
