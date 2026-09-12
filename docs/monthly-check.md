# 월 점검 — 매달 첫 세션에서 (C-21)

세션 시작 시 HANDOFF의 "마지막 점검일"이 30일 넘었으면 Claude가 **제안만** 한다. 실행은 사용자가 "점검하자"라고 할 때. 아래를 답변에 복사해 진행 상황을 표시한다.

```text
월 점검 YYYY-MM
- [ ] 1. 도구 버전 — `claude --version`, `claude doctor`. 업데이트가 있으면 docs/research/ "다시 볼 시점" 지난 항목 재조사
- [ ] 2. 설치본 대조 — `bash tools/check-install.sh`. DIFF는 base 반영 또는 재설치, 프로젝트 settings.local.json에 2개 저장소 이상 반복된 권한은 base/settings.example.json 승격 후보
- [ ] 3. 설정 변경 이력 — ~/.claude/config-changelog.md 를 drafts/observations/memory-<기기>/ 로 복사하고 원본은 비움
- [ ] 4. auto memory 수집 — ~/.claude/projects/*/memory/*.md 를 drafts/observations/memory-<기기>/ 로 복사. 저장소 무관 성향은 drafts/claude-md/ 후보
- [ ] 5. 관찰 기록 검토 — drafts/observations/*.md 에서 두 번 이상 반복된 것만 전역 지침 후보(drafts/claude-md/)
- [ ] 6. 스킬 재시험 — base/skills/* 각 3시나리오를 tools/test-skill.sh 로 (Sonnet). 실패하면 초안으로 내려 수정
- [ ] 7. /insights — 대화형 세션에서 실행, 제안 중 반복되는 것만 후보
- [ ] 8. 사용량 — 상태줄 $ 누계, claude.ai 사용량 페이지, GitHub Settings → Billing → Actions 분
- [ ] 9. 보드 정리 — PROGRESS 완료 항목 중 30일 지난 것을 docs/progress/archive-YYYY-MM.md 로. 열린 Issue(`gh issue list --state open`) 우선순위 재검토
- [ ] 10. 검토표 갱신 — docs/review-vs-official.md·docs/audit-*.md 에서 상태가 바뀐 행 갱신. 새 기능은 docs/research/ 규칙대로 조사
- [ ] 11. 릴리즈 판단 — [Unreleased]가 비어 있지 않고 다른 기기 설치가 예정돼 있으면 컷(versioning.md 컷 시점)
- [ ] 12. HANDOFF "마지막 점검일" 갱신
```

관련 항목: [C-21](PROGRESS.md#c-21) 정의, [C-43](PROGRESS.md#c-43) 대조·이력, [C-27](PROGRESS.md#c-27) 메모리 수집, [C-25](PROGRESS.md#c-25) insights, [C-38](PROGRESS.md#c-38)·[C-22](PROGRESS.md#c-22) 사용량, [C-40](PROGRESS.md#c-40) 보드 크기.
