# claude-config

개인용 Claude 설정 원본 저장소. Claude Code(CLI)와 Claude.ai(웹) 양쪽에서 쓰는 **저장소를 가리지 않는** 스킬·공통 지침(CLAUDE.md)·훅을 여기서 관리하고 배포한다.

저장소 전용 규칙·스킬은 각 저장소(`CLAUDE.md`, `.claude/skills/`)에 두고, 여기서는 **참조만** 한다. 다른 저장소의 내용을 이쪽으로 복사하지 않는다.

## 구조

```text
claude-md/CLAUDE.md                        전역 공통 지침 → ~/.claude/CLAUDE.md
skills/dev-release/                        SemVer 등급 판단 + 릴리즈 컷 절차
  ├─ SKILL.md
  └─ references/
      ├─ semver-rules.md                   등급 기준, 저장소 유형별 관점
      ├─ release-steps.md                  명령어, 자동 워크플로, 버전 파일 위치
      └─ release-notes-format.md           한국어 릴리즈 노트 기본 형식
skills/_template/                          새 스킬 틀 (SKILL.md + references/detail.md)
scripts/hooks/git-guardrails.sh            push·강제삭제 등 앞에서 확인 프롬프트를 강제하는 PreToolUse 훅
scripts/hooks/settings.hooks.example.json  위 훅을 ~/.claude/settings.json에 넣는 예시
scripts/pack.sh                            skills/* → dist/<이름>.zip (_로 시작하는 폴더 제외)
```

## 설치

### Claude Code (CLI)

```bash
cp -r skills/dev-release ~/.claude/skills/
cp claude-md/CLAUDE.md ~/.claude/CLAUDE.md
mkdir -p ~/.claude/hooks && cp scripts/hooks/git-guardrails.sh ~/.claude/hooks/
```

훅은 `~/.claude/settings.json`의 `hooks` 키에 `scripts/hooks/settings.hooks.example.json` 내용을 합쳐야 켜진다(기존 키가 있으면 배열에 추가). 스킬 목록은 세션 시작 시 고정되므로 복사 후 **새 세션**에서 확인한다.

### Claude.ai (웹)

1. `bash scripts/pack.sh` → `dist/<스킬이름>.zip` 생성
2. Claude.ai **Customize → Skills**에서 zip 업로드

웹은 `CLAUDE.md`와 훅을 지원하지 않는다. 프로젝트(Project)의 **Project instructions**에 `claude-md/CLAUDE.md` 내용을 붙여넣어 대체한다.

## 새 스킬 추가

1. `skills/_template/`을 복사해 이름을 바꾼다.
2. `SKILL.md`는 A4 한 장(50~60줄) 이내. 긴 자료는 `references/`로 빼고 SKILL.md에 "언제 읽을지"만 적는다. 참조는 한 단계만.
3. frontmatter `description`에 **사용자가 실제로 쓰는 말투**("~해줘", "~하자")를 따옴표로 넣고 3인칭으로 쓴다 — 이것이 발동 기준이다.
4. 날짜·특정 저장소 사례 같은 시점 의존 정보는 넣지 않는다. 필요하면 "저장소 문서 참고"로 가리킨다.
5. 새 세션에서 3가지 상황으로 시험한 뒤 완료로 본다.

### dev-release 시험 시나리오

| 상황 | 기대 동작 |
| --- | --- |
| `docs/versioning.md`가 있는 저장소에서 "몇 버전으로 올려야 해?" | §0에서 문서를 찾았다고 알리고, 그 문서 기준으로 등급과 근거 제시. 릴리즈는 실행하지 않음 |
| 태그가 `v2.9` 같은 두 자리인 저장소에서 "릴리즈 컷 하자" | 두 자리 형식을 유지하고, 체크리스트를 답변에 복사해 진행. 6번에서 멈추고 확인 요청 |
| 태그도 CHANGELOG도 없는 저장소 | CHANGELOG를 만들지 여부부터 확인. 임의로 태그 형식을 정하지 않음 |

## 규칙을 고칠 때

- 어떤 저장소에서든 같은 지적을 두 번 받거나 실수가 실제 문제로 이어졌으면, 저장소 전용이면 그 저장소 `CLAUDE.md`에, 저장소를 가리지 않으면 `claude-md/CLAUDE.md`에 기록한다.
- 줄을 추가할 때 "이 줄이 없으면 Claude가 실제로 실수하는가?"에 예일 때만. 반드시 지켜져야 하는 것은 CLAUDE.md 문장이 아니라 훅으로 만든다.
- `claude-md/CLAUDE.md`를 고쳤으면 `~/.claude/CLAUDE.md`로 다시 복사한다(Mac·Windows 각각).

## 참고한 자료

- [Claude Code 공식 — Best practices](https://code.claude.com/docs/en/best-practices), [CLAUDE.md와 메모리](https://code.claude.com/docs/en/memory)
- [Agent Skills 공식 — 작성 모범 사례](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices), [anthropics/skills](https://github.com/anthropics/skills)
- [HumanLayer — Writing a good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md) (지시 예산 150~200개, 60줄 이내)
- [Writing a CLAUDE.md that Claude actually follows](https://dev.to/peterverse180/writing-a-claudemd-that-claude-actually-follows-4llo) (이진 규칙, 검증 가능한 문장)
- [mattpocock/skills — git-guardrails](https://github.com/mattpocock/skills/blob/main/skills/misc/git-guardrails-claude-code/SKILL.md) (훅 발상 참고)
- [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code), [josix/awesome-claude-md](https://github.com/josix/awesome-claude-md)
- [Dale Seo — CLAUDE.md 작성 가이드](https://daleseo.com/claude-code-claude-md/), [GeekNews — Claude Code로 좋은 결과 얻기](https://news.hada.io/topic?id=22425)
