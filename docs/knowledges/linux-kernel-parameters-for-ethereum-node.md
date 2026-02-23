# Linux 커널 파라미터 — 이더리움 노드 운영자를 위한 완전 가이드

> **작성일**: 2026-02-13
> **목적**: Ansible `setup-tuning.yml`에 설정된 모든 sysctl/GRUB 커널 파라미터의 역할과, 이더리움 노드 운영에서 왜 필요한지를 주니어 개발자도 이해할 수 있도록 설명
> **참조 파일**: `ansible/playbooks/tasks/setup-tuning.yml`

---

## 0. 커널 파라미터란?

### sysctl

Linux 커널은 **런타임에 동작 방식을 변경할 수 있는 수백 개의 "노브(knob)"**를 갖고 있습니다. `sysctl`은 이 노브를 돌리는 도구입니다.

```bash
# 현재 값 확인
sysctl vm.swappiness

# 임시 변경 (재부팅하면 초기화)
sudo sysctl -w vm.swappiness=10

# 영구 변경 (파일에 저장)
echo "vm.swappiness = 10" | sudo tee /etc/sysctl.d/99-custom.conf
sudo sysctl -p /etc/sysctl.d/99-custom.conf
```

### GRUB 커널 파라미터

GRUB은 부팅 시 커널에 **명령줄 인자**를 전달합니다. 이건 커널이 시작할 때부터 적용되는 설정으로, sysctl보다 더 저수준입니다.

```bash
# 현재 부팅 시 전달된 파라미터 확인
cat /proc/cmdline
```

---

## 1. GRUB 파라미터 상세

### `mitigations=off`

```
GRUB_CMDLINE_LINUX_DEFAULT="... mitigations=off ..."
```

**무엇?**: CPU 보안 취약점(Spectre, Meltdown 등) 완화 기능을 비활성화합니다.

**배경 지식**:
2018년에 발견된 Spectre/Meltdown은 CPU의 **투기적 실행(Speculative Execution)** 과정에서 다른 프로세스의 메모리를 읽을 수 있는 취약점입니다. Linux 커널은 이를 방어하기 위해 패치를 적용했지만, 이 패치가 **CPU 성능을 5~30% 저하**시킵니다.

**이더리움 노드에서 왜?**:

- 블록체인 노드는 **전용 서버**로 운영 → 다른 사용자가 없어 취약점 악용 위험 낮음
- 블록 검증/상태 계산이 CPU 집약적 → **5~30% 성능 향상 효과가 큼**
- 특히 합의 클라이언트(Lighthouse, Prysm)의 에폭(epoch) 처리 시 CPU 피크가 발생

**주의**: 공유 서버, 클라우드 VM, 멀티테넌트 환경에서는 **절대 끄면 안 됨**

| 환경                           | mitigations=off             |
| ------------------------------ | --------------------------- |
| ✅ 전용 자체 서버 (Bare Metal) | 안전하게 사용 가능          |
| ❌ 클라우드 VM (AWS, GCP 등)   | 비권장 (다른 VM과 CPU 공유) |
| ❌ 공유 호스팅                 | 절대 금지                   |

### `nvme_core.default_ps_max_latency_us=0`

```
GRUB_CMDLINE_LINUX_DEFAULT="... nvme_core.default_ps_max_latency_us=0 ..."
```

**무엇?**: NVMe SSD의 **전원 절약 모드(Power State)를 완전히 비활성화**합니다.

**배경 지식**:
NVMe SSD는 유휴 시 전력을 아끼기 위해 저전력 상태로 전환합니다. 문제는 이 상태에서 갑자기 I/O 요청이 들어오면 **깨어나는 데 시간이 걸려** 일시적인 I/O 멈춤(stall)이 발생합니다.

**이더리움 노드에서 왜?**:

```
이더리움 노드의 I/O 패턴:
                    ┌─ 블록 동기화 시 폭발적 쓰기
  I/O 요청량       │
      ▲   ████     │     ████
      │   ████     │     ████
      │   ████ ░░░░│░░░░ ████   ← 이 조용한 구간에서 SSD가 절전 모드 진입
      │   ████ ░░░░│░░░░ ████
      └──────────────────────→ 시간

  SSD가 절전에서 깨어나는 동안 → 블록 처리 지연 → attestation miss 위험!
```

- 실행 클라이언트(Geth, Erigon)는 RocksDB/MDBX로 **대량의 랜덤 I/O** 발생
- 합의 클라이언트도 beacon state를 디스크에서 읽음
- SSD 절전 해제 지연 → attestation/proposal **deadline miss → 보상 손실**

### `pcie_aspm=off`

```
GRUB_CMDLINE_LINUX_DEFAULT="... pcie_aspm=off ..."
```

**무엇?**: PCIe Active State Power Management(ASPM)을 비활성화합니다.

**배경 지식**:
ASPM은 PCIe 링크(CPU ↔ NVMe, GPU, 네트워크카드 등)의 **전력 절약 기능**입니다. 유휴 시 링크 속도를 낮추거나 비활성화합니다.

**이더리움 노드에서 왜?**:

- NVMe SSD는 PCIe를 통해 연결됨
- ASPM이 PCIe 링크를 절전시키면 → NVMe 접근 지연 발생
- `nvme_core` 파라미터와 함께 사용해야 **I/O 지연을 완전히 제거**

---

## 2. Storage(디스크) 관련 sysctl

### `vm.dirty_background_ratio = 5`

**무엇?**: 전체 메모리의 5%가 "더티 페이지"로 쌓이면 **백그라운드에서 디스크 쓰기 시작**

**더티 페이지(Dirty Page)란?**:

```
프로그램이 파일에 쓰기 → 실제로는 RAM에만 씀 (빠름!)
                         ↓
                    이 RAM 페이지가 "더티(dirty)" 상태
                         ↓
                    나중에 커널이 디스크에 flush
```

커널은 성능을 위해 디스크 쓰기를 RAM에 모아뒀다가 한꺼번에 기록합니다. 이걸 **Write-back 캐시**라고 합니다.

**이더리움 노드에서 왜 5%?**:

- 30GB RAM 기준 → 약 1.5GB가 쌓이면 백그라운드 flush 시작
- **너무 높으면**: 더티 데이터가 많이 쌓였다가 한꺼번에 flush → I/O 스파이크 → 블록 처리 지연
- **너무 낮으면**: 너무 자주 flush → SSD 수명 단축
- **5%는 균형점**: 적당히 자주 flush하되 SSD에 과부하 안 줌

### `vm.dirty_ratio = 15`

**무엇?**: 전체 메모리의 15%가 더티 페이지로 쌓이면 **프로세스를 블록(차단)하고 강제 flush**

```
더티 페이지 비율:
  0%────5%────────15%────────100%
       ↑            ↑
       │            └─ dirty_ratio: 여기 도달하면 프로세스가 멈추고 강제 기록
       └─ dirty_background_ratio: 여기부터 백그라운드 기록 시작

  정상 동작 흐름:
  쓰기 → 더티 5% 도달 → 백그라운드 flush 시작 → 15% 도달하기 전에 처리 완료

  비정상 (flush가 못 따라갈 때):
  쓰기 → 15% 도달! → 🔴 프로세스 멈춤 → 강제 flush → 완료 후 재개
```

**이더리움 노드에서 왜 15%?**:

- Geth/Erigon은 블록 처리 시 **대량의 state 업데이트**를 디스크에 기록
- 기본값(20%)보다 낮춰서 **I/O 스파이크를 줄임**
- DRAM-less SSD(저가 NVMe)에서 특히 중요 — 자체 캐시가 없어 더티 페이지 급증 시 성능 급감

### DRAM-less SSD란?

```
일반 NVMe SSD:
┌──────────┐    ┌──────────┐    ┌──────────┐
│  호스트   │───→│ DRAM     │───→│ NAND     │
│  (CPU)   │    │ (캐시)    │    │ (저장소)  │
└──────────┘    └──────────┘    └──────────┘
                 ↑ FTL 매핑 테이블을 DRAM에 캐시 → 빠름

DRAM-less SSD (저가형):
┌──────────┐    ┌──────────┐
│  호스트   │───→│ NAND     │  ← DRAM 없음, 호스트 메모리(HMB) 사용 또는 느림
│  (CPU)   │    │ (저장소)  │
└──────────┘    └──────────┘
```

DRAM-less SSD는 FTL(Flash Translation Layer) 테이블을 자체 캐시할 수 없어서, 대량 쓰기 시 성능이 급격히 떨어집니다. `dirty_ratio`를 낮추면 한 번에 몰리는 쓰기량을 줄여 이 문제를 완화합니다.

---

## 3. Memory(메모리) 관련 sysctl

### `vm.swappiness = 10`

**무엇?**: 커널이 RAM 페이지를 스왑 디스크로 내보내는 **적극성**을 조절합니다.

```
값 범위: 0 ~ 100
  0:  스왑 거의 안 함 (메모리 부족 시에만)
  10: 스왑 최소화 ← 이더리움 노드 권장
  60: 기본값 (적극적으로 스왑)
  100: 매우 적극적으로 스왑
```

**이더리움 노드에서 왜 10?**:

- 실행 클라이언트(Geth, Erigon)은 **대규모 인메모리 캐시** 사용 (RocksDB block cache 등)
- 이 캐시가 스왑에 밀려나면 → **디스크에서 다시 읽기 → 블록 처리 속도 급감**
- 합의 클라이언트도 beacon state를 메모리에 캐시

```
swappiness=60 (기본값):
  RAM: [커널][Geth 캐시][ ░░░░ 비용 ]
  SWAP: [Geth 캐시 일부가 여기로 밀림!] → 느려짐!

swappiness=10:
  RAM: [커널][Geth 캐시][합의 클라이언트]  ← RAM에 유지
  SWAP: [ 거의 비어있음 ]
```

**주의**: 0으로 설정하면 메모리가 진짜 부족할 때도 스왑을 안 해서 OOM Killer가 프로세스를 죽일 수 있음

### `vm.max_map_count = 1048576`

**무엇?**: 하나의 프로세스가 가질 수 있는 **메모리 맵(mmap) 영역의 최대 개수**

**mmap이란?**:

```
일반 파일 읽기:
  프로세스 → read() 시스템콜 → 커널이 디스크에서 읽기 → 커널 버퍼 → 유저 버퍼로 복사

mmap 파일 읽기:
  프로세스 → mmap() → 파일을 프로세스의 가상 메모리에 직접 매핑
  ↓
  파일을 "메모리에 있는 것처럼" 직접 접근 가능 → 매우 빠름 (복사 없음!)
```

**이더리움 노드에서 왜 1048576?**:

- **RocksDB** (Geth, Erigon): SST 파일을 mmap으로 열어서 읽음
- **MDBX** (Erigon): 전체 DB를 mmap으로 매핑
- 이더리움 상태 DB는 수만 개의 파일로 구성 → **기본값(65536)으론 부족**

```
기본값 65536:
  Erigon이 DB 파일 매핑 중... → 65536개 도달 →
  🔴 "mmap failed: Too many open files" → 노드 크래시!

1048576 설정 후:
  Erigon이 DB 파일 매핑 중... → 여유롭게 100만 개까지 가능 → ✅ 정상
```

### `vm.min_free_kbytes = 131072` (신규 추가)

**무엇?**: 커널이 **항상 확보해두는 최소 여유 메모리** (KB 단위, 131072 = 128MB)

**왜 필요한가?**:

```
min_free_kbytes가 없거나 너무 낮을 때:

RAM 사용량: [██████████████████████████████ 99.9%]
여유: 거의 0
  → 커널 자체가 메모리 할당 실패
  → 네트워크 패킷 처리 불가 (skb 할당 실패)
  → OOM 상황에서 OOM Killer 자체도 실행 불가
  → 🔴 시스템 응답 불가 (hang)

min_free_kbytes = 131072 설정 시:

RAM 사용량: [████████████████████████████░░ 96%]
여유: 128MB (커널 전용 예약)
  → 메모리 압박 상황에서도 커널은 정상 동작
  → OOM Killer가 정상적으로 프로세스 정리
  → 네트워크 유지 → SSH 접속 가능
```

**이더리움 노드에서 왜?**:

- 실행 클라이언트는 메모리를 **거의 한계까지** 사용 (캐시가 크니까)
- 장기 운영 시 메모리 파편화로 여유 공간이 줄어듦
- 128MB 여유를 확보해두면 **장기 가동 시 segfault 방지** + 긴급 시 SSH 접속 보장

---

## 4. Network(네트워크) 관련 sysctl

### `net.core.somaxconn = 65535`

**무엇?**: TCP 소켓의 **listen backlog 최대 크기** (연결 대기 큐)

```
이더리움 P2P 연결 과정:

  다른 피어 → [SYN] → 서버의 TCP 백로그 큐 → accept() → 연결 완료
                            ↑
                     somaxconn = 이 큐의 최대 크기

  기본값 4096:
    동시에 4096개 이상의 연결 요청이 오면 → 나머지는 DROP

  65535:
    동시에 65535개까지 대기 가능 → 피어 연결 안정성 향상
```

**이더리움 노드에서 왜?**:

- 실행 클라이언트: **수백 개의 P2P 피어** 연결
- 합의 클라이언트: 다수의 beacon 피어 연결
- 피어가 동시에 재접속하는 상황 (네트워크 장애 복구 후) → 큰 백로그 필요

### `net.ipv4.tcp_max_syn_backlog = 8192`

**무엇?**: **SYN_RECEIVED 상태**의 연결 큐 크기 (아직 3-Way Handshake 완료 전)

```
TCP 3-Way Handshake:
  피어 → [SYN]      → 서버  (여기서 SYN 백로그에 저장)
  피어 ← [SYN+ACK]  ← 서버
  피어 → [ACK]      → 서버  (핸드셰이크 완료 → somaxconn 큐로 이동)
```

**이더리움 노드에서 왜?**:

- P2P 네트워크에서 많은 피어가 **동시에 연결 시도** 가능
- SYN 백로그가 작으면 정상적인 피어 연결도 거부됨
- 8192로 설정하면 충분한 핸드셰이크 버퍼 확보

### `net.core.netdev_max_backlog = 5000`

**무엇?**: 네트워크 인터페이스에서 **커널이 처리하기 전에 쌓아둘 수 있는 패킷 수**

```
네트워크 카드 → [패킷 큐 (netdev_max_backlog)] → 커널 네트워크 스택 → 애플리케이션
                        ↑
                 이 큐가 꽉 차면 패킷 DROP!
```

**이더리움 노드에서 왜?**:

- 블록 전파(gossip) 시 **순간적으로 대량의 패킷** 수신
- 새 블록이 전파되면 모든 피어가 동시에 보내옴
- 기본값(1000)이면 큐 오버플로우 → 패킷 유실 → 블록 수신 지연

---

## 5. File Descriptor(파일 디스크립터) 제한

### `nofile = 1048576`

```
/etc/security/limits.conf:
* soft nofile 1048576
* hard nofile 1048576
```

**파일 디스크립터란?**:
Linux에서 **열린 파일, 소켓, 파이프 등을 가리키는 정수형 핸들**입니다.

```
프로세스가 사용하는 FD들:
  FD 0: stdin
  FD 1: stdout
  FD 2: stderr
  FD 3: /data/geth/chaindata/000001.sst   ← DB 파일
  FD 4: TCP 소켓 (피어 1과 연결)           ← 네트워크
  FD 5: TCP 소켓 (피어 2와 연결)
  ...
  FD 100000+: DB 파일 + 수백 피어 연결
```

**이더리움 노드에서 왜 1048576?**:

- RocksDB: 수만 개의 SST 파일을 열어둠
- P2P: 수백 개의 TCP 소켓
- 기본값(1024)이면 → "Too many open files" → **노드 크래시**

---

## 6. 기타

### Kernel Package Hold

```yaml
- name: Hold all installed kernel metapackages
  ansible.builtin.dpkg_selections:
    name: '{{ item }}'
    selection: hold
```

**무엇?**: `apt upgrade` 시 **커널 패키지가 자동 업데이트되지 않도록 고정(hold)**

**이더리움 노드에서 왜?**:

- 커널 업데이트 → 재부팅 필요 → **노드 다운타임**
- 새 커널에 버그가 있으면 → 부팅 실패 가능
- **계획된 점검 시간에만 직접 커널 업데이트**하기 위해 고정

### SSD TRIM (fstrim.timer)

**무엇?**: SSD에게 "이 블록은 더 이상 안 쓰니 내부적으로 정리해"라고 알려주는 작업

**왜?**:

- SSD는 덮어쓰기가 안 되고 **지우기 → 쓰기** 순서로 동작
- TRIM 없이 오래 쓰면 → SSD가 모든 블록을 "사용 중"으로 인식 → **쓰기 성능 급감**
- 주기적 TRIM → SSD 성능과 수명 유지

---

## 7. 전체 파라미터 한눈에 보기

| 카테고리    | 파라미터                              | 값      | 목적                      |
| ----------- | ------------------------------------- | ------- | ------------------------- |
| **GRUB**    | `mitigations=off`                     | off     | CPU 성능 5~30% 향상       |
| **GRUB**    | `nvme_core.default_ps_max_latency_us` | 0       | NVMe 절전 비활성화        |
| **GRUB**    | `pcie_aspm`                           | off     | PCIe 절전 비활성화        |
| **Storage** | `vm.dirty_background_ratio`           | 5       | 백그라운드 flush 임계치   |
| **Storage** | `vm.dirty_ratio`                      | 15      | 강제 flush 임계치         |
| **Memory**  | `vm.swappiness`                       | 10      | 스왑 최소화               |
| **Memory**  | `vm.max_map_count`                    | 1048576 | mmap 영역 제한 확장       |
| **Memory**  | `vm.min_free_kbytes`                  | 131072  | 최소 여유 128MB 확보      |
| **Network** | `net.core.somaxconn`                  | 65535   | TCP 연결 대기 큐 확장     |
| **Network** | `net.ipv4.tcp_max_syn_backlog`        | 8192    | SYN 큐 확장               |
| **Network** | `net.core.netdev_max_backlog`         | 5000    | 패킷 수신 큐 확장         |
| **FD**      | `nofile`                              | 1048576 | 파일 디스크립터 제한 확장 |
| **Kernel**  | `dpkg hold`                           | -       | 커널 자동 업데이트 방지   |
| **SSD**     | `fstrim.timer`                        | enabled | SSD TRIM 주기적 실행      |
