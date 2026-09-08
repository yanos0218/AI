# 릴리즈 절차 상세

## 공통 체크리스트

1. 테스트가 있다면 통과하는지 확인한다.
2. 산정된 버전을 사용자에게 보여주고 확인받는다.
3. 버전 파일을 갱신한다.
4. CHANGELOG(있는 경우)에 이번 릴리즈 항목을 추가한다.
5. 커밋: `chore(release): vX.Y.Z`
6. 태그: `git tag vX.Y.Z` (annotated 태그 권장: `git tag -a vX.Y.Z -m "vX.Y.Z"`)
7. push 여부, 배포 여부는 반드시 사용자에게 물어본다.

## 플랫폼별 버전 파일 위치

- Node.js: `package.json`의 `version` 필드 (`npm version <major|minor|patch>` 사용 가능)
- Python: `pyproject.toml`의 `[project] version` 또는 `setup.cfg`
- Rust: `Cargo.toml`의 `[package] version`
- Go: 보통 Go 모듈 자체엔 버전 필드가 없고 git 태그가 버전을 대신함

## npm 배포 시

```bash
npm version <major|minor|patch>   # package.json 버전 갱신 + 커밋 + 태그를 한번에
git push --follow-tags
npm publish
```

`npm publish`는 원격(레지스트리)에 공개 배포하는 되돌리기 어려운 작업이므로 실행 전 반드시 확인받는다.

## GitHub Release 생성 시

```bash
gh release create vX.Y.Z --title "vX.Y.Z" --notes "..."
```

CHANGELOG 항목을 `--notes`에 그대로 반영하면 중복 작성을 줄일 수 있다.

## 되돌리기

태그를 잘못 만들었을 때 로컬 태그만 지우는 것은 안전하지만, 이미 push한 태그를 삭제/재생성하는 것은 이를 참조하는 다른 사람에게 영향을 줄 수 있으므로 반드시 사용자 확인 후 진행한다.
