# drafts — 작업 영역

기본 영역(`base/`)에 아직 들어가지 않은 초안을 둔다. `pack.sh`와 설치 절차는 이 폴더를 보지 않으므로, 여기 있는 것은 어디에도 배포되지 않는다.

구조는 기본 영역을 그대로 따라 만든다.

```text
drafts/skills/<이름>/        새 스킬 초안 (base/skills/_template 복사해서 시작)
drafts/claude-md/CLAUDE.md   전역 지침 수정안 (기본 파일을 복사해 고친 뒤 diff로 검토)
drafts/hooks/<이름>.sh       새 훅 초안
```

## 기본 영역으로 올리는 조건 (승격)

1. README "새 스킬 추가" 5번의 시험(3가지 상황, 새 세션)을 통과했다.
2. 사용자가 "기본에 반영해"라고 명시적으로 요청했다.
3. `git mv drafts/<경로> base/<경로>`로 옮기고, `docs/PROGRESS.md`에 완료 표시, `docs/HANDOFF.md` 결정 사항에 한 줄 추가, 커밋 제목 `feat(<영역>): <이름> 기본 영역 승격`.

`.claude/hooks/baseline-guard.sh`가 기본 영역 쓰기 앞에서 확인 프롬프트를 띄운다. 승격 작업이면 승인하고, 아니면 여기로 돌아온다.
