# Ethereum Node System Tuning Guide

This guide explains Linux system tuning for operating Ethereum nodes. It describes the settings applied by the `setup-tuning.yml` task in the `setup-server.yml` playbook.

## Table of Contents

- [1. Kernel Package Hold](#1-kernel-package-hold)
- [2. File Descriptor Limits](#2-file-descriptor-limits)
- [3. Kernel Parameters (sysctl)](#3-kernel-parameters-sysctl)
- [4. GRUB Boot Parameters](#4-grub-boot-parameters)
- [5. SSD Maintenance](#5-ssd-maintenance)
- [6. Summary](#6-summary)

---

## 1. Kernel Package Hold

### Why Is This Needed?

Automatic kernel upgrades can cause unexpected issues with GRUB settings, driver compatibility, etc. Since Ethereum nodes require 24/7 stable operation, kernel upgrades should be performed manually during planned maintenance windows.

### Applied Settings

The following metapackages are set to `apt-mark hold` status:

| Environment                    | Packages                                                        |
| ------------------------------ | --------------------------------------------------------------- |
| **Ubuntu 24.04 (Home Server)** | `linux-image-generic`, `linux-headers-generic`, `linux-generic` |
| **Ubuntu 24.04 (Hetzner)**     | `linux-image-virtual`, `linux-headers-virtual`                  |

### Verification

```bash
apt-mark showhold | grep linux
```

---

## 2. File Descriptor Limits

### Configuration Location

`/etc/security/limits.conf`

### Applied Settings

```conf
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
```

### Why Is This Needed?

Ethereum clients (EL/CL) need to open many files simultaneously during operation:

| Purpose           | Description                                                       |
| ----------------- | ----------------------------------------------------------------- |
| **P2P Sockets**   | Maintains TCP/UDP connections with hundreds to thousands of peers |
| **RocksDB Files** | Database files used by EL clients like Geth/Erigon                |
| **Log Files**     | Various log file handles                                          |

The Linux default (1024) is too low; you'll encounter `too many open files` errors when peer count increases.

### Recommended Value Rationale

- **1,048,576 (2^20)**: Recommended by most Ethereum clients
- Lighthouse, Geth, and Erigon official documentation recommend this value

---

## 3. Kernel Parameters (sysctl)

### Configuration Location

`/etc/sysctl.conf` or `/etc/sysctl.d/`

---

### 3.1 Storage Tuning (DRAM-less SSD Optimization)

```conf
vm.dirty_background_ratio = 5
vm.dirty_ratio = 15
vm.swappiness = 10
```

#### vm.dirty_background_ratio = 5

| Item            | Description                                                          |
| --------------- | -------------------------------------------------------------------- |
| **Default**     | 10                                                                   |
| **Recommended** | 5                                                                    |
| **Meaning**     | Start background writeback when dirty pages reach 5% of total memory |

**Effect**: DRAM-less SSDs (e.g., Fanxiang S500 Pro) lack write buffers, causing severe performance degradation during bulk writes. A lower value triggers more frequent, smaller writes to distribute SSD load.

#### vm.dirty_ratio = 15

| Item            | Description                                                         |
| --------------- | ------------------------------------------------------------------- |
| **Default**     | 20                                                                  |
| **Recommended** | 15                                                                  |
| **Meaning**     | Force synchronous writes when dirty pages reach 15% of total memory |

**Effect**: Forces disk writes before processes wait for I/O completion. Prevents DB write delays in Ethereum clients.

#### vm.swappiness = 10

| Item            | Description                                     |
| --------------- | ----------------------------------------------- |
| **Default**     | 60                                              |
| **Recommended** | 10                                              |
| **Meaning**     | Swap usage tendency (0=minimal, 100=aggressive) |

**Effect**: Ethereum nodes use substantial memory, and swap-induced performance degradation is severe. A low value maximizes RAM usage and reserves swap as a last resort.

---

### 3.2 Network Tuning (P2P Connection Optimization)

```conf
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 8192
net.core.netdev_max_backlog = 5000
```

#### net.core.somaxconn = 65535

| Item            | Description                                              |
| --------------- | -------------------------------------------------------- |
| **Default**     | 4096 (Ubuntu 24.04)                                      |
| **Recommended** | 65535                                                    |
| **Meaning**     | Maximum connection queue size for `listen()` system call |

**Effect**: Ethereum nodes receive numerous connection requests from P2P network peers. A small queue causes connection drops, limiting peer count.

#### net.ipv4.tcp_max_syn_backlog = 8192

| Item            | Description               |
| --------------- | ------------------------- |
| **Default**     | 1024                      |
| **Recommended** | 8192                      |
| **Meaning**     | TCP SYN packet queue size |

**Effect**: Queue for storing SYN packets during new TCP connections. Prevents connection failures during peer connection surges.

#### net.core.netdev_max_backlog = 5000

| Item            | Description                                            |
| --------------- | ------------------------------------------------------ |
| **Default**     | 1000                                                   |
| **Recommended** | 5000                                                   |
| **Meaning**     | Packet queue size between network interface and kernel |

**Effect**: Prevents packet drops on high-speed networks. Especially important during block propagation when many packets arrive simultaneously.

---

### 3.3 Memory Tuning (RocksDB Optimization)

```conf
vm.max_map_count = 1048576
```

#### vm.max_map_count = 1048576

| Item            | Description                                       |
| --------------- | ------------------------------------------------- |
| **Default**     | 65530                                             |
| **Recommended** | 1048576                                           |
| **Meaning**     | Maximum memory mapping (mmap) regions per process |

**Effect**:

- EL clients like Geth and Erigon use **RocksDB**
- RocksDB memory-maps SST files via mmap
- As chain data grows, thousands of files are created; the default is insufficient
- **Symptoms when insufficient**: `mmap failed: Cannot allocate memory` error

---

## 4. GRUB Boot Parameters

### Configuration Location

`/etc/default/grub`

### Applied Settings

```bash
GRUB_TIMEOUT="2"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash mitigations=off nvme_core.default_ps_max_latency_us=0 pcie_aspm=off"
```

---

### 4.1 GRUB_TIMEOUT = 2

| Item        | Description                    |
| ----------- | ------------------------------ |
| **Default** | 10 (or varies by distribution) |
| **Applied** | 2                              |

**Effect**: Reduces GRUB menu wait time to 2 seconds during boot. Enables faster recovery during reboots.

---

### 4.2 mitigations=off

| Item        | Description      |
| ----------- | ---------------- |
| **Default** | mitigations=auto |
| **Applied** | mitigations=off  |

**Effect**: Disables CPU vulnerability mitigations for Spectre, Meltdown, etc.

> [!WARNING]
> This setting sacrifices some security for performance. Only use on dedicated node servers with minimal external attack exposure.

**Performance Improvement**:

- 5~30% CPU overhead reduction (varies by workload)
- Significant effect on Ethereum nodes due to frequent system calls

---

### 4.3 nvme_core.default_ps_max_latency_us=0

| Item        | Description                      |
| ----------- | -------------------------------- |
| **Default** | Automatic (power states allowed) |
| **Applied** | 0 (disable all power saving)     |

**Effect**: Disables NVMe SSD power saving modes (Power States).

**Why Is This Needed?**

- DRAM-less SSDs (Fanxiang, TEAMGROUP, etc.) have significant latency when waking from low-power states
- Ethereum nodes have frequent random I/O, causing frequent power state transitions
- **Symptoms when insufficient**: Intermittent I/O delays, timeouts

---

### 4.4 pcie_aspm=off

| Item        | Description                           |
| ----------- | ------------------------------------- |
| **Default** | auto                                  |
| **Applied** | off                                   |
| **Meaning** | Disable Active State Power Management |

**Effect**: Disables PCIe link power management.

**Why Is This Needed?**

- PCIe link transitions to low-power state cause NVMe SSD response delays
- ASPM-related issues are common with budget NVMe controllers
- For 24/7 server operation, stability is more important than power savings

---

## 5. SSD Maintenance

### Enable fstrim.timer

Enable `fstrim.timer` to maintain SSD performance and lifespan.

```bash
# Check fstrim timer status
systemctl status fstrim.timer

# Manual execution (if needed)
sudo fstrim -av
```

**Effect**:

- Periodically executes TRIM commands to optimize SSD garbage collection
- Ubuntu default is weekly execution
- Essential for maintaining SSD performance after chain data deletion/cleanup

---

## 6. Summary

### Applied Settings Checklist

| Category        | Parameter                             | Value   | Purpose                   |
| --------------- | ------------------------------------- | ------- | ------------------------- |
| **Kernel Hold** | linux-image-_, linux-headers-_        | hold    | Prevent auto-upgrade      |
| **File Limits** | nofile (soft/hard)                    | 1048576 | High socket/file handles  |
| **Storage**     | vm.dirty_background_ratio             | 5       | Distribute SSD write load |
| **Storage**     | vm.dirty_ratio                        | 15      | Sync write threshold      |
| **Storage**     | vm.swappiness                         | 10      | Minimize swap             |
| **Network**     | net.core.somaxconn                    | 65535   | P2P connection queue      |
| **Network**     | net.ipv4.tcp_max_syn_backlog          | 8192    | TCP connection queue      |
| **Network**     | net.core.netdev_max_backlog           | 5000    | Packet receive queue      |
| **Memory**      | vm.max_map_count                      | 1048576 | RocksDB mmap support      |
| **GRUB**        | GRUB_TIMEOUT                          | 2       | Fast boot                 |
| **GRUB**        | mitigations=off                       | -       | CPU performance           |
| **GRUB**        | nvme_core.default_ps_max_latency_us=0 | -       | NVMe latency prevention   |
| **GRUB**        | pcie_aspm=off                         | -       | PCIe stability            |
| **SSD**         | fstrim.timer                          | enabled | Maintain SSD performance  |

### Verification After Application

```bash
# Check kernel hold status
apt-mark showhold | grep linux

# Check limits
ulimit -n

# Check sysctl
sysctl vm.max_map_count
sysctl net.core.somaxconn

# Check GRUB
cat /proc/cmdline | grep -E 'mitigations|nvme|pcie'

# Check fstrim timer
systemctl status fstrim.timer
```

---

## References

- [Geth Documentation - Hardware Requirements](https://geth.ethereum.org/docs/interface/hardware)
- [Lighthouse Book - System Configuration](https://lighthouse-book.sigmaprime.io/system-requirements.html)
- [NVMe Power Management on Linux](https://wiki.archlinux.org/title/Solid_state_drive/NVMe#Power_management)
- [Linux Kernel - vm.dirty_ratio](https://www.kernel.org/doc/Documentation/sysctl/vm.txt)
- [Ubuntu fstrim.timer](https://wiki.archlinux.org/title/Solid_state_drive#TRIM)
