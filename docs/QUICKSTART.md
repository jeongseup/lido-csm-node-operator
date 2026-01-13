# Quick Start Guide

This guide will help you set up your Ethereum Node Operator environment using Ansible.

## Prerequisites

- **Control Machine**: macOS or Linux
- **Ansible 2.15+**: Install via `pipx` (recommended)
  ```bash
  brew install pipx
  pipx ensurepath
  pipx install --include-deps --python 3.12 ansible
  pipx inject ansible ansible-lint --include-apps
  ```
- **Tailscale**: mesh VPN for secure connectivity ([Why Tailscale?](TAILSCALE_NETWORK.md))

---

## 5-Minute Setup

### 1. Initialize Configuration

Clone the repository and prepare your environment files.

```bash
git clone https://github.com/your-username/lido-csm-operator.git
cd lido-csm-operator

# Copy example environment file
cp .env.example .env
```

### 2. Setup Ansible Vault

We use Ansible Vault to store sensitive information (sudo passwords, API tokens, etc.).

```bash
# 1. Create a vault password file (do not commit this!)
echo "your-strong-password" > .vault_pass.txt
chmod 600 .vault_pass.txt

# 2. Prepare your secrets
cp ansible/playbooks/vars/secrets.yml.example ansible/playbooks/vars/secrets.yml

# 3. Edit and encrypt your secrets
# Fill in YOUR_SUDO_PASSWORD, API tokens, etc.
nano ansible/playbooks/vars/secrets.yml
make av-encrypt  # If you haven't encrypted it yet
```

### 3. Configure Inventory

Define your servers in the inventory files.

```bash
# Copy example inventories
cp ansible/inventory/servers.yml.example ansible/inventory/servers.yml
cp ansible/inventory/nodes.yml.example ansible/inventory/nodes.yml
cp ansible/inventory/vcs.yml.example ansible/inventory/vcs.yml

# Edit with your server IPs (Tailscale IPs recommended)
nano ansible/inventory/servers.yml
```

### 4. Deploy!

Run the playbooks in order to set up your infrastructure.

```bash
# 1. Basic server hardening and tuning
# (UFW, Fail2Ban, Sysctl tuning, kernel hold, etc.)
make ap-setup-servers

# 2. Install Ethereum Node clients
# (EL: Nethermind, CL: Lighthouse, MEV-Boost)
make ap-setup-nodes

# 3. Install Validator Client
make ap-setup-vc
```

---

## Next Steps

- **Monitoring**: Setup Prometheus and Grafana (coming soon)
- **Key Migration**: Move validator keys using `make ap-migrate-vc`
- **Tuning**: Learn more about [System Tuning](SYSTEM_TUNING.md)

For detailed information on the IaC architecture, see [IaC_STRUCTURE.md](IaC_STRUCTURE.md).
