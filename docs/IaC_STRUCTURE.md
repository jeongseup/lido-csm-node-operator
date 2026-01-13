# IaC 구조 설계: 하이브리드 클라우드를 위한 Terraform & Ansible

이 문서는 여러 클라우드 제공자(예: GCP, Hetzner)와 온프레미스(예: Home Server) 리소스를 동시에 관리해야 하는 하이브리드 환경에서 Terraform과 Ansible을 사용한 Infrastructure as Code (IaC) 저장소 구조를 제안합니다.

## 1. 핵심 전략: 관심사의 분리 (Decoupling)

우리의 목표는 서로 다른 환경의 리소스를 일관된 방식으로 관리하는 것입니다.

- Terraform의 역할: 프로비저닝 및 태깅 (Provisioning & Tagging)

  - GCP, Hetzner 등 각 클라우드에 VM, 네트워크 등의 리소스를 생성합니다.
  - 생성된 모든 리소스에 **일관된 라벨(Lables) 또는 태그(Tags)**를 붙이는 것까지가 Terraform의 책임입니다. (예: env: prod, role: validator)

- Ansible의 역할: 설정 및 통합 (Configuration & Unification)
  - Ansible은 리소스가 어디서 생성되었는지(Terraform, 수동 등)에 의존하지 않습니다.
  - 대신, 여러 소스(클라우드 API, 정적 파일)로부터 호스트 목록을 취합하는 **동적 인벤토리(Dynamic Inventory)**를 사용합니다.
  - SSH 접속이 가능한 모든 서버를 대상으로 일관된 설정을 적용합니다.

## 2. 권장 디렉터리 구조

이 구조는 "환경 격리"와 "하이브리드 인벤토리"에 중점을 둡니다.

```md
/server-setup/
├── terraform/
│ ├── environments/
│ │ ├── prod/
│ │ │ ├── main.tf # (GCP, Hetzner 리소스를 "함께" 정의)
│ │ │ ├── providers.tf # (google, hcloud 프로바이더 설정)
│ │ │ ├── terraform.tfvars # (prod 환경 전용 변수)
│ │ │ └── backend.tf # (Prod 환경 전체의 state는 하나로 관리)
│ │ └── dev/
│ │ └── ... (dev 환경도 동일)
│ │
│ └── modules/
│ ├── gcp_instance/ # (GCP VM 생성 모듈)
│ └── hetzner_instance/ # (Hetzner VM 생성 모듈)
│
└── ansible/
├── playbooks/
│ ├── setup_validators.yml
│ └── update_system.yml
│
├── roles/
│ ├── common/ # (기본 시스템 설정)
│ ├── cosmos_node/ # (코스모스 노드 설정)
│ └── prometheus_exporter/
│
├── inventory/ # <-- "디렉터리" 자체가 인벤토리
│ ├── 01-gcp-dynamic.yml # (GCP 동적 인벤토리 "플러그인" 설정)
│ ├── 02-hetzner-dynamic.yml # (Hetzner 동적 인벤토리 "플러그인" 설정)
│ └── 03-static-home.yml # (Home-server용 "정적" 인벤토리)
│
├── group_vars/
│ ├── all.yml # (모든 호스트 공통 변수)
│ ├── role_validator.yml # (role=validator 태그를 가진 모든 호스트용 변수)
│ └── home_servers.yml # (정적 호스트 그룹용 변수)
│
└── ansible.cfg # (ansible.cfg에서 'inventory = ./inventory/' 설정)
```

## 3. 세부 설명: The "Why"

- 3.1. Terraform: 멀티 프로바이더와 태깅

Terraform은 environments/prod 디렉터리 내에서 여러 provider를 동시에 선언할 수 있습니다.

terraform/environments/prod/providers.tf 예시:

```
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.4"
    }
  }

  # Prod 환경 전체의 상태(State)는 S3 등 원격지에 하나로 관리
  backend "s3" {
    bucket = "my-hybrid-tf-state"
    key    = "prod/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

provider "google" {
  project = "my-gcp-project"
  region  = "asia-northeast3"
}

provider "hcloud" {
  # (HETZNER_TOKEN 환경 변수에서 토큰을 읽어옴)
}
```

terraform/environments/prod/main.tf 예시:

```
# 1. GCP에 밸리데이터 VM 생성
module "gcp_validator" {
  source = "../../modules/gcp_instance"
  name   = "prod-validator-gcp-01"
  labels = {
    env  = "prod"
    role = "validator"  # <-- 핵심: 일관된 라벨
  }
}

# 2. Hetzner에 센트리 VM 생성
module "hetzner_sentry" {
  source = "../../modules/hetzner_instance"
  name   = "prod-sentry-hetzner-01"
  labels = {
    env  = "prod"
    role = "sentry"     # <-- 핵심: 일관된 라벨
  }
}
```

- 3.2. Ansible: 하이브리드 인벤토리 (핵심)

이 구조의 핵심은 Ansible이 Terraform의 state 파일을 직접 읽는 것이 아니라, 각 클라우드 API와 정적 파일을 동시에 읽어와 인벤토리를 통합하는 것입니다.

ansible.cfg 파일에 inventory = ./inventory/라고 설정하면, Ansible은 해당 디렉터리의 모든 \*.yml 파일을 읽어 인벤토리를 구성합니다.

ansible/inventory/01-gcp-dynamic.yml (GCP 플러그인)

```
# GCP API에 직접 쿼리하여 'prod' 라벨이 붙은 VM만 가져옵니다.
plugin: gcp_compute
projects:
  - "my-gcp-project"
auth_kind: serviceaccount # (GCP_SERVICE_ACCOUNT_FILE 환경 변수 필요)
filters:
  - "labels.env = prod"
# 'labels.role' 값을 기반으로 'role_validator', 'role_sentry' 같은 그룹을 자동 생성
groups:
  role: labels.role
```

ansible/inventory/02-hetzner-dynamic.yml (Hetzner 플러그인)

```
# Hetzner API에 직접 쿼리합니다.
plugin: hetzner.hcloud.hcloud
# 'labels.role' 값을 기반으로 그룹을 자동 생성
groups:
  role: labels.role
```

ansible/inventory/03-static-home.yml (정적 인벤토리)

```
# API가 없는 Home Server는 수동으로 등록합니다.
all:
  children:
    home_servers: # 'home_servers' 라는 정적 그룹 생성
      hosts:
        home-server-01:
          ansible_host: 192.168.0.100 # (내부 IP 또는 도메인)
          ansible_user: my_user
```

## 4. 실행: 어떻게 동작하는가?

이 구조가 완성되면, 시니어 엔지니어로서 우리는 다음과 같은 워크플로우를 갖게 됩니다.

1. 인프라 변경 (Terraform):

- cd terraform/environments/prod
- terraform apply
- Terraform이 GCP와 Hetzner에 VM을 생성하고 role: validator 라벨을 붙입니다.

2. 설정 적용 (Ansible):

- cd ansible/
- ansible-playbook -i inventory/ playbooks/setup_validators.yml

이때 Ansible 내부에서 일어나는 일:

1. Ansible이 inventory/ 디렉터리를 읽습니다.

2. 01-gcp-dynamic.yml이 GCP API를 호출해 role=validator 라벨이 붙은 VM을 찾아 role_validator 그룹에 추가합니다.

3. 02-hetzner-dynamic.yml이 Hetzner API를 호출해 role=validator 라벨이 붙은 VM을 찾아 role_validator 그룹에 또 추가합니다.

4. 03-static-home.yml을 읽어 home_servers 그룹을 인지합니다.

5. playbooks/setup_validators.yml이 실행됩니다.

ansible/playbooks/setup_validators.yml 예시:

```
- name: Setup All Validator Nodes (GCP and Hetzner)
  # 이 그룹은 GCP와 Hetzner의 VM이 자동으로 합쳐진 결과입니다.
  hosts: role_validator
  become: yes
  roles:
    - common
    - cosmos_node

- name: Setup Home Monitoring Server
  hosts: home_servers # 이 그룹은 static.yml에서 정의했습니다.
  become: yes
  roles:
    - common
    # - prometheus_server # (예시)
```

이 구조는 Terraform과 Ansible의 역할을 명확히 분리(Decoupling)하고, 어떤 클라우드나 온프레미스 환경이 추가되더라도 inventory/ 디렉터리에 플러그인 설정 파일 하나만 추가하면 되므로 최고의 확장성을 제공합니다.
