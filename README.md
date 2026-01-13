# Lido CSM Node Operator (Native)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Ansible](https://img.shields.io/badge/Ansible-2.15+-black?logo=ansible)](https://docs.ansible.com/)
[![Tailscale](https://img.shields.io/badge/Tailscale-VPN-blue)](https://tailscale.com/)

A powerful infrastructure automation toolkit for **Ethereum Home Stakers** participating in **Lido's Community Staking Module (CSM)**.

This repository prioritizes **native node operation** (direct systemd services, no Docker-in-Docker overhead), secure mesh networking with **Tailscale**, and enterprise-grade **Ansible** automation.

---

## 🚀 Key Features

- **Native Systemd Services**: High performance and visibility without Docker abstraction layers.
- **Ansible Automation**: Idempotent configuration management for entire server lifecycles.
- **Zero-Downtime VC Migration**: Securely move validator keys between servers with slashing protection management.
- **Built-in Security**: Automated UFW configuration, SSH hardening, Fail2Ban, and kernel-level tuning.
- **Tailscale First**: Seamless multi-server communication without public port exposure.

---

## 🛠 Available Commands (Makefile)

We use `make` as a convenient wrapper for Ansible playbooks.

### Core Setup

| Command                | Description                                         | Playbook           |
| ---------------------- | --------------------------------------------------- | ------------------ |
| `make ap-setup-server` | Hardening, Tuning, Security, and Base libs          | `setup-server.yml` |
| `make ap-setup-nodes`  | Install EL (Nethermind), CL (Lighthouse), MEV-Boost | `setup-nodes.yml`  |
| `make ap-setup-vc`     | Install and configure Validator Client              | `setup-vc.yml`     |

### Security & Vault

- `make av-create-pass`: Initialize your vault password.
- `make av-edit`: Edit your encrypted `secrets.yml`.
- `make av-view`: View encrypted secrets without editing.

### Migration & Maintenance

- `make ap-migrate-vc SOURCE_HOST=... TARGET_HOST=...`: Full automated key migration.
- `make ap-import-keys`: Bulk import keystores to a specific VC.
- `make ap-teardown-vc`: Safely stop and remove a VC service and its data.

---

## 📖 Documentation Index

For technical deep dives, refer to the following guides:

| Document                                        | Description                                          |
| ----------------------------------------------- | ---------------------------------------------------- |
| [**Quick Start Guide**](docs/QUICKSTART.md)     | **Start here!** 5-minute setup from scratch.         |
| [Ansible Installation](docs/INSTALL_ANSIBLE.md) | How to install Ansible via `pipx` (macOS/Linux).     |
| [System Tuning](docs/SYSTEM_TUNING.md)          | Detailed explanation of kernel and OS optimizations. |
| [Tailscale Network](docs/TAILSCALE_NETWORK.md)  | Why we use Tailscale and how it secures your nodes.  |
| [IaC Structure](docs/IaC_STRUCTURE.md)          | Architectural overview of variables and roles.       |

---

## 🏠 Repository Structure

```text
.
├── ansible/
│   ├── inventory/      # Server and node definitions (*.example)
│   └── playbooks/      # Main deployment and maintenance logic
│       ├── tasks/      # Modular setup steps (UFW, Sysctl, etc.)
│       └── vars/       # Network-specific variables (Mainnet/Holesky)
├── docs/               # In-depth technical guides
├── make/               # Makefile modules (Ansible, Terraform)
└── terraform/          # [Experimental] Cloud infrastructure definitions
```

---

## ⚠️ Disclaimer

- **Terraform**: The `terraform/` directory is considered **legacy/experimental**. It was used for initial cloud testing but is not actively maintained for home staking setups.
- **Security**: Always use **Ansible Vault** to protect your `secrets.yml`. Never commit plain-text passwords or mnemonic-related data.

## 🤝 Contributing & License

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md).
Distributed under the **MIT License**. See `LICENSE` for more information.

---

_This project is built by a solo staker for the solo staking community. If you find it helpful, consider giving it a star! ⭐_
