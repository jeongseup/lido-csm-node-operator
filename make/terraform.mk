# =============================================================
#                      Terraform Commands
# =============================================================

# Determine which var files to use based on environment name
# common.tfvars is always included.
# If ENV contains 'node', include hetzner.tfvars.
# If ENV contains 'vc', include gcp.tfvars.
VAR_FILES := -var-file="../../vars/common.tfvars"
ifeq ($(ENV),prod-node)
    VAR_FILES += -var-file="../../vars/prod.hetzner.tfvars"
else ifeq ($(ENV),prod-vc)
    VAR_FILES += -var-file="../../vars/prod.gcp.tfvars"
else ifeq ($(findstring node,$(ENV)),node)
    VAR_FILES += -var-file="../../vars/hetzner.tfvars"
else ifeq ($(findstring vc,$(ENV)),vc)
    VAR_FILES += -var-file="../../vars/gcp.tfvars"
endif

# --- Base Terraform Commands ---

.PHONY: tf-init tf-plan tf-apply tf-destroy

tf-init:
	@echo "===> Terraform 초기화 [$(ENV)]..."
	@terraform -chdir=$(TERRAFORM_DIR) init

tf-plan:
	@echo "===> Terraform 실행 계획 [$(ENV)]..."
	@terraform -chdir=$(TERRAFORM_DIR) plan $(VAR_FILES)

tf-apply:
	@echo "===> Terraform 변경 사항 적용 [$(ENV)]..."
	@terraform -chdir=$(TERRAFORM_DIR) apply $(VAR_FILES)

tf-destroy:
	@echo "===> Terraform 리소스 삭제 [$(ENV)]..."
	@terraform -chdir=$(TERRAFORM_DIR) destroy $(VAR_FILES)

# --- Environment-specific Targets ---

# Dev Node
.PHONY: tf-init-dev-node tf-plan-dev-node tf-apply-dev-node tf-destroy-dev-node
tf-init-dev-node:
	@$(MAKE) tf-init ENV=dev-node
tf-plan-dev-node:
	@$(MAKE) tf-plan ENV=dev-node
tf-apply-dev-node:
	@$(MAKE) tf-apply ENV=dev-node
tf-destroy-dev-node:
	@$(MAKE) tf-destroy ENV=dev-node

# Dev VC
.PHONY: tf-init-dev-vc tf-plan-dev-vc tf-apply-dev-vc tf-destroy-dev-vc
tf-init-dev-vc:
	@$(MAKE) tf-init ENV=dev-vc
tf-plan-dev-vc:
	@$(MAKE) tf-plan ENV=dev-vc
tf-apply-dev-vc:
	@$(MAKE) tf-apply ENV=dev-vc
tf-destroy-dev-vc:
	@$(MAKE) tf-destroy ENV=dev-vc

# Prod Node
.PHONY: tf-init-prod-node tf-plan-prod-node tf-apply-prod-node tf-destroy-prod-node
tf-init-prod-node:
	@$(MAKE) tf-init ENV=prod-node
tf-plan-prod-node:
	@$(MAKE) tf-plan ENV=prod-node
tf-apply-prod-node:
	@$(MAKE) tf-apply ENV=prod-node
tf-destroy-prod-node:
	@$(MAKE) tf-destroy ENV=prod-node

# Prod VC
.PHONY: tf-init-prod-vc tf-plan-prod-vc tf-apply-prod-vc tf-destroy-prod-vc
tf-init-prod-vc:
	@$(MAKE) tf-init ENV=prod-vc
tf-plan-prod-vc:
	@$(MAKE) tf-plan ENV=prod-vc
tf-apply-prod-vc:
	@$(MAKE) tf-apply ENV=prod-vc
tf-destroy-prod-vc:
	@$(MAKE) tf-destroy ENV=prod-vc
