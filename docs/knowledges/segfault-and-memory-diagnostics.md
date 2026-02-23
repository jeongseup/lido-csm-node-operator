# Segfault와 메모리 진단 — 주니어 개발자를 위한 기초부터 실전까지

> **작성일**: 2026-02-13
> **목적**: dmesg에서 segfault를 발견했을 때, 하드웨어/소프트웨어 양쪽에서 원인을 진단하고 해결하는 방법을 이해하기 위한 기초 지식 문서

---

## 1. Segfault (Segmentation Fault)란?

### 정의

**Segmentation Fault**는 프로그램이 **접근 권한이 없는 메모리 영역**에 읽기/쓰기를 시도했을 때 운영체제(커널)가 해당 프로세스를 강제 종료시키면서 발생하는 에러입니다.

### 왜 발생하는가?

컴퓨터의 메모리는 **가상 메모리(Virtual Memory)** 시스템으로 관리됩니다.
각 프로세스는 자기만의 **가상 주소 공간**을 가지며, 커널의 **MMU(Memory Management Unit)**가 가상 주소를 물리 주소로 변환합니다.

```
프로세스 A의 가상 주소 공간:
┌────────────────────────┐ 0xFFFFFFFF (높은 주소)
│  커널 영역 (접근 불가)    │ ← 여기 접근하면 segfault
├────────────────────────┤
│  스택 (Stack)            │ ← 지역변수, 함수 호출 정보
│         ↓               │
│   (빈 공간)               │
│         ↑               │
│  힙 (Heap)              │ ← malloc/new로 할당된 메모리
├────────────────────────┤
│  데이터 (Data)           │ ← 전역변수, static 변수
├────────────────────────┤
│  텍스트 (Code)           │ ← 실행할 기계어 코드
└────────────────────────┘ 0x00000000 (낮은 주소)
```

segfault가 발생하는 대표적 상황:

| 원인                | 예시                                          | 레벨              |
| ------------------- | --------------------------------------------- | ----------------- |
| NULL 포인터 역참조  | `int *p = NULL; *p = 5;`                      | 소프트웨어 버그   |
| 해제된 메모리 접근  | `free(ptr); ptr->value = 1;` (Use-After-Free) | 소프트웨어 버그   |
| 버퍼 오버플로우     | 배열 범위를 넘어서 쓰기                       | 소프트웨어 버그   |
| 스택 오버플로우     | 무한 재귀 호출                                | 소프트웨어 버그   |
| **RAM 물리적 불량** | 정상 코드인데 비트가 뒤집힘                   | **하드웨어 문제** |

---

## 2. dmesg란?

### 정의

**dmesg (diagnostic message)**는 Linux 커널이 출력하는 **커널 링 버퍼(Kernel Ring Buffer)**의 메시지를 보여주는 명령어입니다.

### 커널 링 버퍼란?

커널은 부팅 시점부터 하드웨어 감지, 드라이버 로드, 에러 등의 메시지를 **고정 크기의 원형 버퍼**에 기록합니다.
"링(Ring)"이라 불리는 이유는 버퍼가 가득 차면 **가장 오래된 메시지를 덮어쓰기** 때문입니다.

```
링 버퍼 (원형 구조):
    ┌─── 새 메시지 ←──┐
    │                  │
    ▼                  │
[msg5][msg6][msg7][msg8]  ← 가장 오래된 메시지부터 덮어씀
[msg1][msg2][msg3][msg4]
    ▲
    └─── 오래된 메시지
```

### 주요 사용법

```bash
# 전체 커널 메시지 보기
dmesg

# 사람이 읽을 수 있는 타임스탬프로 보기
dmesg -T

# 에러/경고만 필터링
dmesg --level=err,warn

# segfault 관련만 보기
dmesg -T | grep segfault

# 실시간으로 새 메시지 보기
dmesg -w
```

### segfault 로그 읽는 법

```
[Thu Feb 13 10:30:15 2026] myapp[1234]: segfault at 10 ip 00007f... sp 00007f... error 4 in libc.so
```

| 필드          | 의미                                              |
| ------------- | ------------------------------------------------- |
| `myapp[1234]` | 프로세스 이름과 PID                               |
| `at 10`       | 접근하려던 주소 (0x10 → NULL 근처 = NULL pointer) |
| `ip`          | Instruction Pointer (크래시 난 코드 위치)         |
| `sp`          | Stack Pointer                                     |
| `error 4`     | 에러 코드 (비트 플래그)                           |

**error 코드 비트 해석:**

- bit 0 (값 1): Protection fault (보호 위반)
- bit 1 (값 2): Write (쓰기 시도, 없으면 읽기)
- bit 2 (값 4): User mode (유저 모드에서 발생)

| error 값 | 의미                                        |
| -------- | ------------------------------------------- |
| 4        | 유저 모드에서 **없는 페이지를 읽으려 함**   |
| 6        | 유저 모드에서 **없는 페이지에 쓰려 함**     |
| 5        | 유저 모드에서 **보호된 페이지를 읽으려 함** |
| 7        | 유저 모드에서 **보호된 페이지에 쓰려 함**   |

---

## 3. UEFI vs Legacy BIOS

### 부팅(Boot)이란?

컴퓨터 전원 → OS 실행까지의 과정. 이 과정을 관리하는 **펌웨어(Firmware)**가 BIOS 또는 UEFI입니다.

### Legacy BIOS (Basic Input/Output System)

- 1981년 IBM PC부터 사용된 **구형 부팅 방식**
- 16비트 리얼 모드로 동작
- **MBR(Master Boot Record)** 방식으로 디스크 부팅
- 최대 2TB 디스크, 4개 파티션 제한

```
전원 ON → BIOS → MBR(디스크 첫 512바이트) → 부트로더(GRUB) → OS
```

### UEFI (Unified Extensible Firmware Interface)

- 2005년부터 보급된 **현대 부팅 방식**
- 32/64비트 모드로 동작
- **GPT(GUID Partition Table)** 방식 지원
- 2TB 이상 디스크, 128개 파티션 지원
- **EFI System Partition (ESP)** 에 `.efi` 바이너리로 부팅

```
전원 ON → UEFI → ESP 파티션의 .efi 파일 → 부트로더(GRUB) → OS
```

### 확인 방법

```bash
# Linux에서 확인
[ -d /sys/firmware/efi ] && echo "UEFI" || echo "Legacy BIOS"

# EFI 시스템 파티션 확인
ls /boot/efi/EFI/
```

### memtest86+에서 왜 중요한가?

| 부팅 모드   | memtest86+ 바이너리 | 비고                      |
| ----------- | ------------------- | ------------------------- |
| Legacy BIOS | `memtest86+.bin`    | 항상 작동                 |
| UEFI        | `memtest86+x64.efi` | v6+ 필요, 구버전은 미지원 |

---

## 4. GRUB (GRand Unified Bootloader)

### 정의

Linux에서 가장 널리 사용되는 **부트로더**. 커널을 메모리에 로드하고 실행하는 역할을 합니다.

### 부팅 과정에서의 위치

```
BIOS/UEFI → GRUB → Linux 커널 → systemd → 서비스들
                ↑
            여기서 memtest86+를 선택할 수 있음
```

### 주요 파일

| 파일                  | 역할                                    |
| --------------------- | --------------------------------------- |
| `/etc/default/grub`   | 사용자 설정 파일 **(이것을 수정)**      |
| `/boot/grub/grub.cfg` | 자동 생성되는 설정 **(직접 수정 금지)** |
| `/etc/grub.d/`        | 메뉴 항목 생성 스크립트                 |

### 주요 설정값

```bash
# /etc/default/grub

# 메뉴 표시 방식 (hidden: 숨김, menu: 표시)
GRUB_TIMEOUT_STYLE=menu

# 메뉴 대기 시간 (초)
GRUB_TIMEOUT=10

# 커널 파라미터 (memmap 등 여기에 추가)
GRUB_CMDLINE_LINUX="memmap=4M\$0x1cc00000"

# 불량 RAM 영역 지정
GRUB_BADRAM="0x1cebad20,0xfffffffffff00000"
```

```bash
# 설정 변경 후 반드시 실행
sudo update-grub
```

---

## 5. ECC 메모리 (Error-Correcting Code Memory)

### 정의

데이터를 읽을 때 **1비트 에러를 자동으로 감지하고 수정**할 수 있는 RAM.
2비트 에러는 감지만 가능 (수정 불가 → Uncorrectable Error).

### 일반 RAM vs ECC RAM

```
일반 RAM (Non-ECC):
데이터: 10110100 → 비트 플립 → 10110110
                                  ↑ 바뀜! 하지만 아무도 모름 → segfault 또는 조용한 데이터 손상

ECC RAM:
데이터: 10110100 + ECC 비트: 011
→ 비트 플립 → 10110110 + ECC: 011
→ ECC 검증: "어? 3번째 비트가 틀렸다" → 자동 수정!
→ CE (Correctable Error) 카운트 +1 → 로그 기록
```

### 확인 방법

```bash
# ECC RAM인지 확인
sudo dmidecode -t memory | grep "Error Correction Type"
# 출력: "Multi-bit ECC" → ECC RAM

# EDAC으로 에러 카운트 확인
sudo apt install edac-utils
sudo edac-util -s
```

| 에러 타입           | 약자 | 의미                                                |
| ------------------- | ---- | --------------------------------------------------- |
| Correctable Error   | CE   | 1비트 에러, ECC가 자동 수정. 누적되면 RAM 열화 징후 |
| Uncorrectable Error | UE   | 2비트+ 에러, 수정 불가 → **즉시 RAM 교체**          |

---

## 6. 메모리 진단 도구 정리

### 하드웨어 레벨

| 도구         | 설치                     | 언제 쓰나                     | 핵심 명령어                 |
| ------------ | ------------------------ | ----------------------------- | --------------------------- |
| `memtester`  | `apt install memtester`  | OS 위에서 빠른 RAM 검사       | `sudo memtester 1024M 3`    |
| `memtest86+` | `apt install memtest86+` | OS 없이 전체 RAM 정밀 검사    | GRUB에서 선택 (재부팅 필요) |
| `edac-utils` | `apt install edac-utils` | ECC 에러 히스토리 확인        | `sudo edac-util -s`         |
| `mcelog`     | `apt install mcelog`     | CPU/메모리 하드웨어 에러 로그 | `sudo mcelog --client`      |

### 소프트웨어 레벨

| 도구       | 설치                   | 언제 쓰나                            | 핵심 명령어                        |
| ---------- | ---------------------- | ------------------------------------ | ---------------------------------- |
| `valgrind` | `apt install valgrind` | 프로세스 메모리 버그 추적            | `valgrind --leak-check=full ./app` |
| `strace`   | `apt install strace`   | 시스템콜 추적으로 segfault 원인 파악 | `strace -f ./app`                  |
| `debsums`  | `apt install debsums`  | 설치된 라이브러리 무결성 검사        | `sudo debsums -c`                  |

### 모니터링

| 도구      | 설치                  | 언제 쓰나                       | 핵심 명령어         |
| --------- | --------------------- | ------------------------------- | ------------------- |
| `sysstat` | `apt install sysstat` | 메모리 사용량 히스토리          | `sar -r`            |
| `smem`    | `apt install smem`    | 프로세스별 정확한 메모리 사용량 | `smem -r -k -s pss` |
| `htop`    | `apt install htop`    | 실시간 메모리/CPU 모니터링      | `htop`              |

---

## 7. 메모리 관련 커널 파라미터 (sysctl)

### vm.overcommit_memory

| 값       | 의미                                          |
| -------- | --------------------------------------------- |
| 0 (기본) | 커널이 휴리스틱으로 판단 (대부분 허용)        |
| 1        | 항상 허용 (위험, OOM 가능성 높음)             |
| 2        | 물리 RAM + 스왑의 일정 비율까지만 허용 (안전) |

### vm.swappiness

- 범위: 0~100
- **0**: 스왑 거의 안 함 (RAM만 사용)
- **60 (기본)**: 적극적으로 스왑 사용
- **10 (권장)**: 스왑 최소화, 성능 우선

### vm.min_free_kbytes

- 커널이 항상 확보해두는 여유 메모리 (KB 단위)
- 너무 낮으면: 메모리 압박 시 할당 실패 → 크래시
- 너무 높으면: 사용 가능한 메모리 낭비
- **서버 권장: 128MB (131072)**

---

## 8. 실전 체크 플로우

```
segfault 발생!
    │
    ├─ 1. dmesg -T | grep segfault
    │     → 어떤 프로세스? 반복 발생? 같은 주소?
    │
    ├─ 2. 특정 프로세스만 segfault?
    │     ├─ YES → 소프트웨어 버그 가능성 높음
    │     │        → valgrind로 디버깅
    │     │        → 패키지 재설치/업데이트
    │     └─ NO (여러 프로세스에서 랜덤) → 하드웨어 문제 의심
    │
    ├─ 3. edac-util -s → ECC 에러?
    │     ├─ CE 다수 → RAM 열화 중, 교체 예정
    │     └─ UE 발생 → 즉시 RAM 교체
    │
    ├─ 4. memtester 1024M 5 → FAILURE?
    │     ├─ 고정 (매번 같은 주소) → 해당 DIMM 교체
    │     ├─ 간헐적 (가끔만) → 발열/전원/RAM 열화
    │     └─ 없음 → 소프트웨어 문제일 가능성
    │
    └─ 5. 소프트웨어 점검
          ├─ apt upgrade (커널 + glibc)
          ├─ debsums -c (라이브러리 무결성)
          └─ sysctl 메모리 파라미터 안정화
```

---

## 9. 핵심 용어 사전

| 용어             | 설명                                                             |
| ---------------- | ---------------------------------------------------------------- |
| **segfault**     | 프로세스가 허용되지 않은 메모리에 접근해 커널이 강제 종료시킨 것 |
| **dmesg**        | 커널 링 버퍼의 진단 메시지를 보는 명령어                         |
| **커널 링 버퍼** | 커널이 메시지를 기록하는 고정 크기 원형 버퍼                     |
| **MMU**          | CPU에 내장된 가상→물리 주소 변환 하드웨어                        |
| **UEFI**         | 현대 부팅 펌웨어, GPT 디스크/2TB+ 지원                           |
| **Legacy BIOS**  | 구형 부팅 펌웨어, MBR/2TB 제한                                   |
| **GRUB**         | Linux 부트로더, 커널/memtest86+ 선택 메뉴 제공                   |
| **ECC**          | 1비트 에러 자동 수정 메모리, 서버급에서 사용                     |
| **CE/UE**        | Correctable/Uncorrectable Error (ECC 에러 종류)                  |
| **EDAC**         | 커널의 ECC 에러 탐지/보고 서브시스템                             |
| **MCE**          | CPU가 감지한 하드웨어 에러 (Machine Check Exception)             |
| **glibc**        | malloc/free 등 메모리 관리 함수를 제공하는 C 표준 라이브러리     |
| **OOM Killer**   | 메모리 부족 시 커널이 프로세스를 강제 종료하는 메커니즘          |
| **memmap**       | GRUB 커널 파라미터로 특정 메모리 영역을 예약(사용 불가)하는 설정 |
| **IPMI**         | 서버 원격 관리 인터페이스 (OS 독립, 전원/콘솔 원격 제어)         |
| **Stuck-at**     | RAM 셀이 항상 0 또는 1로 고정된 물리적 불량                      |
| **Bit flip**     | RAM 셀의 값이 의도치 않게 뒤집히는 현상                          |
| **PSS**          | Proportional Set Size, 공유 메모리를 비례 배분한 실제 사용량     |
