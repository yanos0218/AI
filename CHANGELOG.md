# Changelog

형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/), 버전은 [docs/versioning.md](docs/versioning.md).
**최근 3개 릴리즈 + `[Unreleased]`만 남기고 이전 이력은 지운다**

- 릴리즈마다 [GitHub Releases](https://github.com/yanos0218/AI/releases)에 같은 내용이 있어 중복 관리를 피한다(예: `gh release view v0.5.0`)

## [Unreleased]

### Fixed

- `self-audit` 스킬 `references/method.md` 3절
  - 이슈 본문을 저장소 이슈 형식 문서 우선으로 쓰고, 없으면 배경/제안 내용/기대 효과/결정 헤딩. "근거 한 줄 + 이유"만 적어 이슈 형식 검사에 걸리던 문제([Issue #172](https://github.com/yanos0218/AI/issues/172), 새 세션 시험 2회, PATCH)

## [0.13.1] - 2026-10-07

### Changed

- `base/claude-md/CLAUDE.md` §1·§2
  - 도구 호출 앞뒤 진행 설명도 한국어, 첫 설명부터 결론 뒤 비유·예시 하나(2026-10-07 self-audit, PATCH)
- `docs/issue-format.md` 공통 절
  - 이슈 본문·코멘트에 체크박스를 쓰지 않는 규칙 명시([Issue #171](https://github.com/yanos0218/AI/issues/171), 버전 등급 미반영, 문서 전용)
- `base/claude-md/CLAUDE.md` §4
  - 검사 결과는 실제로 검사한 대상 수까지 읽고, 0건이거나 실제와 맞지 않으면 "미검증"으로 보는 규칙 추가. 0줄로 세고 ok를 찍는 검사에서 반영 전 2회 모두 "통과" 보고, 반영 후 2회 모두 문제를 짚음([Issue #167](https://github.com/yanos0218/AI/issues/167), PATCH)
- `CLAUDE.md` 검증 절
  - `docs/testing.md`로 분리(60/60 → 57줄), 시험 도구 목록·세 OS 호환 규칙·설치는 커밋 뒤 추가, `docs/skill-development.md`에 Mac 시험 준비 추가([Issue #166](https://github.com/yanos0218/AI/issues/166), 버전 등급 미반영 — 문서 전용)

## [0.13.0] - 2026-09-29

### Added

- `base/hooks/format-guard.sh`·`md-format-check.sh`·`format_check.py` 형식 검사 훅 승격
  - 커밋·이슈·PR·릴리즈 본문을 게시 직전에 검사해 목록 줄바꿈·음슴체 위반이면 막고, `.md`에 새로 쓴 부분은 저장 뒤 사유를 돌려줌. `settings.example.json`에 `git`·`gh` 명령과 `.md` 편집일 때만 뜨게 등록, 같은 호출 중복 실행 방지([Issue #141](https://github.com/yanos0218/AI/issues/141), MINOR)
- `tools/test-format-guard.sh`
  - 형식 검사 훅 시험 32건, `drafts/hooks/`에서 옮김([Issue #141](https://github.com/yanos0218/AI/issues/141), PATCH)
- `base/skills/usage-dashboard` 스킬 승격
  - 요청할 때만 켜는 토큰 사용 기록과 로컬 대시보드(5시간 블록·시간·일·월, 저장소·메인/서브에이전트·모델별, 요청 순위와 원인). 세션 시작 크기가 평소보다 커지면 화면에만 강조, 세션 시작 알림(`usage.sh check`)은 뺌(사용자 결정, 대시보드와 중복·세션 시작 지연). `settings.example.json`에 async Stop 훅 등록, 꺼져 있으면 훅은 바로 끝남. Windows·Mac 전용([Issue #136](https://github.com/yanos0218/AI/issues/136), MINOR)
- `tools/test-session-start-check.sh`
  - 세션 시작 훅의 설정 낡음 판정 시험. 임시 원격·복제본·가짜 HOME으로 원격 앞섬, 문서만 바뀐 커밋, 옛 버전 파일 형식, fetch 주기와 기다리지 않음을 확인([Issue #150](https://github.com/yanos0218/AI/issues/150), PATCH)

### Changed

- `base/claude-md/CLAUDE.md` §8
  - 설계를 보일 때 채울 칸(무엇을·왜, 바뀌는 파일, 검증 방법, 문서 동기화 대상, 결정 필요) 추가. 새 세션 비교에서 반영 전 2회 모두 검증·문서 칸 없음, 반영 후 2회 모두 채움([Issue #155](https://github.com/yanos0218/AI/issues/155), PATCH)
- `base/vscode/extensions.txt`
  - `redhat.vscode-yaml`·`timonwong.shellcheck` 추가(설정 파일 없이 동작, CI와 같은 기준), 파일 아이콘 `pkief.material-icon-theme` 추가와 `settings.json`에 아이콘 테마 지정, Mac에서 쓰지 않는 Swift 확장 주석 삭제([Issue #165](https://github.com/yanos0218/AI/issues/165), PATCH)
- `base/hooks/check-cram.py`
  - 목록 줄바꿈 판정기를 `tools/`에서 옮김, 전역 형식 검사 훅과 저장소 커밋 검사(`tools/check-cram.sh`)가 같은 판정기를 씀([Issue #141](https://github.com/yanos0218/AI/issues/141), PATCH)
- `.github/workflows/lint.yml`
  - shellcheck 대상에 `base/skills/*/scripts/*.sh`와 `drafts/hooks/*.sh` 추가, 초안 폴더가 비어도 실패하지 않게 빈 글롭은 건너뜀(`nullglob`), 로컬 같은 대상 경고 0건([Issue #161](https://github.com/yanos0218/AI/issues/161), PATCH)
- `tools/install.sh`
  - 버전 표시 파일 3행에 `base/` 트리 해시를 기록함. 1·2행은 그대로라 기존 세션 시작 훅과 호환, 문서만 바뀐 커밋을 설정 변경과 구별하는 데 씀([Issue #150](https://github.com/yanos0218/AI/issues/150), PATCH)

### Fixed

- `.claude/hooks/session-end-check.sh`
  - 공백·이름 바뀐 파일의 경로를 일부만 읽어 `base/` 변경을 놓치던 문제와, 규칙과 반대로 "닫기(Closes #N)"를 안내하던 문구. 경로 전체와 옛·새 경로를 읽고 `Refs #N` 안내로 바꿈([Issue #163](https://github.com/yanos0218/AI/issues/163), PATCH)
- `tools/test-skill.sh`·`tools/test-agent.sh`
  - `--tools ""`처럼 빈 값이면 Mac bash 3.2에서 `tool_rules` 빈 배열로 멈추던 문제, 빈 배열 안전하게 펼침([Issue #162](https://github.com/yanos0218/AI/issues/162), PATCH)
- `base/hooks/session-start-check.sh`
  - 원본 저장소가 원격보다 뒤처져도 낡음 알림이 안 뜨던 문제와, 문서만 바뀐 커밋에도 알림이 뜨던 거짓 경보. 하루 한 번 백그라운드 fetch, 뒤처지면 원격 기준, `base/` 트리 해시로 비교(옛 설치본은 태그 비교)([Issue #150](https://github.com/yanos0218/AI/issues/150), PATCH)
- `base/skills/config-update`
  - 원격을 확인하지 않아 낡은 버전을 최신으로 판정하던 문제. fetch → 뒤처졌고 작업 트리가 깨끗하면 `pull --ff-only` → `base/` 트리 비교 → 다를 때만 설치([Issue #150](https://github.com/yanos0218/AI/issues/150), PATCH)
- `.claude/hooks/pre-commit-check.sh`
  - 명령을 `sed`로 꺼내며 뒤의 설명 글까지 삼켜, 설명에 "#64"·"chore(release):"가 있으면 이슈 번호 확인을 건너뛰고 커밋이 아닌 명령에 확인 창을 띄우던 문제. JSON으로 정확히 꺼냄([Issue #156](https://github.com/yanos0218/AI/issues/156), PATCH)
- `tools/check-install.sh`
  - 프로젝트 루트 기본값이 Windows 전용(`/c/Git`)이라 Mac·Linux에서 조용히 "(없음)"이던 문제. 기본값을 이 저장소의 상위 폴더로, 경로가 없으면 안내([Issue #157](https://github.com/yanos0218/AI/issues/157), PATCH)
- `tools/test-session-start-check.sh`
  - 실제 v0.12.0 태그에 기대 `base/`가 바뀐 뒤 "문서만 바뀐 커밋" 사례가 건너뛰어지던 문제. 시험 안에서 태그와 문서 커밋을 만들어 15건 모두 실행([Issue #158](https://github.com/yanos0218/AI/issues/158), PATCH)
- `tools/check-install.sh`·`tools/install.sh`·`tools/pack.sh`
  - 스킬 폴더의 파이썬 캐시(`__pycache__`)까지 비교·복사·압축해 거짓 `DIFF`가 나고 설치본·웹 zip에 캐시가 섞이던 문제. 세 곳 모두 제외([Issue #160](https://github.com/yanos0218/AI/issues/160), PATCH)
- `tools/check-docs.sh`
  - Mac 기본 bash 3.2에 없는 `mapfile` 때문에 모든 파일을 0줄로 세고 통과시키던 문제, 하위 프로세스 없는 내장 `read`로 줄 수를 세도록 바꿈([Issue #151](https://github.com/yanos0218/AI/issues/151), PATCH)
- `tools/test-hooks-py.sh`
  - `python` 명령을 고정으로 불러 `python3`만 있는 Mac에서 7건이 실패하던 문제, 훅과 같은 순서(`python` → `python3`)로 고르도록 바꿈([Issue #151](https://github.com/yanos0218/AI/issues/151), PATCH)
- `tools/test-skill.sh`
  - 시험 중 스킬이 자신을 다시 설치하면(config-update) 끝날 때 비켜 둔 설치본이 새 폴더 안으로 들어가 이중 폴더가 생기던 문제. 복구 전에 대상 폴더를 치움([Issue #152](https://github.com/yanos0218/AI/issues/152), PATCH)
- `tools/test-agent.sh`
  - Mac에서 PyYAML이 없으면 변환 실패를 무시하고 세션을 띄워 "토큰 0"만 나오던 문제와, `--installed`에서 bash 3.2가 빈 배열로 멈추던 문제. 변환 실패 시 안내 후 종료, 빈 배열 안전하게 펼침([Issue #154](https://github.com/yanos0218/AI/issues/154), PATCH)
- `tools/check-cram.sh`
  - `--staged`에서 추가된 줄 번호 목록을 `awk -v`로 넘겨, Mac 기본 awk가 오류를 내고 여러 줄을 추가한 파일을 건너뛰어 통과시키던 문제. 환경변수로 넘기도록 바꿈([Issue #151](https://github.com/yanos0218/AI/issues/151), PATCH)

## [0.12.0] - 2026-09-28

### Added

- `base/agents/` 용도별 서브에이전트 3종 승격
  - 조사 `researcher`(Sonnet, 읽기·검색·웹만), 문서·참조 점검 `auditor`(Sonnet, 읽기·검색만), 검사 실행 `verifier`(Haiku). verifier는 전용 훅 `base/hooks/verifier-guard.sh`가 커밋·push·파일 쓰기·설치 명령을 차단. `install.sh`가 `~/.claude/agents/`에 설치하고 `check-install.sh`가 대조([Issue #131](https://github.com/yanos0218/AI/issues/131), MINOR)
- `base/hooks/compact-snapshot.sh`·`compact-snapshot-show.sh` 승격
  - 컴팩션 직전 git 상태·최근 테스트/빌드 명령과 결과를 저장했다가 컴팩션 직후 세션 시작 메시지로 보여주고 지움. `settings.example.json`에 PreCompact·SessionStart(compact) 등록([Issue #104](https://github.com/yanos0218/AI/issues/104), MINOR)
- `base/skills/pdf-extract` 스킬 승격
  - PDF를 MarkItDown으로 텍스트 변환 후 읽어 토큰 절약(4쪽 한국어 실측 −62%). 스캔본·글자 깨짐 판정 후 직접 읽기로 전환, MarkItDown은 `~/.claude/venvs/markitdown` 가상환경에 사용자 승인 후 설치([Issue #132](https://github.com/yanos0218/AI/issues/132), MINOR)
- `tools/check-cram.py`
  - 파일 맨 앞 YAML 머리말(`---` ~ `---`)은 검사하지 않음. 스킬·에이전트 설정 줄이 크램으로 오탐되던 문제, 머리말 예외 2줄 정리([Issue #132](https://github.com/yanos0218/AI/issues/132), PATCH)
- `tools/test-agent.sh`
  - 에이전트 발동 시험 도구. 같은 폴더 에이전트를 `--agents` JSON으로 넘겨 위임 대상·도구 호출·훅 차단·토큰 추출([Issue #131](https://github.com/yanos0218/AI/issues/131), PATCH)
- `tools/check-cram.py`
  - 표 줄도 검사: 셀을 나누고 `<br>` 조각마다 목록 크램 규칙 적용. 픽스처에 표 사례 추가([Issue #126](https://github.com/yanos0218/AI/issues/126), PATCH)

### Changed

- `base/settings.example.json` 훅 대기 줄이기
  - 기록만 하는 config-changelog·bulk-read-log를 `async`로 돌려 명령·편집 뒤 기다리지 않음
  - `if` 조건으로 gh-throttle은 `gh`·`bash` 명령, config-changelog 편집 기록은 `~/.claude` 파일만. 조건은 명령 이름만 써서 heredoc 등에서 같은 훅이 여러 번 뜨지 않게 함
  - 느린 시각 실측 명령 대기 중앙값 42.8초(2026-09-28)의 원인 대응([Issue #147](https://github.com/yanos0218/AI/issues/147), PATCH)
- `.claude/settings.json`(이 저장소 전용)
  - 훅 경로를 `${CLAUDE_PROJECT_DIR}` 기준으로 바꿔 작업 폴더를 옮겨도 동작, pre-commit-check는 `if` 조건으로 `git`·`bash` 명령에서만, 같은 도구 호출에 두 번 뜨면 하나만 검사, 제한 시간 120초([Issue #148](https://github.com/yanos0218/AI/issues/148))
- `base/hooks/` config-changelog·bulk-read-log·verifier-guard 파이썬 전환
  - 셸 입구는 대상 아닌 입력을 하위 프로세스 없이 끝내고, 판정은 파이썬 본체와 공통 모듈 `hooklib.py`가 함(입력 JSON을 정확히 읽어 설명 글·따옴표 안 글 오탐 약 70건 제거, 옛 훅이 놓친 여러 줄 명령 안 `git add` 차단)
  - 막는 훅(verifier-guard)은 파이썬이 없거나 오류면 차단, 기록 훅은 조용히 통과하고 `~/.claude/hook-errors.log`에 기록
  - `settings.example.json`의 config-changelog·bulk-read-log 제한 시간 5초 → 30초. 느린 시각에 확인 없이 통과되던 문제 해결([Issue #143](https://github.com/yanos0218/AI/issues/143))
  - `tools/install.sh`·`check-install.sh`가 `base/hooks/*.py`도 복사·대조([Issue #144](https://github.com/yanos0218/AI/issues/144), PATCH)
- `.claude/hooks/baseline-guard.sh`(이 저장소 전용)
  - 같은 구조로 전환, 실패하면 확인 창. 제한 시간 30초. 시험은 `tools/test-hooks-py.sh`([Issue #144](https://github.com/yanos0218/AI/issues/144))
- `base/claude-md/CLAUDE.md` 5절 서브에이전트 문장
  - 전용 에이전트(researcher·auditor·verifier)가 있으면 그것을 쓰고, 에이전트 파일에 모델이 있으면 `model` 값을 넘기지 않음. 나머지는 기존대로 Sonnet([Issue #131](https://github.com/yanos0218/AI/issues/131), PATCH)
- `base/claude-md/CLAUDE.md` 5절 조사 규칙
  - 도구·사례 조사는 표본을 정량으로 뽑고 스타·최근 활동을 직접 확인, "없다" 대신 찾아본 범위, 서브에이전트 조사 결과는 보고 전 직접 재검증([Issue #138](https://github.com/yanos0218/AI/issues/138), PATCH)
- `base/skills/` SKILL.md 4개(_template, config-update, dev-workflow, self-audit)
  - 목록 줄바꿈 규칙 위반 8줄을 하위 bullet·소제목·문장 분리로 수정. 동작 변경 없음([Issue #137](https://github.com/yanos0218/AI/issues/137), PATCH)
- `base/skills/*/references/` 4개 파일(_template detail, dev-release release-notes-format·semver-rules, dev-workflow file-layout)
  - 같은 규칙 위반 4줄 수정, self-audit method.md 필드 나열 3줄은 예외 등록. 동작 변경 없음([Issue #137](https://github.com/yanos0218/AI/issues/137), PATCH)
- `base/rules/docs-format.md`
  - "필드명: 값" 예외를 짧은 한 줄 값으로 좁힘. 문장·항목이 여럿인 값(조사 이슈의 결론·출처·영향 등)은 하위 bullet로 줄바꿈([Issue #133](https://github.com/yanos0218/AI/issues/133), PATCH)
  - GitHub Issue·PR 본문과 코멘트도 음슴체·명사형으로 쓴다는 줄 추가. 기존엔 릴리즈 노트만 규정([Issue #126](https://github.com/yanos0218/AI/issues/126), PATCH)
  - "필드명: 값" 예외의 예시에서 옛 조사 이슈 양식(질문/조사일, 결론/출처/영향 필드) 언급 제거. 조사 이슈가 `##` 헤딩 양식으로 바뀐 데 따름([Issue #146](https://github.com/yanos0218/AI/issues/146), PATCH)
- `docs/issue-format.md`·`.github/workflows/issue-format-check.yml` 조사(`research`) 양식
  - `## 조사` 아래 필드 목록 대신 다른 양식처럼 `## 질문`·`## 결론`·`## 조사일`·`## 출처`·`## 영향` 헤딩으로 통일. 자동 검사도 새 헤딩 기준([Issue #146](https://github.com/yanos0218/AI/issues/146))
- base에서 원본 저장소(claude-config) 참조 제거
  - 전역 CLAUDE.md·repo-setup·dev-workflow·dev-release의 "claude-config `docs/...` 참고" 5곳을 스킬 자체 기준으로 교체. 다른 기기 세션이 원본 저장소에 관여하려던 문제 대응([Issue #125](https://github.com/yanos0218/AI/issues/125), PATCH)
- `session-start-check.sh`
  - 설정 낡음 알림에서 원본 저장소 경로·`install.sh` 명령을 빼고 "갱신 여부만 묻고 config-update 스킬로만 갱신, 원본 저장소 파일은 읽거나 고치지 않음"으로 변경([Issue #125](https://github.com/yanos0218/AI/issues/125), PATCH)
- `config-update` 스킬
  - SRC_PATH를 `install.sh`·`check-install.sh` 실행에만 쓰고 그 저장소에 읽기·쓰기·이슈·push를 하지 않는다는 줄 추가([Issue #125](https://github.com/yanos0218/AI/issues/125), PATCH)

### Fixed

- `tools/check-docs.sh`·`.claude/hooks/pre-commit-check.sh` 커밋 검사가 제한 시간을 넘겨 검사 없이 커밋되던 문제 일부
  - check-docs.sh 줄 수 세기를 bash 내장으로 바꿔 느린 시각 24초 → 4.6초, 커밋 검사의 markdownlint는 스테이징된 .md만
  - `git -C <경로> commit` 형태도 커밋으로 판정([Issue #148](https://github.com/yanos0218/AI/issues/148))
- `base/hooks/git-guardrails.sh`·`gh-throttle.sh`
  - 판정을 bash 내장 기능으로 바꿔 하위 프로세스를 없앰, 제한 시간 5초·9초 → 30초. 느린 시각에 9.5초가 걸려 제한 시간을 넘기면 확인 창 없이 통과될 수 있던 문제([Issue #142](https://github.com/yanos0218/AI/issues/142), PATCH)
- `base/agents/researcher.md`
  - 웹 도구가 권한 거부되면 멈추고 보고, 홈·설치 폴더 로컬 우회 검색 금지. 같은 시험에서 에이전트 토큰 약 12.1만 → 2.6만([Issue #139](https://github.com/yanos0218/AI/issues/139), PATCH)
- `base/hooks/bulk-read-log.sh`
  - 서브에이전트 안에서 실행한 조회(입력에 `agent_id`)는 기록하지 않음, 알림 개수가 부풀던 문제([Issue #134](https://github.com/yanos0218/AI/issues/134), PATCH)
  - 명령을 160바이트로 자를 때 한글 조각이 남아 기록 파일이 UTF-8로 안 읽히던 문제

### Removed

- `drafts/observations/`
  - 날짜별 관찰 기록·auto memory 사본·claude.ai 내보내기 폴더 폐지. 월 점검에서 auto memory는 각 기기에서 직접 읽고 대화 방식은 self-audit로 확인. 저장소 `CLAUDE.md` 세션 끝 관찰 기록 규칙 삭제

## [0.11.4] - 2026-09-19

### Added

- `tools/check-install.sh`
  - `--summary` 옵션 신설: 6개 섹션 상세 없이 마지막 판정 줄만 출력. 릴리즈 컷 때 grep으로 걸러도 "설정 변경 이력" 섹션이 새서 컨텍스트를 불필요하게 채우던 문제 해결([Issue #123](https://github.com/yanos0218/AI/issues/123), PATCH)

### Changed

- `.gitattributes`
  - `.md`·`.json`에 `eol=lf` 추가. `core.autocrlf=true` 환경에서 커밋마다 반복되던 CRLF 경고 제거([Issue #123](https://github.com/yanos0218/AI/issues/123), 버전 등급 미반영 — 저장소 설정 전용)
- `docs/github.md`
  - "gh CLI를 Claude가 직접 사용" 행에 `-q`로 필요한 필드만 추출하는 습관 명시(원본 JSON을 그대로 받으면 토큰이 늘어남, [Issue #123](https://github.com/yanos0218/AI/issues/123), 버전 등급 미반영 — 문서 전용)
