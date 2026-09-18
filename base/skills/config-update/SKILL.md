---
name: config-update
description: "전역 claude-config 설정(CLAUDE.md·hooks·skills·rules·settings.json)이 최신인지 확인하고, 낡았으면 원본 저장소의 install.sh+check-install.sh로 갱신한다. 사용자가 '설정 업데이트해줘', 'claude-config 갱신해줘', '클로드 설정 최신인지 확인해줘'라고 하면 사용한다. 어느 저장소에 있든 발동하며 원본 경로는 ~/.claude/.claude-config-version에서 읽는다. 원본 저장소 자체가 없는 신규 기기 세팅은 tools/bootstrap.sh(사람이 직접 curl로 실행)가 담당하므로 이 스킬은 clone을 새로 하지 않는다."
allowed-tools: Bash(cat ~/.claude/.claude-config-version) Bash(git -C* describe*) Bash(bash */tools/install.sh) Bash(bash */tools/check-install.sh)
---

# config-update

전역 설정이 원본 저장소의 `base/`와 같은지 확인하고 필요하면 갱신한다.

## 0. 시작 전 확인 (필수)

- `~/.claude/.claude-config-version`을 읽는다 — 1행: 원본 저장소 경로(SRC_PATH), 2행: 설치된 버전.
- 파일이 없으면 아직 `tools/install.sh`를 한 번도 실행한 적이 없는 것이다. **경로를 추측하지 말고** 원본 저장소 위치를 사용자에게 물어본다.
- 같은 세션에 다른 SessionStart 알림(저장소 표준 제안, 대량 조회 누적 등)이 함께 떠 있어도, 이 체크리스트를 먼저 끝내고 나서 그것들에 답한다.

## 1. 절차

```text
설정 갱신
- [ ] 1. .claude-config-version 읽기 (SRC_PATH, 설치된 버전)
- [ ] 2. git -C "<SRC_PATH>" describe --tags --always 로 최신 버전 확인
- [ ] 3. 같으면 "이미 최신입니다"라고만 답하고 끝
- [ ] 4. 다르면 bash "<SRC_PATH>/tools/install.sh" 실행
- [ ] 5. bash "<SRC_PATH>/tools/check-install.sh" 실행
- [ ] 6. 결과 보고 — 이전 버전 → 새 버전, check-install.sh 마지막 판정 줄 그대로 전달. 버전이 바뀐 경우(3번에서 "이미 최신"이 아니었던 경우)엔 "CLAUDE.md·스킬은 보통 이 세션의 다음 응답부터 자동 반영됩니다. 훅 등록·권한(settings.json 구조)이 바뀐 경우엔 확실히 하려면 새 세션을 시작하세요"를 덧붙인다.
```

CLAUDE.md는 컴팩션·세션 재시작 시 다시 로드되고, 스킬은 호출할 때마다 디스크에서 새로 읽는다([공식 문서](https://code.claude.com/docs/en/context-window), 같은 세션 안에서 실험으로도 확인됨). 다만 훅 "등록"(어떤 이벤트에 어떤 훅을 실행할지, 권한 목록 — settings.json 구조 자체)이 바뀐 경우는 즉시 반영되는지 검증되지 않았으므로, 그럴 때만 새 세션을 권장한다([Issue #110](https://github.com/yanos0218/AI/issues/110)/[#111](https://github.com/yanos0218/AI/issues/111)).

## 하지 않는 것

- SRC_PATH가 없으면 새로 clone하지 않는다 — 그건 `tools/bootstrap.sh`(사람이 직접 실행)의 역할이다.
- `base/` 내용 자체를 이 스킬로 고치지 않는다 — 순수 배포 갱신 도구다.
- `check-install.sh`가 "어긋난 항목이 있다"고 보고해도 임의로 파일을 손대지 않고 그대로 사용자에게 전달한다.
