---
name: user-profile
description: "사용자(yanos0218)의 배경, 작업 방식, Claude에게 원하는 것 — 2026-09-08 GitHub 저장소 전수 조사로 파악"
metadata: 
  node_type: memory
  type: user
  originSessionId: d1d3662c-8db2-4c7f-b8d9-f1dd657ec8b2
  modified: 2026-09-08T11:42:09.345Z
---

- 개발자가 아니다. 상황에 따라 그때그때 필요한 걸 Claude와 함께 만든다("바이블 코딩"). 그래서 언어/스택이 프로젝트마다 다르다(JS PWA, Spring Boot, Swift, FastAPI, 셸 스크립트, 단일 HTML 도구, Markdown 자동화 시스템).
- 한국어, KST. Windows PC(이 세션)와 Mac mini(OpenClaw 자동화, `~/.claude/CLAUDE.md`가 따로 있을 가능성) 두 환경. Synology NAS에 자체 호스팅. Tistory 블로그 운영.
- 개인 프로젝트 위주. 활성 저장소: kolo_pwa(라이브 PWA 서비스, 가장 체계적), kolo-api, OpenClaw, Script(Rocky Linux 운영 스크립트), Etc(HTML 분석 도구).
- 작업 방식이 매우 체계적이다: Conventional Commits(한국어 제목), Keep a Changelog, `P-NN` 백로그 ID, 릴리즈 노트 형식·톤(음슴체)까지 확정해 둠. 규칙은 "날짜 + 실제 사고 + 앞으로의 규칙" 형식으로 저장소 CLAUDE.md에 쌓는다.
- Claude에게 고치고 싶은 점(2026-09-08 직접 답변): 확인을 너무 자주 묻거나 반대로 멋대로 진행함 / 매번 같은 배경 설명을 다시 해야 함 / 검증 없이 "됐다"고 함 / 설명이 너무 김. → 전역 CLAUDE.md §2~§5가 이걸 겨냥한다.

- 대화 방식(2026-09-08 관찰): 메시지 하나에 항목 여러 개를 `-`로 나열하고 `>`로 진짜 의도를 덧붙인다. "확인해줘"=현황 조사, "찾아주고 검토해줘"=커뮤니티 조사+판단, "어떻게 생각해?"=의견·추천. "진행해줘"는 직전 제안 전체 승인이므로 그 배치 안에서 중간 확인을 다시 받지 않는다. 결과는 표 + 추천 하나. 원자료는 저장소 `drafts/observations/`.

**How to apply:** 용어는 짧게 풀어 쓰고 추천안을 먼저 말한다. 저장소 문서(CLAUDE.md/docs)에 이미 답이 있는지 먼저 본다. 내부 작업은 묻지 않고, push·배포·삭제는 확인한다. "GitHub 저장소를 보고 판단해달라"는 요청이 자연스러운 사용자다.
