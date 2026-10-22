# 운영체제별 차이 구분

같은 저장소를 Windows와 Mac(Linux 포함)에서 쓰므로, 무엇이 모든 기기에서 같아야 하고 무엇이 운영체제 때문에 다를 수밖에 없는지 구분해 두는 문서임([Issue #197](https://github.com/yanos0218/AI/issues/197)). 새 차이가 생기면 이 표에 먼저 올리고 처리 방식을 정함.

## 구분 기준

| 구분 | 뜻 | 같은지 확인하는 법 |
| --- | --- | --- |
| 공통 | 모든 기기에서 값이 같아야 함 | 기기끼리 `diff`했을 때 차이가 없어야 함 |
| 운영체제별(코드) | 같은 파일이 실행할 때 운영체제를 보고 갈라짐 | 파일 내용은 같고 동작만 다름 |
| 운영체제별(설치) | 설치 위치나 방법이 운영체제마다 다름 | 설치 스크립트가 운영체제별로 갈라짐 |
| 기기별 | 운영체제와 무관하게 기기 사정에 따라 다름 | 사용자 `settings.json`에 직접 둔 값, 병합 규칙이 보존함 |

## 지금 확인된 항목 (2026-10-21 Mac에서 코드 조사, 2026-10-22 Windows·AlmaLinux 9 WSL 출력 대조)

| 구분 | 항목 | 처리 방식 | 근거 |
| --- | --- | --- | --- |
| 공통 | 전역 지침, rules, agents, skills·hooks 파일 내용 | `install.sh`가 같은 파일을 복사 | [tools/install.sh](../tools/install.sh) |
| 공통 | settings.json의 모델·effort·env·상태줄·허용·차단 목록·훅 | 같은 값을 병합([Issue #194](https://github.com/yanos0218/AI/issues/194)) | [base/settings.example.json](../base/settings.example.json), [tools/settings_merge.py](../tools/settings_merge.py) |
| 운영체제별(코드) | 대시보드 열기·주소 복사<br>Mac은 `open`·`pbcopy`, Windows는 `cmd.exe`·`clip.exe` | 실행할 때 `uname -s`로 분기 | [base/skills/usage-dashboard/scripts/usage.sh](../base/skills/usage-dashboard/scripts/usage.sh) |
| 운영체제별(코드) | 파이썬 이름<br>Windows는 `python`, Mac은 `python3` | 있는 것을 순서대로 찾음 | [testing.md](testing.md) "세 OS에서 도는 스크립트 쓰기" |
| 운영체제별(코드) | 상태줄 JSON 읽기 도구<br>`jq`가 없는 Linux 등 | jq, python, node 순으로 찾음 | [install.md](install.md) |
| 운영체제별(설치) | VS Code 설정 파일 위치<br>Windows `%APPDATA%`, Mac `~/Library/Application Support` | 설치 스크립트가 운영체제별로 갈라짐 | [base/vscode/install.sh](../base/vscode/install.sh), [base/vscode/install.ps1](../base/vscode/install.ps1) |
| 운영체제별(설치) | Mac 전용 확장 `swift-vscode` | 기본 목록에서 빼고 Mac에서 따로 설치 | [install.md](install.md) |
| 운영체제별(설치) | Linux RHEL 계열 최소 설치본<br>git·diff·python3이 버전마다 없을 수 있음 | 설치 전에 `dnf install -y git diffutils python3`을 실행 | [install.md](install.md) |
| 공통(운영체제 전용 항목 포함) | settings.json 훅의 `PowerShell` matcher 4곳<br>Windows 전용 도구용이지만 모든 기기에 같이 설치되고 Mac에서는 해당 도구가 없어 쓰이지 않음 | 같은 값을 병합, 무해해서 갈라 두지 않음 | [base/settings.example.json](../base/settings.example.json) |
| 기기별 | Mac·Windows의 `permissions.blockReadsOutsideWorkingDirectories`<br>Linux는 아직 없음, 기본 영역 반영 전 임시 불일치 | 사용자 `settings.json`에 직접 둠, 기본 영역 반영은 [Issue #195](https://github.com/yanos0218/AI/issues/195) | [Issue #194](https://github.com/yanos0218/AI/issues/194) 확인 절차 |
| 운영체제별(실행 환경) | Windows PowerShell에서 `bash`<br>Git Bash가 아니라 WSL(`C:\WINDOWS\system32\bash.exe`)이 실행돼 `~/.claude`가 없는 리눅스 홈을 봄 | Windows에서는 Git Bash 터미널이나 Claude Code `Bash` 도구에서 실행 | [Issue #194](https://github.com/yanos0218/AI/issues/194) 2026-10-22 |
| 운영체제별(실행 환경) | Windows `fingerprint.sh` 출력 줄 끝이 CRLF<br>Mac·Linux 출력과 그냥 `diff`하면 모든 줄이 다르게 나옴 | `diff --strip-trailing-cr`로 비교 | [Issue #194](https://github.com/yanos0218/AI/issues/194) 2026-10-22 |
| 운영체제별(실행 환경) | WSL의 `code`<br>Windows VS Code가 PATH로 잡혀 `check-install.sh`가 확장 16개를 MISSING으로 보고하고 실패로 끝남 | WSL이고 `code`가 `/mnt/` 아래(Windows VS Code)면 MISSING 목록은 보이되 판정에서 제외하고 안내 한 줄, WSL 안 `code`의 MISSING은 그대로 실패로 셈 | [Issue #201](https://github.com/yanos0218/AI/issues/201) 2026-10-22 |
| 후보(미확정) | 샌드박스는 Windows 미지원 | 설정 값으로 갈라야 하는지 확인 뒤 결정 | [PROGRESS.md §5](PROGRESS.md#5-보류기각) |

- 요약
  - 설정 파일의 값으로 운영체제를 구분해야 하는 항목은 아직 확인된 것이 없음
  - 지금까지의 차이는 모두 실행 코드나 설치 스크립트 안에서 풀림

## 새 차이가 생겼을 때

- 순서
  - 먼저 코드 안에서 갈라지는지 본다(`uname -s`, 있는 도구 찾기). 스크립트 복사본은 운영체제별로 두지 않음
  - 설정 값이 운영체제마다 달라야 하는 경우에만 덮어쓰기 구조를 검토함([Issue #197](https://github.com/yanos0218/AI/issues/197))
  - 기기 사정이면 운영체제별이 아니라 기기별이라 사용자 `settings.json`에 둠
- 어느 쪽이든 이 문서의 표에 한 줄 추가하고, 근거 이슈를 링크함

## 비교 방법

- 설치 병합 시험은 CI가 세 운영체제 러너에서 자동으로 돌림([testing.md](testing.md)), Claude Code 자체 동작은 러너에서 못 봐서 기기에서 확인함
- 기기마다 `bash tools/fingerprint.sh --common`을 실행해 출력을 `diff`함([testing.md](testing.md) "기기 간 차이")
  - 출력 줄은 [공통](같아야 함)과 [기기별](달라도 정상)로 표시되고 `--common`은 [공통]만 뽑음
  - `diff`가 비어 있으면 일치, 차이가 나오면 어긋남
  - Windows 출력이 섞이면 `diff --strip-trailing-cr`로 비교, Windows에서는 PowerShell이 아니라 Git Bash에서 실행
  - 사용자가 얹은 권한 키(예: `blockReadsOutsideWorkingDirectories`)도 [공통]에 나오므로 기본 영역에 반영되기 전까지는 차이로 드러남
- 전체 출력(옵션 없음)은 [기기별] 줄까지 보여 주며 그 차이는 정상
- 새 항목은 [공통]에 둘지 [기기별]에 둘지 이 문서의 구분 기준으로 정하고 `tools/fingerprint.sh`의 `COMMON` 목록에 반영함
