# =============================================================
#                      Ansible Commands
# =============================================================

# --- Setup Commands (General) ---

.PHONY: ap-setup-server ap-setup-nodes ap-setup-vc

ap-setup-server:
	@echo "===> Running Ansible Playbook: playbooks/setup-server.yml..."
	@cd $(ANSIBLE_DIR) && \
	ansible-playbook playbooks/setup-server.yml --vault-password-file $(ANSIBLE_VAULT_PASS_FILE) $(ARGS)

ap-setup-nodes:
	@echo "===> Running Ansible Playbook: playbooks/setup-nodes.yml..."
	@cd $(ANSIBLE_DIR) && \
	ansible-playbook playbooks/setup-nodes.yml --vault-password-file $(ANSIBLE_VAULT_PASS_FILE) $(ARGS)

ap-setup-vc:
	@echo "===> Running Ansible Playbook: playbooks/setup-vc.yml..."
	@cd $(ANSIBLE_DIR) && \
	ansible-playbook playbooks/setup-vc.yml --vault-password-file $(ANSIBLE_VAULT_PASS_FILE) $(ARGS)

# --- Tooling & Maintenance ---

.PHONY: ap-import-keys ap-teardown-vc ap-teardown-node

ap-import-keys:
	@echo "===> Running Ansible Playbook: playbooks/import-keys.yml..."
	@cd $(ANSIBLE_DIR) && \
	ansible-playbook playbooks/import-keys.yml --vault-password-file $(ANSIBLE_VAULT_PASS_FILE) $(ARGS)

# --- VC Key Migration Commands ---
# Usage: make ap-migrate-vc SOURCE_HOST=xxx TARGET_HOST=yyy

ap-migrate-vc-phase1:
	@echo "===> [Phase 1] VC Migration: Export from source ($(SOURCE_HOST))..."
	@cd $(ANSIBLE_DIR) && \
	ansible-playbook playbooks/migrate-vc-keys.yml \
		-e "source_host=$(SOURCE_HOST)" \
		-e "target_host=$(TARGET_HOST)" \
		--tags phase1 \
		--vault-password-file $(ANSIBLE_VAULT_PASS_FILE) $(ARGS)

ap-migrate-vc-phase2:
	@echo "===> [Phase 2] VC Migration: Import to target ($(TARGET_HOST))..."
	@cd $(ANSIBLE_DIR) && \
	ansible-playbook playbooks/migrate-vc-keys.yml \
		-e "source_host=$(SOURCE_HOST)" \
		-e "target_host=$(TARGET_HOST)" \
		--tags phase2 \
		--vault-password-file $(ANSIBLE_VAULT_PASS_FILE) $(ARGS)

ap-migrate-vc:
	@echo "===> VC Migration: Full ($(SOURCE_HOST) -> $(TARGET_HOST))..."
	@cd $(ANSIBLE_DIR) && \
	ansible-playbook playbooks/migrate-vc-keys.yml \
		-e "source_host=$(SOURCE_HOST)" \
		-e "target_host=$(TARGET_HOST)" \
		--vault-password-file $(ANSIBLE_VAULT_PASS_FILE) $(ARGS)

# --- Teardown Commands ---

ap-teardown-vc:
	@echo "===> VC Teardown: $(TARGET_VC) (server: $(SERVER_HOST))..."
	@cd $(ANSIBLE_DIR) && \
	ansible-playbook playbooks/teardown-vc.yml \
		-e "target_vc=$(TARGET_VC)" \
		-e "server_host=$(SERVER_HOST)" \
		-e "delete_data=$(DELETE_VC_DATA)" \
		-e "delete_user=$(DELETE_VC_USER)" \
		--vault-password-file $(ANSIBLE_VAULT_PASS_FILE) $(ARGS)

ap-teardown-node:
	@echo "===> Node Teardown: $(TARGET_NODE) (server: $(SERVER_HOST))..."
	@cd $(ANSIBLE_DIR) && \
	ansible-playbook playbooks/teardown-node.yml \
		-e "target_node=$(TARGET_NODE)" \
		-e "server_host=$(SERVER_HOST)" \
		-e "delete_data=$(DELETE_NODE_DATA)" \
		-e "delete_user=$(DELETE_NODE_USER)" \
		--vault-password-file $(ANSIBLE_VAULT_PASS_FILE) $(ARGS)

# --- Vault Commands ---

.PHONY: av-create-pass av-create-secrets av-view av-edit

av-create-pass:
	@echo "===> Creating Ansible vault password..."
	@read -sp "🚨 INFO: Enter your vault password: " confirm && echo "$$confirm" > $(ANSIBLE_DIR)/$(ANSIBLE_VAULT_PASS_FILE)

av-create-secrets:
	@echo "===> Encrypting secrets file..."
	@cd $(ANSIBLE_DIR) && \
	ansible-vault create $(ANSIBLE_SECRETS_FILE)

av-view:
	@echo "===> Viewing encrypted secrets file..."
	@cd $(ANSIBLE_DIR) && \
	ansible-vault view $(ANSIBLE_SECRETS_FILE) --vault-password-file $(ANSIBLE_VAULT_PASS_FILE)

av-edit:
	@echo "===> Editing encrypted secrets file..."
	@cd $(ANSIBLE_DIR) && \
	ansible-vault edit $(ANSIBLE_SECRETS_FILE) --vault-password-file $(ANSIBLE_VAULT_PASS_FILE)

# =============================================================
#                 Examples & Specific Deployments
# =============================================================
# The following targets are examples from the original maintainer's
# environment and may need customization for your setup.

ap-setup-server-hetzner:
	@echo "===> Running setup-server.yml (Hetzner Cloud inventory)..."
	@cd $(ANSIBLE_DIR) && \
	ansible-playbook playbooks/setup-server.yml --vault-password-file $(ANSIBLE_VAULT_PASS_FILE) -i inventory/hcloud.yml $(ARGS)

ap-setup-bucheon:
	@echo "===> Example: Setup bucheon server..."
	@cd $(ANSIBLE_DIR) && \
	ansible-playbook playbooks/setup-server.yml \
		-i inventory/servers.yml \
		--limit p-home-bucheon-server-root \
		--vault-password-file $(ANSIBLE_VAULT_PASS_FILE) $(ARGS)

ap-teardown-vc-bucheon-testnet:
	@$(MAKE) ap-teardown-vc TARGET_VC=p-home-bucheon-vc-ethereum-testnet SERVER_HOST=p-home-bucheon-server-root DELETE_VC_DATA=true DELETE_VC_USER=true

ap-teardown-node-bucheon-testnet:
	@$(MAKE) ap-teardown-node TARGET_NODE=p-home-bucheon-node-ethereum-testnet SERVER_HOST=p-home-bucheon-server-root DELETE_NODE_DATA=true DELETE_NODE_USER=true

