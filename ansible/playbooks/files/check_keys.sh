cat check_keys.sh
#!/bin/bash

# 경로 설정 (본인의 환경에 맞게 수정)
KEY_DIR="$HOME/workspace/validator_keys"
VC_DEFINITION_FILE="/data/ethereum/vc/validators/validator_definitions.yml"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "---------------------------------------------------------------"
echo "Checking Validator Keys vs Lighthouse Definition"
echo "Definition: $VC_DEFINITION_FILE"
echo "---------------------------------------------------------------"

# 1. 정의 파일 존재 여부 확인
if [ ! -f "$VC_DEFINITION_FILE" ]; then
    echo -e "${RED}[ERROR]${NC} Definition file not found at $VC_DEFINITION_FILE"
    exit 1
fi

# 2. 키 디렉토리 내의 json 파일 순회
for keyfile in "$KEY_DIR"/keystore-*.json; do
    # 파일이 없는 경우 대응
    [ -e "$keyfile" ] || continue

    # jq로 pubkey 추출 (접두어 0x가 없는 경우가 많으므로 처리)
    PUBKEY=$(jq -r '.pubkey' "$keyfile")

    # Lighthouse yml은 보통 0x로 시작하므로 접두어 정리
    if [[ $PUBKEY != 0x* ]]; then
        SEARCH_KEY="0x$PUBKEY"
    else
        SEARCH_KEY="$PUBKEY"
    fi

    # 정의 파일에서 해당 펍키 검색
    if grep -q "$SEARCH_KEY" "$VC_DEFINITION_FILE"; then
        echo -e "[${GREEN}  OK  ${NC}] $(basename "$keyfile") -> $SEARCH_KEY"
    else
        echo -e "[${RED}MISSING${NC}] $(basename "$keyfile") -> $SEARCH_KEY"
    fi
done

echo "---------------------------------------------------------------"
echo "Check Completed."