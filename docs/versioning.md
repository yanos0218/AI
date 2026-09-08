# 버전 정책

이 저장소는 "설정 원본"이라 코드 배포는 없지만, **기기 3대(Windows·Mac mini·Linux)와 Claude.ai 웹에 어느 시점의 지침·스킬이 깔려 있는지**를 맞추기 위해 태그를 쓴다. 릴리즈 컷은 `dev-release` 스킬 절차를 따른다.

## 태그

- 형식 `vX.Y.Z` 세 자리, 접두사 `v`. 시작은 `v0.1.0`(2026-09-08).
- `v1.0.0`은 기본 영역이 Windows·Mac·웹 세 표면에 모두 반영된 시점에 올린다.

## 등급

기본 영역(`base/claude-md/`, `base/skills/<이름>/`, `scripts/`, `base/vscode/`)의 변경만 등급에 반영한다. `docs/`, `drafts/`, `.claude/`, README만 바뀐 것은 버전을 올리지 않는다.

| 등급 | 조건 | 예 |
| --- | --- | --- |
| MAJOR | 지침·훅의 의미가 바뀌어 **모든 기기에서 다시 설치하지 않으면 동작이 달라지는** 변경 | CLAUDE.md 확인 기준 개편, 훅 패턴 대폭 변경, 스킬 삭제 |
| MINOR | 기본 영역에 **새 자산 승격**(스킬·훅·설정 키 추가) | 개발용 스킬 승격 |
| PATCH | 기본 영역 안의 수정·문구·버그 | dev-release SKILL.md 규칙 한 줄 추가 |

## 절차

1. 변경은 `CHANGELOG.md` `[Unreleased]`에 쌓는다(Keep a Changelog, 한국어).
2. 승격이나 수정이 모이면 사용자가 컷을 요청한다. 작은 변경마다 태그를 찍지 않는다.
3. 컷 = CHANGELOG 확정 → `chore(release): vX.Y.Z` 커밋 → (사용자 확인) 태그·push → `bash tools/pack.sh` → `gh release create`에 `dist/*.zip` 첨부.
4. Release의 zip이 웹(Claude.ai) 업로드용 산출물이다. 웹에 올린 버전을 `docs/PROGRESS.md` §0 배포 열에 적는다.
