---
name: self-audit
description: "이 저장소의 CLAUDE.md·규칙 문서가 실제 대화·작업 방식과 얼마나 어긋났는지 최근 세션 기록을 직접 읽어 찾아내고, 반복된 지적·안 지켜진 규칙·문서화 안 된 결정을 후보로 제시한다. 사용자가 '이번 달 CLAUDE.md 점검해줘', 'self-audit 해줘', '지침 점검해줘', '이 저장소 감사해줘'라고 하면 사용한다. session-start-check.sh가 세션이 쌓이면 실행을 제안하지만, 실행(비용 발생)은 항상 사용자가 명시적으로 요청할 때만 한다."
allowed-tools: Bash(ls*) Bash(wc -l*) Bash(gh issue list*) Bash(gh label list*)
---

# self-audit

대화 기록을 실제로 읽어 CLAUDE.md·규칙 문서와 실제 작업 방식 사이의 간극을 찾는다(ykdojo `review-claudemd` 패턴 응용). 파일 몇 개로 상태를 이어가는 평소 방식(HANDOFF 등, 비용 0)과 역할이 다르다 — 이건 어쩌다 한 번 도는 유료 감사다.

## 0. 시작 전 확인

- 저장소 `CLAUDE.md`·`docs/`, 전역 `~/.claude/CLAUDE.md`·`~/.claude/rules/*.md`를 전부 읽는다 — 감사 대상 기준.
- 감사 표시 파일(`references/method.md` 1절)로 지난 감사 이후 세션 수를 센다. 처음이면 최신 것부터 상한까지만.
- 세션 개수를 한 줄로 알리고 진행한다.

## 1. 절차

```text
self-audit
- [ ] 1. 감사 대상 문서 전부 읽기 (저장소 CLAUDE.md·docs·전역 CLAUDE.md·rules/)
- [ ] 2. 서브에이전트(Sonnet, general-purpose)에게 대화 기록 분석 위임 — references/method.md 2절 지시문 그대로 전달
- [ ] 3. 서브에이전트가 돌려준 후보 목록(표)을 사용자에게 제시
- [ ] 4. ★ 사용자 확인 ★ — 후보마다 "문서 반영"/"Issue로만"/"기각" 중 고르게 한다
- [ ] 5. 고른 것만 처리: 문서 반영은 직접 수정 후 커밋, Issue는 references/method.md 3절 형식으로 생성
- [ ] 6. 감사 표시 파일 갱신 (references/method.md 1절)
- [ ] 7. 결과 보고 — 반영한 문서, 만든 Issue 번호, 기각한 것
```

## 2. 참고 자료

- `references/method.md` — 표시 파일 형식, 서브에이전트 지시문 원문, 세션·용량 상한, Issue 작성 형식. 2·5·6단계에서 읽는다.

## 하지 않는 것

- 사용자 확인 없이 CLAUDE.md·규칙 문서를 직접 고치지 않는다. 후보 제시까지만 자동, 반영은 항상 승인 후.
- 세션이 안 쌓였는데 먼저 나서서 실행하지 않는다 — 알려주는 건 훅(`session-start-check.sh`) 몫, 실행은 사용자가 말할 때만.
- 대화 기록 원문을 본 세션에 그대로 붙이지 않는다. 서브에이전트가 요약(표)만 반환한다.
