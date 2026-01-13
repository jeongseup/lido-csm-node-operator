# Tailscale Network Setup for Ethereum Node Operation

This guide explains how and why to use [Tailscale](https://tailscale.com/) as a mesh VPN for managing your Ethereum node infrastructure.

## Why Tailscale?

When operating Ethereum nodes across multiple locations (home servers, cloud instances, remote VCs), you need secure, reliable connectivity. Tailscale provides a **zero-config mesh VPN** that creates a private network across all your devices.

### The Challenge

```
┌─────────────────────────────────────────────────────────────────┐
│                         Public Internet                          │
│                                                                  │
│   [Home Server A]     [Cloud VC]     [Home Server B]            │
│   Behind NAT          Public IP      Behind NAT                 │
│   192.168.1.x         35.x.x.x       192.168.0.x               │
│                                                                  │
│   ❌ Cannot directly connect to each other                      │
│   ❌ Need complex port forwarding                               │
│   ❌ Dynamic IPs complicate SSH access                         │
└─────────────────────────────────────────────────────────────────┘
```

### The Solution with Tailscale

```
┌─────────────────────────────────────────────────────────────────┐
│                      Tailscale Network (100.x.x.x)              │
│                                                                  │
│   [Home Server A]     [Cloud VC]     [Home Server B]            │
│   100.64.0.1          100.64.0.2     100.64.0.3                │
│                                                                  │
│   ✅ Direct WireGuard connections (peer-to-peer when possible) │
│   ✅ Automatic NAT traversal                                    │
│   ✅ Stable IPs regardless of physical network                  │
│   ✅ End-to-end encrypted                                       │
└─────────────────────────────────────────────────────────────────┘
```

---

## Benefits for Ethereum Node Operators

### 1. Simplified Ansible Inventory

Instead of managing dynamic public IPs or complex SSH tunnels:

```ini
# Before (complex, fragile)
[home_servers]
seoul-node ansible_host=dynamic-ddns.example.com ansible_port=22222

# After (simple, stable)
[home_servers]
seoul-node ansible_host=100.64.0.1
```

### 2. Secure Access Without Port Forwarding

- No need to expose SSH (port 22) to the internet
- No need for complex firewall rules for management traffic
- Only expose essential ports (P2P: 30303, 9000)

### 3. Easy VC Migration

When migrating Validator Client keys between hosts:

```bash
# Both source and target are accessible via Tailscale
make ap-migrate-vc-phase1  # Export from source
make ap-migrate-vc-phase2  # Import to target
```

### 4. Mobile Access

Monitor and manage nodes from anywhere using the Tailscale mobile app—your laptop becomes part of the mesh network.

### 5. MagicDNS

Access nodes by hostname instead of IP:

```bash
ssh seoul-node    # Instead of ssh 100.64.0.1
```

---

## Setup Guide

### Prerequisites

- Tailscale account (free tier supports up to 100 devices)
- Root/sudo access on target servers

### 1. Install Tailscale on Each Node

```bash
# Ubuntu/Debian
curl -fsSL https://tailscale.com/install.sh | sh

# Start and authenticate
sudo tailscale up
```

### 2. Generate Auth Keys for Automation

For Ansible-managed nodes, use [auth keys](https://tailscale.com/kb/1085/auth-keys):

1. Go to [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys)
2. Generate a new auth key (reusable, with appropriate expiry)
3. Store in your secrets vault

### 3. Ansible Integration

The `setup-server.yml` playbook can automatically configure Tailscale:

```yaml
# In your inventory vars
tailscale_auth_key: 'tskey-auth-xxxxx'
```

---

## Security Considerations

### What Tailscale Provides

- **End-to-end encryption**: WireGuard protocol
- **Zero-trust networking**: Each device authenticated individually
- **No exposed coordination server**: Only control plane, not data plane

### What You Still Need

- **SSH key authentication**: Tailscale doesn't replace SSH security
- **Firewall rules**: Still configure UFW for P2P ports
- **Regular updates**: Keep Tailscale client updated

### Recommended Firewall Configuration

```bash
# Allow Tailscale interface
ufw allow in on tailscale0

# Allow P2P ports from anywhere (required for Ethereum)
ufw allow 30303/tcp  # EL P2P
ufw allow 30303/udp
ufw allow 9000/tcp   # CL P2P
ufw allow 9000/udp

# SSH only via Tailscale (optional, high security)
ufw allow in on tailscale0 to any port 22
```

---

## Troubleshooting

### Check Tailscale Status

```bash
tailscale status
tailscale ping <peer-name>
```

### Verify Connectivity

```bash
# From your laptop
ssh <tailscale-ip> -v
```

### Common Issues

| Issue                  | Solution                                                    |
| ---------------------- | ----------------------------------------------------------- |
| Cannot connect to peer | Check if both devices are online: `tailscale status`        |
| Slow connection        | Verify direct connection: `tailscale ping --verbose <peer>` |
| Auth key expired       | Generate new key and re-authenticate                        |

---

## References

- [Tailscale Documentation](https://tailscale.com/kb/)
- [Tailscale + SSH](https://tailscale.com/kb/1193/tailscale-ssh)
- [WireGuard Protocol](https://www.wireguard.com/)
- [Auth Keys for Automation](https://tailscale.com/kb/1085/auth-keys)
