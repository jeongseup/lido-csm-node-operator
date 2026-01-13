# =================================================================
#                    Lido CSM Operator Makefile
# =================================================================

-include .env
export

# --- Configuration ---
ENV ?= prod-node
TERRAFORM_DIR := terraform/environments/$(ENV)
ANSIBLE_DIR := ansible
ANSIBLE_VAULT_PASS_FILE := .vault_pass.txt
ANSIBLE_SECRETS_FILE := playbooks/vars/secrets.yml

# --- Include Modules ---
include make/local.mk
include make/terraform.mk
include make/ansible.mk

# =============================================================
#                 Positional Arguments Handler
# =============================================================

%:
	@: