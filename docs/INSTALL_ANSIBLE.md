# Installing Ansible on macOS (pipx Method)

## Overview

While `brew install ansible` is a common approach for installing Ansible on macOS, using **pipx** offers several advantages:

- **Isolated virtual environments**: Each package is installed in its own environment, preventing dependency conflicts
- **Python version control**: Install with a specific Python version
- **Flexible plugin management**: Easily inject additional packages like `ansible-lint`, `requests`, etc.
- **Resolves Homebrew conflicts**: Avoids issues like `ansible-lint` not finding the `community.general` collection

---

## Prerequisites

- macOS (Apple Silicon or Intel)
- Homebrew installed ([brew.sh](https://brew.sh))
- Python 3.12+ installed (`brew install python@3.12`)

---

## Installation Steps

### 1. Remove Existing Homebrew Ansible (Optional)

If you have Ansible installed via Homebrew, remove it to prevent conflicts:

```bash
brew uninstall ansible
brew uninstall ansible-lint
```

### 2. Install and Configure pipx

```bash
# Install pipx
brew install pipx

# Add pipx binary path to your PATH
pipx ensurepath
```

> [!NOTE]
> After running `pipx ensurepath`, restart your terminal or run `source ~/.zshrc` to apply the PATH changes.

### 3. Install Ansible

```bash
# Install Ansible with dependencies using Python 3.12
pipx install --include-deps --python 3.12 ansible
```

### 4. Inject Additional Packages

Inject required additional packages into the Ansible environment:

```bash
# ansible-lint (Ansible playbook linter)
pipx inject ansible ansible-lint --include-apps

# requests (HTTP request module, used by URI module, etc.)
pipx inject ansible requests --include-apps

# python-dateutil (Date/time utilities)
pipx inject ansible python-dateutil --include-apps
```

---

## Verification

```bash
# Check Ansible version
ansible --version

# Check ansible-lint version
ansible-lint --version

# List installed collections
ansible-galaxy collection list
```

---

## References

- [Ansible Lint not finding community.general with Homebrew-installed Ansible](https://serverfault.com/questions/1158998/ansible-lint-not-finding-community-general-included-with-homebrew-installed-ansi)
- [Using Ansible --ask-become-pass in a variable](https://serverfault.com/questions/1061344/using-ansible-ask-become-pass-in-a-variable)
- [pipx Official Documentation](https://pipx.pypa.io/stable/)
- [Ansible Installation Guide](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
