# claude-config

개인용 Claude 설정 원본 저장소입니다. Claude Code(CLI)와 Claude.ai(웹)에서 쓰는 스킬(Skill)과 공통 지침(CLAUDE.md)을 여기서 관리하고, 필요한 곳에 배포합니다.

## 구조

```text
skills/_template/    새 스킬을 만들 때 복사해서 시작하는 틀
skills/dev-release/  SemVer 버전 산정 + 릴리즈 절차 스킬
claude-md/CLAUDE.md  Claude Code 공통 지침 (한국어 소통, 커밋 규칙 등)
scripts/pack.sh      skills/* 를 dist/<이름>.zip 으로 압축
```

## 설치 방법

### Claude Code (CLI)

1. 원하는 스킬 폴더를 `~/.claude/skills/`에 그대로 복사합니다.

   ```bash
   cp -r skills/dev-release ~/.claude/skills/
   ```

2. 공통 지침을 적용하려면 `claude-md/CLAUDE.md`를 `~/.claude/CLAUDE.md`로 복사합니다.

   ```bash
   cp claude-md/CLAUDE.md ~/.claude/CLAUDE.md
   ```

### Claude.ai (웹)

웹은 폴더를 직접 읽지 못하므로 zip으로 묶어서 업로드해야 합니다.

1. `scripts/pack.sh`를 실행해 `dist/<스킬이름>.zip`을 만듭니다.

   ```bash
   bash scripts/pack.sh
   ```

2. Claude.ai에서 **Customize → Skills**로 이동해 zip 파일을 업로드합니다.

웹은 `CLAUDE.md`를 지원하지 않으므로, 공통 지침이 필요하면 프로젝트(Project)의 **Project instructions**란에 `claude-md/CLAUDE.md` 내용을 그대로 붙여넣어 대체합니다.

## 새 스킬 추가하기

1. `skills/_template/`을 원하는 이름으로 복사합니다.
2. `SKILL.md`는 A4 한 장(대략 50~60줄) 이내로 유지하고, 긴 참고 자료는 `references/`에 분리한 뒤 `SKILL.md`에 "언제 그 파일을 읽어야 하는지"를 명시합니다.
3. frontmatter의 `description`에는 무엇을 하는 스킬인지뿐 아니라 **언제 발동해야 하는지**(트리거 조건)까지 충분히 적습니다.
