---
name: feedback-reference-not-copy
description: claude-config 저장소에는 다른 저장소의 규칙·사례를 복사하지 않고 참조만 한다
metadata: 
  node_type: memory
  type: feedback
  originSessionId: d1d3662c-8db2-4c7f-b8d9-f1dd657ec8b2
  modified: 2026-09-08T11:56:13.926Z
---

다른 저장소(kolo_pwa, OpenClaw 등)에 있는 규칙·사고 사례·형식은 이 저장소로 **그대로 가져오지 말고 참조만** 한다. (2026-09-08, 사용자 직접 지시)

**Why:** 저장소별 내용은 그 저장소가 원본이고 계속 바뀐다. 복사하면 두 곳이 어긋나고, 날짜·P-번호 같은 시점 의존 정보는 곧 틀린 정보가 된다(공식 스킬 작성 가이드의 "time-sensitive 정보 금지"와도 일치).

**How to apply:** 전역 CLAUDE.md·스킬에는 저장소를 가리지 않는 규칙만 쓰고, 저장소별 예시가 필요하면 "저장소 문서(docs/versioning.md 등)가 있으면 그쪽 우선"으로 가리킨다. 참고 문서 목록은 [[project-claude-config-roadmap]]에 있다.
