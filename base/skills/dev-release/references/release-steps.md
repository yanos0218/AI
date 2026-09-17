# 릴리즈 절차 상세

SKILL.md §2의 명령어 수준 보충. 저장소에 릴리즈 절차 문서(`docs/versioning.md`, `playbooks/release-process.md` 등)가 있으면 그쪽을 따른다.

## 1. 기본 명령 순서

```bash
# 0. 상태·자격증명 확인
gh auth status                               # 실패하면 여기서 멈춘다 — 사용자가 직접 gh auth login. 토큰을 대화에 붙여넣으라고 하지 않는다
git status                                   # 미커밋 변경이 있으면 먼저 처리
git tag --list --sort=-v:refname | head -5   # 마지막 태그, 자릿수·접두사 확인
git log <마지막태그>..HEAD --oneline           # 등급 판단 근거

# 1~4. CHANGELOG / 버전 파일 / 릴리즈 노트 편집 (SKILL.md §2)

# 5. 커밋
git add -A && git commit -m "chore(release): vX.Y.Z"

# 6. 사용자 확인 후 태그 + push
git tag -a vX.Y.Z -m "vX.Y.Z"
git push origin main vX.Y.Z

# 7. Release — 자동 워크플로가 없을 때만
gh release create vX.Y.Z --title "vX.Y.Z - 한국어 제목" --notes-file <노트파일>
scripts/release-check.sh vX.Y.Z              # 있으면
```

브랜치 보호나 PR 필수 규칙이 있는 저장소는 `main` 직접 push 대신 작업 브랜치 → PR → merge 후 `main`을 `git pull --ff-only`로 최신화한 다음 태그를 찍는다.

## 2. 자동 Release 워크플로가 있는 저장소

- **태그 push로 자동 트리거**
  - 노트 파일(`.github/release-notes/vX.Y.Z.md` 등)을 요구하는 워크플로면 **태그 push 전에** 커밋돼 있어야 한다.
  - 워크플로 신설 이전에 push된 태그는 자동으로 안 걸리므로 Actions 탭에서 `Run workflow`로 수동 실행.
- **`workflow_dispatch`만 있는 경우**
  - 태그는 손으로 push하고, Actions에서 입력값(태그·제목)을 넣어 실행한다.
- 실행 후 `gh run list --workflow=<파일명> --limit 1`과 `gh release view vX.Y.Z`로 결과를 확인하고 사용자에게 보고한다.

## 3. 버전이 박힌 파일 — 플랫폼별

| 플랫폼 | 위치 | 비고 |
| --- | --- | --- |
| Node | `package.json` `version` | `npm version`은 커밋+태그를 한 번에 만드니 확인 절차와 충돌하지 않게 `--no-git-tag-version`을 쓰거나 손으로 편집 |
| Python | `pyproject.toml` `[project] version` 또는 `setup.cfg` | |
| Java/Gradle | `build.gradle` `version` | 태그를 안 쓰는 저장소면 해당 없음 |
| Swift/iOS | Xcode `MARKETING_VERSION`(마케팅 버전) + `CURRENT_PROJECT_VERSION`(빌드 번호) | 빌드 번호는 매 빌드 +1, 태그는 마케팅 버전 bump 때만 |
| 셸 스크립트 | 스크립트 안 `SCRIPT_VERSION="X.Y.Z"` + checksum 값 + 폴더 README 현재 버전·`Version History` 표 | 전부 같은 커밋에서 |
| 단일 HTML 도구 | 파일 안 `vX.Y` 표기 + 폴더 README 히스토리 표 | |
| Markdown 시스템 | README 제목/헤더의 버전 | |

## 4. 마일스톤 (GitHub Issues를 쓰는 저장소만)

이슈가 "닫힘"과 "실제로 릴리즈에 포함됨"은 시점이 다르다(승격은 즉시, 릴리즈 컷은 나중에 배치로). 마일스톤으로 그 연결을 남기면 `gh issue list --milestone vX.Y.Z`로 특정 릴리즈에 뭐가 들어갔는지 바로 찾을 수 있다.

```bash
# 1. 마일스톤 생성
resp=$(gh api repos/<owner>/<repo>/milestones -f title="vX.Y.Z" -f state=open -f due_on="<릴리즈 시각, ISO8601>")
num=$(echo "$resp" | python3 -c "import json,sys;print(json.load(sys.stdin)['number'])")

# 2. 직전 태그..이번 태그 범위 커밋에서 Closes #N 추출
git log <이전태그>..vX.Y.Z --format="%B" | grep -oiE 'closes #[0-9]+' | grep -oE '[0-9]+' | sort -un

# 3. 각 이슈에 배정
gh issue edit <N> --milestone "vX.Y.Z"

# 4. 마일스톤 닫기
gh api -X PATCH "repos/<owner>/<repo>/milestones/$num" -f state=closed
```

이슈 번호가 존재하지 않아 배정이 실패해도(오탈자 등) 나머지는 계속 진행하고 실패한 번호만 보고한다.

## 5. 되돌리기

- 로컬 태그만 잘못 만들었으면 `git tag -d vX.Y.Z`로 지우면 된다(안전).
- **이미 push된 태그**를 삭제·재생성하는 건 그 태그를 참조하는 Release·다른 클론에 영향을 준다. 사용자 확인 없이 하지 않고, 가능하면 새 PATCH 버전으로 앞으로 나간다.
- `npm publish` 같은 레지스트리 배포는 되돌릴 수 없다고 보고 실행 전 반드시 확인받는다.
