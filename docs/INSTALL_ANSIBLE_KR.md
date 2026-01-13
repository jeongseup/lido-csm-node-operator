# macOS에서 Ansible 설치하기 (pipx 방식)

## 개요

macOS에서 Ansible을 설치할 때 `brew install ansible`을 사용하는 것이 일반적이지만, **pipx**를 사용하면 다음과 같은 장점이 있습니다:

- **격리된 가상환경**: 각 패키지가 독립된 가상환경에 설치되어 의존성 충돌 방지
- **Python 버전 관리**: 특정 Python 버전으로 설치 가능
- **유연한 플러그인 관리**: `ansible-lint`, `requests` 등의 추가 패키지를 쉽게 주입(inject) 가능
- **Homebrew 버전 충돌 해결**: `ansible-lint`가 `community.general` 컬렉션을 찾지 못하는 문제 등을 방지

---

## 사전 요구사항

- macOS (Apple Silicon 또는 Intel)
- Homebrew 설치 완료 ([brew.sh](https://brew.sh))
- Python 3.12+ 설치 (`brew install python@3.12`)

---

## 설치 과정

### 1. 기존 Homebrew Ansible 제거 (선택사항)

기존에 Homebrew로 설치한 Ansible이 있다면 충돌을 방지하기 위해 제거합니다:

```bash
brew uninstall ansible
brew uninstall ansible-lint
```

### 2. pipx 설치 및 환경 설정

```bash
# pipx 설치
brew install pipx

# PATH에 pipx 바이너리 경로 추가
pipx ensurepath
```

> [!NOTE] > `pipx ensurepath` 실행 후 터미널을 재시작하거나 `source ~/.zshrc`를 실행해야 PATH가 적용됩니다.

### 3. Ansible 설치

```bash
# Python 3.12 환경에서 Ansible과 의존성 함께 설치
pipx install --include-deps --python 3.12 ansible
```

### 4. 추가 패키지 주입

Ansible 환경에 필요한 추가 패키지들을 주입합니다:

```bash
# ansible-lint (Ansible 플레이북 린터)
pipx inject ansible ansible-lint --include-apps

# requests (HTTP 요청 모듈, URI 모듈 등에서 사용)
pipx inject ansible requests --include-apps

# python-dateutil (날짜/시간 유틸리티)
pipx inject ansible python-dateutil --include-apps
```

---

## 설치 확인

```bash
# Ansible 버전 확인
ansible --version

# ansible-lint 버전 확인
ansible-lint --version

# 설치된 컬렉션 확인
ansible-galaxy collection list
```

---

## 참고 자료

- [Ansible Lint가 Homebrew 설치된 community.general을 찾지 못하는 문제](https://serverfault.com/questions/1158998/ansible-lint-not-finding-community-general-included-with-homebrew-installed-ansi)
- [Ansible --ask-become-pass 변수 사용 방법](https://serverfault.com/questions/1061344/using-ansible-ask-become-pass-in-a-variable)
- [pipx 공식 문서](https://pipx.pypa.io/stable/)
- [Ansible 공식 설치 가이드](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
