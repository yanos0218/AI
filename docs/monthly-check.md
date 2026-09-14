# 월 점검 — 매달 첫 세션에서 (C-21)

세션 시작 시 HANDOFF의 "마지막 점검일"이 30일 넘었으면 Claude가 **제안만** 한다. 실행은 사용자가 "점검하자"라고 할 때. 아래를 답변에 복사해 진행 상황을 표시한다.

```text
월 점검 YYYY-MM
- [ ] 1. 도구 버전 — `claude --version`, `claude doctor`. 업데이트가 있으면 `research` 라벨 이슈 중 "다시 볼 시점" 지난 것 재조사(`gh issue list --label research --state all`)
- [ ] 2. 설치본 대조 — `bash tools/check-install.sh`. DIFF는 base 반영 또는 재설치, 프로젝트 settings.local.json에 2개 저장소 이상 반복된 권한은 base/settings.example.json 승격 후보
- [ ] 3. 설정 변경 이력 — ~/.claude/config-changelog.md 를 drafts/observations/memory-<기기>/ 로 복사하고 원본은 비움
- [ ] 4. auto memory 수집 — ~/.claude/projects/*/memory/*.md 를 drafts/observations/memory-<기기>/ 로 복사. 저장소 무관 성향은 Issue로 후보 등록(`task` 라벨, 2026-09-12부터 drafts/claude-md/ 대신)
- [ ] 5. 관찰 기록 검토 — drafts/observations/*.md 에서 두 번 이상 반복된 것만 전역 지침 후보로 Issue 등록
- [ ] 6. 스킬 재시험 — base/skills/* 각 3시나리오를 tools/test-skill.sh 로 (Sonnet). 실패하면 초안으로 내려 수정
- [ ] 7. /insights — 대화형 세션에서 실행, 제안 중 반복되는 것만 후보
- [ ] 8. 사용량 — 상태줄 $ 누계, claude.ai 사용량 페이지, GitHub Settings → Billing → Actions 분
- [ ] 9. 이슈 정리 — 열린 Issue(`gh issue list --state open`) 우선순위 재검토. PROGRESS §0 표가 실제 배포 상태와 맞는지 확인
  - 파생 관계인데 sub-issue로 안 묶인 것 없는지도 함께: 본문에서 다른 이슈 번호(`#N`)를 파생 의미로 언급한 것 찾아 대조(`docs/issue-format.md` "이슈 수명 관리")
- [ ] 10. 검토표 갱신 — docs/review-vs-official.md에서 상태가 바뀐 행 갱신. 새로 발견한 문제·제안은 Issue로(`task`/`bug` 라벨, 2026-09-12부터 파일 대신). 새 기능은 조사 규칙대로 조사해 `research` 라벨 이슈로
- [ ] 11. 릴리즈 판단 — [Unreleased]가 비어 있지 않고 다른 기기 설치가 예정돼 있으면 컷(versioning.md 컷 시점)
- [ ] 12. HANDOFF "마지막 점검일" 갱신
```

관련 항목: [Issue #42](https://github.com/yanos0218/AI/issues/42) 정의, [Issue #43](https://github.com/yanos0218/AI/issues/43) 대조·이력, [Issue #9](https://github.com/yanos0218/AI/issues/9) 메모리 수집, [Issue #16](https://github.com/yanos0218/AI/issues/16) insights, [Issue #33](https://github.com/yanos0218/AI/issues/33)·[Issue #10](https://github.com/yanos0218/AI/issues/10) 사용량, [Issue #49](https://github.com/yanos0218/AI/issues/49) 보드 크기.
