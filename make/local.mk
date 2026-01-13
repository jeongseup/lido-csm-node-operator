# =============================================================
#                      Local Commands
# =============================================================

# --- Terraform Vars Setup ---

.PHONY: setup-tfvars

setup-tfvars:
	@echo "===> Generating .tfvars files from samples..."
	@for sample in $(wildcard terraform/vars/*.tfvars.sample); do \
		cp $$sample $${sample%.sample}; \
	done

# --- Validator Keys Sync ---

.PHONY: sync-mainnet-keys sync-hoodi-keys

sync-mainnet-keys:
	@echo "===> Syncing mainnet validator keys..."
	@cd ./.keys/mainnet && ./sync_validator_keys.sh

sync-hoodi-keys:
	@echo "===> Syncing hoodi validator keys..."
	@cd .keys/hoodi && ./sync_validator_keys.sh


