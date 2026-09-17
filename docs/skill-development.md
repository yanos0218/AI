# 새 스킬 추가

1. `base/skills/_template/`을 `drafts/skills/<이름>/`으로 복사한다.
2. `SKILL.md`는 A4 한 장(50~60줄) 이내. 긴 자료는 `references/`로 빼고 SKILL.md에 "언제 읽을지"만 적는다. 참조는 한 단계만.
3. frontmatter `description`에 **사용자가 실제로 쓰는 말투**("~해줘", "~하자")를 따옴표로 넣고 3인칭으로 쓴다.
   - 이것이 발동 기준이다.
4. 날짜·특정 저장소 사례 같은 시점 의존 정보는 넣지 않는다. 필요하면 "저장소 문서 참고"로 가리킨다.
5. 새 세션에서 3가지 상황으로 시험한 뒤 완료로 본다.

`base/skills/_template/SKILL.md` 하단 "작성 시 원칙"에도 같은 기준이 요약돼 있다.

- 실제로 스킬을 쓸 때 참고하고, 완성한 스킬 파일에서는 그 절을 지운다.

## 시험 방법

`bash tools/test-skill.sh <스킬 폴더> <시나리오 git 저장소> "<사용자 말>"`

- 시나리오 저장소의 `.claude/skills/`에 넣고 새 세션(`claude -p`, 기본 Sonnet)으로 돌려 발동·도구 호출·비용을 본다.
- 같은 세션 안에서 스킬을 직접 호출하는 것은 발동 테스트가 아니다.
- 스킬별 구체적인 시험 시나리오는 그 스킬의 `references/`에 둔다(예: [base/skills/dev-release/references/test-scenarios.md](../base/skills/dev-release/references/test-scenarios.md)).
