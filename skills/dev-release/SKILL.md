---
name: dev-release
description: "변경 사항이 SemVer상 MAJOR/MINOR/PATCH 중 무엇인지 근거와 함께 판단하고, 저장소의 기존 버전 규칙(docs/versioning.md, README 버전 정책, 태그 자릿수, release-check.sh 등)을 우선 적용한 뒤 CHANGELOG 정리 → 릴리즈 노트 → 커밋 → 태그 → GitHub Release까지 릴리즈 컷을 진행한다. 사용자가 '몇 버전으로 올려야 해', '버전 올려줘', 'MAJOR/MINOR/PATCH 중 무엇으로 올릴지 알려줘', '릴리즈 컷 하자', '태그 찍어줘', '릴리즈해줘'라고 하면, 요청이 버전 판단만인지 릴리즈 실행까지인지 구분해 진행한다. 배포(서버 전송 등)만 요청했거나 저장소에 전용 배포 스킬이 있으면 그쪽을 우선한다."
---

# dev-release

저장소마다 버전 규칙이 다르다(자릿수, 노트 형식, 자동화 유무). **이 스킬은 기본값이고, 저장소 문서가 있으면 그쪽이 우선한다.**

## 0. 저장소의 기존 규칙부터 찾는다 (필수)

아래를 확인하고 발견한 것을 사용자에게 한 줄로 알린 뒤 진행한다.

| 확인 | 의미 |
| --- | --- |
| `docs/versioning.md`, README의 "버전 정책 / 버전 체계 / Version Policy" 절 | 등급 기준·태그 형식·릴리즈 빈도가 여기 정의됨. 아래 §1보다 우선 |
| `git tag --list --sort=-v:refname \| head` | 자릿수(`v1.2.3` vs `v1.2`)와 접두사 `v` — 기존 형식을 바꾸지 않는다 |
| `CHANGELOG.md` | Keep a Changelog 형식, `[Unreleased]` 누적 여부. 없으면 만들지 여부를 확인 |
| `.github/workflows/release*.yml`, `.github/release-notes/`, `scripts/release-check.sh` | 태그 push로 Release가 자동 생성되는지, 노트 파일을 태그 전에 만들어야 하는지, 검증 스크립트가 있는지 |
| 버전이 박힌 파일 | `package.json`, `pyproject.toml`, 스크립트 안 `SCRIPT_VERSION`, HTML 도구 안 `vX.Y`, README 배지 / `Version History` 표 |
| "SemVer 태그를 쓰지 않는다"는 선언 | 날짜순 CHANGELOG만 갱신하고 태그·Release는 만들지 않는다 |

## 1. 등급 판단

마지막 태그 이후 커밋(`git log <tag>..HEAD --oneline`)과 diff를 보고 아래 순서로 판단한다.

1. **먼저 BREAKING 여부를 확인한다**
   - API/CLI/설정/데이터 스키마 비호환, 데이터 소스 전환, UI 전면 개편, `feat!:` / `BREAKING CHANGE:`가 있으면 **MAJOR**
2. **그다음 기능 추가 여부를 확인한다**
   - 기존 동작 유지 + 기능·메뉴·옵션 추가면 **MINOR**
3. **그다음 수정/정리 여부를 확인한다**
   - 버그 수정, 문구·스타일, 성능 개선, 내부 정리면 **PATCH**
4. **여러 종류가 섞여 있으면 가장 높은 등급을 선택한다**
   - 예: 기능 추가와 버그 수정이 같이 있으면 **MINOR**; breaking change가 하나라도 있으면 **MAJOR**
5. **오탈자만 있거나 비기능적 변경이면 버전을 올리지 않는다**

0.y.z 단계와 판단이 갈리는 경우는 `references/semver-rules.md`를 읽는다.

**근거를 먼저 보여준다** — "커밋 A·B가 기능 추가라 MINOR → `vX.Y.0` 제안" 형태로 제시하고 확인을 받은 뒤 다음 단계로 간다. 버전 판단만 요청받았으면 여기서 끝낸다.

## 2. 릴리즈 컷 절차

저장소 문서에 절차가 있으면 그것을 따른다. 없으면 아래 체크리스트를 답변에 복사해 진행 상황을 표시하며 진행한다. 명령어와 플랫폼별 세부는 `references/release-steps.md`.

```text
릴리즈 vX.Y.Z
- [ ] 1. 테스트·체크 통과 (실행한 명령과 결과 기록)
- [ ] 2. CHANGELOG [Unreleased] → [X.Y.Z] - YYYY-MM-DD
- [ ] 3. 버전이 박힌 파일 전부 갱신 (§0에서 찾은 목록)
- [ ] 4. 릴리즈 노트 작성 — references/release-notes-format.md (노트 파일을 쓰는 저장소는 태그 전에)
- [ ] 5. 커밋 chore(release): vX.Y.Z
- [ ] 6. ★ 사용자 확인 ★ → git tag vX.Y.Z → git push origin main vX.Y.Z
- [ ] 7. GitHub Release 생성 또는 자동 워크플로 결과 확인, 검증 스크립트 실행
```

## 하지 않는 것

- **배포마다 태그를 찍지 않는다.** 작은 수정마다 올리면 버전 번호만 의미 없이 소진된다. 사용자가 릴리즈를 요청할 때만 컷하고, 그 사이 변경은 `[Unreleased]`에 쌓는다.
- 태그 형식·자릿수를 저장소 관례와 다르게 만들지 않는다. 이미 push된 태그는 사용자 확인 없이 지우거나 옮기지 않는다.
- push, 태그 push, Release 생성은 사용자 확인 없이 실행하지 않는다.
