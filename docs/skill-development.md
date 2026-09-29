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
- 에이전트(`drafts/agents/*.md`)는 `bash tools/test-agent.sh <에이전트.md> <시나리오 git 저장소> "<사용자 말>"`로 시험한다.
  - 프로젝트 `.claude/agents/`에 넣으면 `-p` 세션은 신뢰 전 폴더라 에이전트 훅이 건너뛰어진다. 그래서 `--agents` JSON 파일로 넘긴다(v2.1.281 이상, `CLAUDE_BIN`으로 실행 파일 지정).
- 스킬별 구체적인 시험 시나리오는 그 스킬의 `references/`에 둔다(예: [base/skills/dev-release/references/test-scenarios.md](../base/skills/dev-release/references/test-scenarios.md)).
- 시험 도구 실행 전 확인
  - Mac은 VS Code 확장만 깔려 있으면 `claude`가 PATH에 없다. `CLAUDE_BIN`에 확장 안의 실행 파일(`~/.vscode/extensions/anthropic.claude-code-<버전>-darwin-arm64/resources/native-binary/claude`)을 지정한다.
  - `test-agent.sh`는 PyYAML이 필요하다. Mac Homebrew 파이썬엔 없으니 가상환경에 설치하고 그 `bin`을 PATH 앞에 둔다.
- 새 세션이 시험 요청보다 세션 시작 알림("전역 설정이 낡았습니다", "CLAUDE.md가 없습니다")을 먼저 물으면 그 회차는 무효다(2026-09-29 2회 무효, [Issue #155](https://github.com/yanos0218/AI/issues/155))
  - 시험 전에 `bash tools/install.sh`로 설치본을 맞추고, 시나리오 저장소에 `.claude/.no-repo-setup-suggest`를 만든다.
- 시험이 실제 `~/.claude`에 설치를 실행하는 스킬(config-update 등)이면 버전 파일과 `settings.json`을 먼저 백업하고 끝나면 되돌린 뒤 `bash tools/check-install.sh`로 대조한다.
