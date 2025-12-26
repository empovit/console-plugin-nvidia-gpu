.PHONY: help build-dev-image build lint type-check i18n clean update-lockfile \
        build-image push-image helm-lint deploy undeploy

# Configuration
REGISTRY ?= quay.io/edge-infrastructure
IMAGE_NAME ?= console-plugin-nvidia-gpu
VERSION ?= $(shell grep '^version:' deployment/console-plugin-nvidia-gpu/Chart.yaml | awk '{print $$2}')
TAG ?= $(shell git rev-parse --short HEAD)
NAMESPACE ?= nvidia-gpu-operator
RELEASE_NAME ?= console-plugin-nvidia-gpu

# Container runtime (podman preferred, falls back to docker)
CONTAINER_TOOL ?= $(shell command -v podman 2>/dev/null || echo docker)
DEV_IMAGE ?= $(IMAGE_NAME)-dev

# Colors for output
BLUE := \033[36m
GREEN := \033[32m
YELLOW := \033[33m
RESET := \033[0m

# All JS/TS targets run inside a container (no Node.js required on host).
# Run 'make build-dev-image' once before using other targets.
# For hot-reload development, use: yarn start (requires Node.js on host)

help: ## Show this help
	@echo "$(BLUE)Available targets:$(RESET)"
	@echo ""
	@echo "$(YELLOW)Development (containerized - no Node.js required):$(RESET)"
	@grep -E '^(build-dev-image|build|lint|type-check|i18n|clean|update-lockfile):.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(BLUE)%-18s$(RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Container Image:$(RESET)"
	@grep -E '^(build-image|push-image):.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(BLUE)%-18s$(RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Helm:$(RESET)"
	@grep -E '^(helm-lint|deploy|undeploy):.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(BLUE)%-18s$(RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Variables:$(RESET)"
	@echo "  TAG=$(TAG)  NAMESPACE=$(NAMESPACE)  VERSION=$(VERSION)"
	@echo ""
	@echo "$(YELLOW)Examples:$(RESET)"
	@echo "  make build-dev-image   # Run once to create dev container"
	@echo "  make build-image TAG=0.3.0"
	@echo "  make deploy NAMESPACE=my-namespace"

##@ Development (containerized)

build-dev-image: ## Build the dev container image (run once)
	@echo "$(GREEN)Building dev image: $(DEV_IMAGE)...$(RESET)"
	$(CONTAINER_TOOL) build -t $(DEV_IMAGE) -f Dockerfile.dev .
	@echo "$(GREEN)✓ Dev image ready. Run 'make build', 'make lint', etc.$(RESET)"

build: ## Build plugin for production
	@echo "$(GREEN)Building plugin (containerized)...$(RESET)"
	@$(CONTAINER_TOOL) run --rm \
		-v "$(CURDIR):/workspace:z" \
		-w /workspace \
		$(DEV_IMAGE) \
		sh -c "yarn install --frozen-lockfile && yarn build"

lint: ## Lint the code
	@echo "$(GREEN)Linting code (containerized)...$(RESET)"
	@$(CONTAINER_TOOL) run --rm \
		-v "$(CURDIR):/workspace:z" \
		-w /workspace \
		$(DEV_IMAGE) \
		sh -c "yarn install --frozen-lockfile && yarn lint"

type-check: ## Check TypeScript types
	@echo "$(GREEN)Type checking (containerized)...$(RESET)"
	@$(CONTAINER_TOOL) run --rm \
		-v "$(CURDIR):/workspace:z" \
		-w /workspace \
		$(DEV_IMAGE) \
		sh -c "yarn install --frozen-lockfile && yarn type-check"

i18n: ## Generate i18n translations
	@echo "$(GREEN)Generating i18n (containerized)...$(RESET)"
	@$(CONTAINER_TOOL) run --rm \
		-v "$(CURDIR):/workspace:z" \
		-w /workspace \
		$(DEV_IMAGE) \
		sh -c "yarn install --frozen-lockfile && yarn i18n"

clean: ## Clean build artifacts
	@echo "$(GREEN)Cleaning build artifacts...$(RESET)"
	rm -rf dist/ *.tgz

update-lockfile: ## Regenerate yarn.lock
	@echo "$(GREEN)Regenerating yarn.lock (containerized)...$(RESET)"
	@$(CONTAINER_TOOL) run --rm \
		-v "$(CURDIR):/workspace:z" \
		-w /workspace \
		--user root \
		$(DEV_IMAGE) \
		sh -c "rm -f yarn.lock && yarn install --ignore-engines && chown $(shell id -u):$(shell id -g) yarn.lock"
	@echo "$(GREEN)✓ yarn.lock regenerated$(RESET)"

##@ Container Image

build-image: ## Build container image
	@echo "$(GREEN)Building image: $(REGISTRY)/$(IMAGE_NAME):$(TAG)$(RESET)"
	$(CONTAINER_TOOL) build -t $(REGISTRY)/$(IMAGE_NAME):$(TAG) .

push-image: build-image ## Build and push container image
	@echo "$(GREEN)Pushing image: $(REGISTRY)/$(IMAGE_NAME):$(TAG)$(RESET)"
	$(CONTAINER_TOOL) push $(REGISTRY)/$(IMAGE_NAME):$(TAG)
	@echo "$(GREEN)✓ Pushed: $(REGISTRY)/$(IMAGE_NAME):$(TAG)$(RESET)"

##@ Helm

helm-lint: ## Lint the Helm chart
	@echo "$(GREEN)Linting Helm chart...$(RESET)"
	helm lint deployment/$(RELEASE_NAME)

deploy: ## Deploy plugin to cluster (install or upgrade)
	@echo "$(GREEN)Deploying plugin...$(RESET)"
	helm upgrade --install -n $(NAMESPACE) $(RELEASE_NAME) \
		--set image.repository=$(REGISTRY)/$(IMAGE_NAME) \
		--set image.tag=$(TAG) \
		./deployment/$(RELEASE_NAME)
	@echo "$(GREEN)✓ Deployed $(RELEASE_NAME)$(RESET)"

undeploy: ## Remove plugin from cluster
	@echo "$(GREEN)Removing $(RELEASE_NAME)...$(RESET)"
	helm uninstall -n $(NAMESPACE) $(RELEASE_NAME)
	@echo "$(GREEN)✓ Removed $(RELEASE_NAME)$(RESET)"
