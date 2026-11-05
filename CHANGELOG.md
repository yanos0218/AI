# Changelog

형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/), 버전은 [docs/versioning.md](docs/versioning.md).
**최근 3개 릴리즈 + `[Unreleased]`만 남기고 이전 이력은 지운다**

- 릴리즈마다 [GitHub Releases](https://github.com/yanos0218/AI/releases)에 같은 내용이 있어 중복 관리를 피함(예: `gh release view v0.5.0`)

## [Unreleased]

### Changed

- `dev-release` 스킬의 마일스톤 절차 보강([Issue #267](https://github.com/yanos0218/AI/issues/267))
  - 이슈 배정이 모두 끝난 뒤 마지막에 마일스톤을 닫도록 순서를 명시함(닫힌 마일스톤은 `gh issue edit`이 못 찾아 실패)
  - 앞 릴리즈에 이미 배정된 이슈는 옮기지 않고, 이미 닫았을 때 다시 여는 방법과 zsh 반복문 주의를 추가함

## [0.18.4] - 2026-11-05

### Added

- 형식 검사 훅(`format_check.py`)에 이슈 번호 인접 검사 추가([Issue #264](https://github.com/yanos0218/AI/issues/264))
  - `#242는`처럼 번호 바로 뒤에 한글·영문이 붙으면 GitHub이 링크로 바꾸지 않아, 이슈·PR·릴리즈·커밋 본문과 음슴체 대상 `.md`에서 막음
  - 링크 주소·URL·백틱·따옴표 속 글자는 보지 않음, 과거 이슈 본문 35건과 커밋 11줄은 그대로 둠

### Changed

- `tools/eng-scan.py`가 파일 줄 번호 목록과 `file://` 안내 문장을 영어 설명으로 세던 오탐을 제거함([Issue #266](https://github.com/yanos0218/AI/issues/266))
  - 영어 우세 24건이 20건으로 줄고 비율은 1.8%에서 1.5%로 정정됨
- 전역 지침 `base/claude-md/CLAUDE.md`를 10,734바이트에서 9,292바이트로 줄임([Issue #242](https://github.com/yanos0218/AI/issues/242))
  - 사고 날짜·이슈 근거 괄호 9곳과 §8 사례 줄을 덜어냄(규칙 문장은 그대로, 이유는 `docs/decisions.md`와 이슈에 있음)
  - §5 서브에이전트 세부(전용 에이전트·모델 값, Sonnet 지정, 병렬 위임 파일 분리)를 `base/claude-md-details/subagents.md`로 분리하고 본문에는 읽으라는 한 문장만 둠
  - 목록 항목 두 개가 줄바꿈 없이 붙어 있던 4곳을 분리

## [0.18.3] - 2026-11-05

### Fixed

- heredoc 가림 순서 오류를 `verifier-guard`·`doc-drift-check`에도 수정([Issue #263](https://github.com/yanos0218/AI/issues/263))
  - `hooklib.mask_command` 추가, `verifier_guard.py`·`doc_drift.py`·`hooklib.command_words`·`bulk_read_log.py`가 사용
  - 따옴표 밖의 `<<`만 연산자로 보고 구분자는 원문에서 읽으며, 본문 속 짝 없는 따옴표가 뒤의 판정을 흐트러뜨리지 않음
  - 고쳐진 증상
    - heredoc 본문의 `>`를 파일 쓰기로 보고 `verifier-guard`가 deny하던 오탐
    - heredoc 본문의 `git commit`을 실제 커밋으로 보던 `doc-drift-check`의 오탐
    - 짝 없는 따옴표가 든 heredoc 뒤의 `> 파일`을 `verifier-guard`가 허용하던 누락
  - `tools/test-hooks-py.sh`(통과 50 / 실패 0)·`tools/test-doc-drift.sh`(통과 28건)에 시험 추가, 수정 전 훅으로는 4건 실패 확인
- `bulk-read-log` 훅이 정상 조회를 대량 조회로 오탐하던 문제 수정([Issue #262](https://github.com/yanos0218/AI/issues/262))
  - `--limit` 단독 기준을 20에서 100으로 올림(세션 시작의 `gh issue list --limit 50` 제외)
  - 결과를 파일로 저장하는 명령(`> 파일`, `>> 파일`)은 제외, `2>&1`·`> /dev/null`은 파일 저장으로 보지 않음
  - 따옴표 heredoc(`<<'EOF'`) 본문 속 글을 명령으로 보던 순서 오류 수정(`quote_mask`가 먼저 돌아 `EOF`를 지움)
  - `tools/test-hooks-py.sh`에 케이스 10개 추가(통과 42 / 실패 0, 수정 전 훅으로는 5건 실패 확인)
- `md-format-check` 훅의 문장형 종결 검사가 "있다(근거)", "하나다 —", "~다," 꼴을 놓치던 문제 수정([Issue #261](https://github.com/yanos0218/AI/issues/261))
  - 정정 전 docs에서 기존 식은 0줄, 보강한 식은 55줄 적발, 조사 "마다"는 제외
  - `tools/test-format-guard.sh`에 케이스 4개 추가(통과 48 / 실패 0)
  - CI `lint` job에 `format_check.py scan md` 단계 추가, Edit·Write를 거치지 않은 쓰기와 기존 위반을 사후에 잡음
- `tools/` 스크립트 11개, `drafts/hooks/notify.sh`, `base/skills/live-status/scripts/live.sh`가 이름만 보고 `python3`를 골라 Windows의 Microsoft Store 별칭(출력 "Python", 종료 코드 49)에 걸리던 문제 수정([Issue #255](https://github.com/yanos0218/AI/issues/255))
  - `tools/install.sh`처럼 `python3`·`python` 중 `-c 'import sys'`가 실제로 성공하는 것을 고름
  - `tools/test-python-pick.sh` 추가, 이름 순서만 믿는 줄이 남았는지 정적으로 확인하고 가짜 별칭을 앞에 둔 채 `check-cram.sh`·`check-docs.sh`를 실행함, CI `설치 병합 시험` job에 등록
- `tools/install.ps1`이 설치 뒤 다시 시작하는 방법을 알리지 않아 생기던 문제 2건에 안내 추가([Issue #258](https://github.com/yanos0218/AI/issues/258), [Issue #259](https://github.com/yanos0218/AI/issues/259))
  - Git·Python을 이번 실행에서 설치했으면 Claude Code와 터미널 창을 모두 닫고 새 창에서 시작하라고 안내함(같은 창은 새 PATH를 몰라 `python`이 Store 별칭으로 잡힘)
  - Claude Code 세션 안(`CLAUDECODE=1`)에서 Git Bash 없이 시작한 경우 그 세션의 명령이 `git-guardrails` 훅 실패로 막힐 수 있다고 경고함
  - [docs/install.md](docs/install.md) 주의에 같은 내용 추가

### Changed

- [docs/testing.md](docs/testing.md)와 [docs/os-differences.md](docs/os-differences.md)의 파이썬 선택 규칙을 "실행 확인 후 선택"으로 정정(도구는 `python3`→`python` 이름 순서였음)
- 읽기 차단 서술 정정([Issue #228](https://github.com/yanos0218/AI/issues/228), [Issue #231](https://github.com/yanos0218/AI/issues/231))
  - [docs/install.md](docs/install.md)는 "작업 폴더 밖 읽기가 막힘"을 `Read` 도구 한정으로 고치고 대화형 `Bash`는 막히지 않는다고 적음
  - [docs/review-vs-official.md](docs/review-vs-official.md)에 Windows 2.1.318 대화형 재현(2026-11-04)과, 공식 문서가 읽기 전용 `Bash` 명령도 이 설정의 영향 대상으로 적고 있어 어긋난다는 점을 추가
  - [docs/HANDOFF.md](docs/HANDOFF.md)의 남은 재시험에서 Windows를 뺌

## [0.18.2] - 2026-11-04

### Fixed

- 훅 4개(`session-start-check.sh`, `compact-snapshot.sh`, `compact-snapshot-show.sh`, `statusline.sh`)가 `python3`를 먼저 골라, Windows에서 Microsoft Store 별칭(출력 "Python", 종료 코드 49)에 걸려 조용히 종료되던 문제 수정([Issue #253](https://github.com/yanos0218/AI/issues/253))
  - `python` → `python3` 순으로 바꿔 [docs/testing.md](docs/testing.md)의 훅 규칙과 맞춤
  - `tools/test-session-start-check.sh`에 가짜 스토어 별칭 시나리오 추가(`jq`가 없을 때만 실행), 수정 전 훅은 10건 실패·수정 후 27건 통과
