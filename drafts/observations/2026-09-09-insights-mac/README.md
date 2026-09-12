# `/insights` Mac mini 첫 실행 (2026-09-09)

- 실행: `claude -p "/insights" --model sonnet` (VS Code 확장 내장 바이너리 2.1.266). 비대화형에서도 동작, 출력은 `~/.claude/usage-data/report.html` → [report.html](report.html)에 복사.
- 범위: **3세션 23메시지**(2026-09-07~09, OpenClaw 1 + 이 저장소 2). 데이터가 얕아 결론은 참고용. 다음 실행은 10월 월 점검.
- 도구 사용: Bash 253 · Read 97 · Edit 96 · Write 7. 메시지당 도구 호출 약 20회. 응답 시간 중앙값 3분.

## 리포트가 짚은 것

| 구분 | 내용 | 이미 있는 장치 |
| --- | --- | --- |
| 잘 됨 | "다음 뭐 해?"로 시작해 실행까지 위임, 커밋·CI·문서까지 마무리 | HANDOFF "다음 할 일", 세션 끝 갱신 규칙 |
| 마찰 | 릴리즈에 GitHub 토큰이 없어 막힘 → **토큰을 채팅에 붙여넣음**(OpenClaw 세션, Claude가 사후 재발급 안내) | 전역 §7 "노출됐으면 재발급"만 있고 **사전 점검·붙여넣기 금지는 없음** |
| 마찰 | 자동 모드 분류기가 파일 복사 명령을 막아 Read/Write로 우회 | [#1](https://github.com/yanos0218/AI/issues/1), C-11 |
| 마찰 | VS Code 확장 7/13 누락을 늦게 발견(설치 스크립트가 별도) | `install.md`에 순서 있음. `check-install.sh`는 확장을 안 봄 |
| 마찰 | C-10·C-25가 열린 채 세션 종료 | 보드·HANDOFF가 이미 추적. 리포트의 NOTES.md 제안은 불필요 |

## 제안된 CLAUDE.md 추가 4개 → 판정은 [Issue #59](https://github.com/yanos0218/AI/issues/59)
