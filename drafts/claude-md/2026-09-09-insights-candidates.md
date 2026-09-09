# `/insights` 제안 → 전역 지침·스킬 후보 (2026-09-09, Mac 3세션 기준)

원자료 [drafts/observations/2026-09-09-insights-mac/](../observations/2026-09-09-insights-mac/README.md). 채택은 사용자 확인 후 `drafts/claude-md/CLAUDE.md` diff로.

| 제안 | 판정 | 이유·갈 곳 |
| --- | --- | --- |
| Release: 릴리즈 전 `gh auth status` 확인, 없으면 멈추고 `gh auth login` 안내, **토큰을 채팅에 붙여넣으라고 하지 않는다** | **채택 후보** | 실제 사고(2026-09-09 OpenClaw). 전역 §7에 한 줄 + dev-release `release-steps.md` 0단계. → [C-53](../../docs/PROGRESS.md#c-53) |
| Task Workflow: "다음 뭐 해?"엔 순위 목록 제시 후 선택 대기, 커밋 메시지에 항목 ID | 기각 | 이미 그렇게 하고 있음(HANDOFF "다음 할 일", 커밋 본문에 C-NN). 지침 추가 불필요 |
| Verification: 설치 완료 보고 전 검증 명령 재실행·출력 제시, 설치 스크립트 전부 열거 | 부분 채택 | 전역 §4가 이미 요구. 빠진 건 `check-install.sh`가 VS Code 확장을 안 보는 것 → C-53에 묶어 도구 쪽에서 해결 |
| Environment: 변경은 Mac·Windows 양쪽 검증 또는 "보류" 표시 | 기각 | PROGRESS §0 배포 열이 그 역할. 지침보다 표가 정확 |
| PostToolUse 훅으로 편집 직후 shellcheck | 보류 | CI가 이미 함. Windows Git Bash에 shellcheck 없음. 훅이 늘면 소음 |
| `/ship` 스킬(커밋→push→CI→릴리즈) | 기각 | dev-release가 이미 그 역할. push는 확인 항목이라 한 명령으로 묶지 않음 |
| 자율 루프·병렬 worktree·verify.sh 하네스 | 보류 | HANDOFF 결정: 병렬 작업은 습관 항목. 3세션 데이터로 판단할 근거 아님 |
