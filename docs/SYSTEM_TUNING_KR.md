# Ethereum Node System Tuning Guide

이더리움 노드 운영을 위한 Linux 시스템 튜닝 가이드입니다. 이 문서는 `setup-server.yml` 플레이북의 `setup-tuning.yml` 태스크에서 적용되는 설정들의 의미와 효과를 설명합니다.

## 목차

- [1. Kernel Package Hold](#1-kernel-package-hold)
- [2. File Descriptor Limits](#2-file-descriptor-limits)
- [3. Kernel Parameters (sysctl)](#3-kernel-parameters-sysctl)
- [4. GRUB Boot Parameters](#4-grub-boot-parameters)
- [5. SSD Maintenance](#5-ssd-maintenance)
- [6. 요약](#6-요약)

---

## 1. Kernel Package Hold

### 왜 필요한가?

커널 패키지가 자동으로 업그레이드되면 GRUB 설정, 드라이버 호환성 등에서 예기치 않은 문제가 발생할 수 있습니다. 특히 이더리움 노드는 24/7 안정적인 운영이 필수이므로, 커널 업그레이드는 계획된 유지보수 시간에 수동으로 진행하는 것이 좋습니다.

### 적용 설정

다음 메타패키지들이 `apt-mark hold` 상태로 설정됩니다:

| 환경                           | 패키지                                                          |
| ------------------------------ | --------------------------------------------------------------- |
| **Ubuntu 24.04 (Home Server)** | `linux-image-generic`, `linux-headers-generic`, `linux-generic` |
| **Ubuntu 24.04 (Hetzner)**     | `linux-image-virtual`, `linux-headers-virtual`                  |

### 확인 방법

```bash
apt-mark showhold | grep linux
```

---

## 2. File Descriptor Limits

### 설정 위치

`/etc/security/limits.conf`

### 적용 설정

```conf
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
```

### 왜 필요한가?

이더리움 클라이언트(EL/CL)는 운영 중 매우 많은 파일을 동시에 열어야 합니다:

| 용도             | 설명                                              |
| ---------------- | ------------------------------------------------- |
| **P2P 소켓**     | 수백~수천 개의 피어와 TCP/UDP 연결 유지           |
| **RocksDB 파일** | Geth/Erigon 등 EL 클라이언트가 사용하는 DB 파일들 |
| **로그 파일**    | 다양한 로그 파일 핸들                             |

Linux 기본값(1024)은 너무 낮아서 피어 수가 많아지면 `too many open files` 에러가 발생합니다.

### 권장값 근거

- **1,048,576 (2^20)**: 대부분의 이더리움 클라이언트 권장값
- Lighthouse, Geth, Erigon 공식 문서에서 이 값을 권장

---

## 3. Kernel Parameters (sysctl)

### 설정 위치

`/etc/sysctl.conf` 또는 `/etc/sysctl.d/`

---

### 3.1 Storage 튜닝 (DRAM-less SSD 대응)

```conf
vm.dirty_background_ratio = 5
vm.dirty_ratio = 15
vm.swappiness = 10
```

#### vm.dirty_background_ratio = 5

| 항목       | 설명                                                      |
| ---------- | --------------------------------------------------------- |
| **기본값** | 10                                                        |
| **권장값** | 5                                                         |
| **의미**   | 전체 메모리의 5%가 dirty page로 차면 백그라운드 쓰기 시작 |

**효과**: DRAM-less SSD (예: Fanxiang S500 Pro)는 쓰기 버퍼가 없어서 대량 쓰기 시 성능이 급격히 저하됩니다. 낮은 값을 설정하면 더 자주, 적은 양씩 디스크에 쓰기가 발생하여 SSD 부하를 분산시킵니다.

#### vm.dirty_ratio = 15

| 항목       | 설명                                                 |
| ---------- | ---------------------------------------------------- |
| **기본값** | 20                                                   |
| **권장값** | 15                                                   |
| **의미**   | 전체 메모리의 15%가 dirty page로 차면 동기 쓰기 강제 |

**효과**: 프로세스가 I/O 완료를 기다리기 전에 디스크에 쓰도록 강제합니다. 이더리움 클라이언트의 DB 쓰기 지연을 방지합니다.

#### vm.swappiness = 10

| 항목       | 설명                                         |
| ---------- | -------------------------------------------- |
| **기본값** | 60                                           |
| **권장값** | 10                                           |
| **의미**   | 스왑 사용 성향 (0=거의 안 함, 100=적극 사용) |

**효과**: 이더리움 노드는 대량의 메모리를 사용하며, 스왑으로 인한 성능 저하가 심각합니다. 낮은 값으로 설정하여 RAM을 최대한 활용하고 스왑은 최후의 수단으로만 사용합니다.

---

### 3.2 Network 튜닝 (P2P 연결 최적화)

```conf
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 8192
net.core.netdev_max_backlog = 5000
```

#### net.core.somaxconn = 65535

| 항목       | 설명                                         |
| ---------- | -------------------------------------------- |
| **기본값** | 4096 (Ubuntu 24.04)                          |
| **권장값** | 65535                                        |
| **의미**   | `listen()` 시스템 콜의 최대 연결 대기열 크기 |

**효과**: 이더리움 노드는 P2P 네트워크에서 수많은 피어로부터 연결 요청을 받습니다. 대기열이 작으면 연결 요청이 드롭되어 피어 수가 제한됩니다.

#### net.ipv4.tcp_max_syn_backlog = 8192

| 항목       | 설명                     |
| ---------- | ------------------------ |
| **기본값** | 1024                     |
| **권장값** | 8192                     |
| **의미**   | TCP SYN 패킷 대기열 크기 |

**효과**: 새로운 TCP 연결 시 SYN 패킷을 저장하는 큐입니다. 피어 연결 급증 시에도 연결 실패를 방지합니다.

#### net.core.netdev_max_backlog = 5000

| 항목       | 설명                                                        |
| ---------- | ----------------------------------------------------------- |
| **기본값** | 1000                                                        |
| **권장값** | 5000                                                        |
| **의미**   | 네트워크 인터페이스에서 커널로 전달되기 전 패킷 대기열 크기 |

**효과**: 고속 네트워크에서 패킷 드롭을 방지합니다. 특히 블록 전파 시 순간적으로 많은 패킷이 수신됩니다.

---

### 3.3 Memory 튜닝 (RocksDB 최적화)

```conf
vm.max_map_count = 1048576
```

#### vm.max_map_count = 1048576

| 항목       | 설명                                      |
| ---------- | ----------------------------------------- |
| **기본값** | 65530                                     |
| **권장값** | 1048576                                   |
| **의미**   | 프로세스당 최대 메모리 매핑(mmap) 영역 수 |

**효과**:

- Geth, Erigon 등 EL 클라이언트는 **RocksDB**를 사용합니다
- RocksDB는 SST 파일들을 mmap으로 메모리에 매핑합니다
- 체인 데이터가 커지면 수천 개의 파일이 생성되며, 기본값으로는 부족합니다
- **부족 시 증상**: `mmap failed: Cannot allocate memory` 에러

---

## 4. GRUB Boot Parameters

### 설정 위치

`/etc/default/grub`

### 적용 설정

```bash
GRUB_TIMEOUT="2"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash mitigations=off nvme_core.default_ps_max_latency_us=0 pcie_aspm=off"
```

---

### 4.1 GRUB_TIMEOUT = 2

| 항목       | 설명                         |
| ---------- | ---------------------------- |
| **기본값** | 10 (또는 배포판에 따라 다름) |
| **적용값** | 2                            |

**효과**: 부팅 시 GRUB 메뉴 대기 시간을 2초로 단축합니다. 재부팅 시 빠른 복구가 가능합니다.

---

### 4.2 mitigations=off

| 항목       | 설명             |
| ---------- | ---------------- |
| **기본값** | mitigations=auto |
| **적용값** | mitigations=off  |

**효과**: Spectre, Meltdown 등 CPU 취약점 완화 조치를 비활성화합니다.

> [!WARNING]
> 이 설정은 성능을 위해 보안을 일부 희생합니다. 외부 공격 노출이 적은 전용 노드 서버에서만 사용하세요.

**성능 향상**:

- CPU 오버헤드 5~30% 감소 (워크로드에 따라 다름)
- 이더리움 노드는 시스템 콜이 빈번하여 효과가 큽니다

---

### 4.3 nvme_core.default_ps_max_latency_us=0

| 항목       | 설명                        |
| ---------- | --------------------------- |
| **기본값** | 자동 (전원 상태 허용)       |
| **적용값** | 0 (모든 전원 절약 비활성화) |

**효과**: NVMe SSD의 전원 절약 모드(Power States)를 비활성화합니다.

**왜 필요한가?**

- DRAM-less SSD (Fanxiang, TEAMGROUP 등)는 저전력 상태에서 복귀 시 지연이 큽니다
- 이더리움 노드는 랜덤 I/O가 빈번하여 전원 상태 전환이 자주 발생합니다
- **부족 시 증상**: 간헐적인 I/O 지연, 타임아웃

---

### 4.4 pcie_aspm=off

| 항목       | 설명                                   |
| ---------- | -------------------------------------- |
| **기본값** | auto                                   |
| **적용값** | off                                    |
| **의미**   | Active State Power Management 비활성화 |

**효과**: PCIe 링크의 전원 관리를 비활성화합니다.

**왜 필요한가?**

- PCIe 링크가 저전력 상태로 전환되면 NVMe SSD 응답 지연 발생
- 특히 저가형 NVMe 컨트롤러에서 ASPM 관련 문제가 빈번합니다
- 24/7 운영되는 서버에서는 전원 절약보다 안정성이 중요합니다

---

## 5. SSD Maintenance

### fstrim.timer 활성화

SSD의 성능과 수명을 유지하기 위해 `fstrim.timer`를 활성화합니다.

```bash
# fstrim 타이머 상태 확인
systemctl status fstrim.timer

# 수동 실행 (필요 시)
sudo fstrim -av
```

**효과**:

- 주기적으로 TRIM 명령을 실행하여 SSD 가비지 컬렉션을 최적화합니다
- Ubuntu 기본값은 주 1회 실행입니다
- 체인 데이터 삭제/정리 후 SSD 성능 유지에 필수입니다

---

## 6. 요약

### 적용 설정 체크리스트

| 범주            | 파라미터                              | 값      | 목적                 |
| --------------- | ------------------------------------- | ------- | -------------------- |
| **Kernel Hold** | linux-image-_, linux-headers-_        | hold    | 자동 업그레이드 방지 |
| **File Limits** | nofile (soft/hard)                    | 1048576 | 대량 소켓/파일 핸들  |
| **Storage**     | vm.dirty_background_ratio             | 5       | SSD 쓰기 부하 분산   |
| **Storage**     | vm.dirty_ratio                        | 15      | 동기 쓰기 임계점     |
| **Storage**     | vm.swappiness                         | 10      | 스왑 최소화          |
| **Network**     | net.core.somaxconn                    | 65535   | P2P 연결 대기열      |
| **Network**     | net.ipv4.tcp_max_syn_backlog          | 8192    | TCP 연결 대기열      |
| **Network**     | net.core.netdev_max_backlog           | 5000    | 패킷 수신 대기열     |
| **Memory**      | vm.max_map_count                      | 1048576 | RocksDB mmap 지원    |
| **GRUB**        | GRUB_TIMEOUT                          | 2       | 빠른 부팅            |
| **GRUB**        | mitigations=off                       | -       | CPU 성능 최적화      |
| **GRUB**        | nvme_core.default_ps_max_latency_us=0 | -       | NVMe 지연 방지       |
| **GRUB**        | pcie_aspm=off                         | -       | PCIe 안정성          |
| **SSD**         | fstrim.timer                          | enabled | SSD 성능 유지        |

### 적용 후 확인 방법

```bash
# Kernel hold 상태 확인
apt-mark showhold | grep linux

# limits 확인
ulimit -n

# sysctl 확인
sysctl vm.max_map_count
sysctl net.core.somaxconn

# GRUB 확인
cat /proc/cmdline | grep -E 'mitigations|nvme|pcie'

# fstrim 타이머 확인
systemctl status fstrim.timer
```

---

## 참고 자료

- [Geth Documentation - Hardware Requirements](https://geth.ethereum.org/docs/interface/hardware)
- [Lighthouse Book - System Configuration](https://lighthouse-book.sigmaprime.io/system-requirements.html)
- [NVMe Power Management on Linux](https://wiki.archlinux.org/title/Solid_state_drive/NVMe#Power_management)
- [Linux Kernel - vm.dirty_ratio](https://www.kernel.org/doc/Documentation/sysctl/vm.txt)
- [Ubuntu fstrim.timer](https://wiki.archlinux.org/title/Solid_state_drive#TRIM)
