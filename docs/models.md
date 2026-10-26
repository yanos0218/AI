# 기본 모델·effort 기준

개발 작업의 기본 모델과 effort를 모든 기기에서 같게 맞추는 기준임. 결정 근거는 [Issue #187](https://github.com/yanos0218/AI/issues/187), 조사는 [Issue #177](https://github.com/yanos0218/AI/issues/177).

## 결정 (2026-10-21)

- 기본은 Sonnet 5.5, effort는 medium
  - 원본은 [base/settings.example.json](../base/settings.example.json)의 `model`·`effortLevel`·`modelSettings`
  - 같은 방식으로 `language: korean`(응답 언어)도 맞춤([Issue #223](https://github.com/yanos0218/AI/issues/223), 영어 진행 설명 줄이기)
  - `tools/install.sh`가 설치할 때마다 이 값으로 맞춤(기기에서 `/model`로 바꿔 둔 값도 되돌아옴)
- 모델은 별칭(`sonnet`)이 아니라 전체 ID로 적음
  - 별칭이 가리키는 버전이 CLI 버전마다 달라, 기기 간 차이의 원인이 되기 때문
  - 새 모델이 나오면 원본의 ID를 직접 올림
- 최상위 `effortLevel`은 Opus 5.5에서 무시되므로 `modelSettings`에도 모델별로 적음

## 작업별로 고르는 기준

| 작업 | 모델 | effort |
| --- | --- | --- |
| 기능 구현·일반 수정 | Sonnet 5.5 | medium |
| 기계적 작업(이름 바꾸기 등) | Sonnet 5.5 | low |
| 설계·어려운 디버깅·코드 리뷰 | `/model opus`로 올림 | medium, 막히면 high |
| 장시간 무인 실행 | Fable 5.1<br>사용 크레딧으로 청구될 수 있어 실행 전 확인 | 개별 판단 |

- 근거는 공식 costs 문서("Sonnet handles most coding tasks well", Opus는 복잡한 설계·다단계 추론에만)와 claude.dev 글(2026-09-22~25, 제작자 측정)
- 작업 종류별 공식 권장 표는 없음(미확인)
- 모델별 구독 한도 소모 배율은 공식 수치가 없고, 2026-10-24에 이 계정에서 [tools/measure-model.sh](../tools/measure-model.sh)로 실측함([Issue #178](https://github.com/yanos0218/AI/issues/178))
  - 같은 읽기 전용 작업(규칙 위반 5개 찾기) 1회당 5시간 한도 소모는 Opus 5.5가 4%p(1회), Sonnet 5.5가 평균 1.5%p(2회, 1%p와 2%p)
  - 대략 2~3배로 보이나 표본이 작고 사용률 눈금이 1%p라 거칠며 회차마다 토큰 사용량 차이가 커서 확정 배율은 아님
  - 정답은 Opus 5/5, Sonnet 9/10(한 회차에서 오답 1개)
  - 도구는 모델마다 목표 몫 3%p를 채우면 다음 모델로 넘어가 Opus는 1회만 돌았음

## 올리고 내리는 법

- 모델
  - 그 세션만 바꾸기는 `/model opus`, 선택기에서 `s`
  - 저장해 다음 세션에도 쓰면 설치 때 원본 값으로 되돌아오므로, 바꾸려면 원본을 고침
- effort
  - `/effort <수준>`으로 바꿈
  - 세션 중에 바꿔도 캐시는 유지됨(claude.dev 글)
- plan 모드에서만 Opus를 쓰는 `opusplan` 별칭은 도입하지 않음
  - 한도 소모 배율이 대략 2~3배로 추정될 뿐 표본이 작아 보류 유지

## 기기에서 어긋났는지 보는 법

- `bash tools/check-install.sh`
  - 설치본 `settings.json`의 세 키가 원본과 같은지 대조
- `bash tools/fingerprint.sh`
  - `settings model`, `settings modelSettings`, `모델 환경변수` 줄을 기기끼리 비교
- 새 세션이 다른 모델로 시작하는 공식 원인(model-config 문서)
  - 선택기에서 `s`·`--model`로 그 세션에만 적용한 경우
  - 프로젝트·관리형 settings의 `model`, 셸의 `ANTHROPIC_MODEL`, 조직 기본값이 더 높은 우선순위인 경우
  - `~/.claude/settings.json`에 쓰지 못한 경우
  - `--resume`·`--continue`로 재개해 저장된 모델이 유지된 경우

## 한계

- 5.5 모델 ID는 CLI v2.1.284 이상이 필요함
  - Sonnet 5.5는 v2.1.284, Opus 5.5는 v2.1.280, Haiku 5.5는 v2.1.293 이상
  - 구버전 기기는 `fingerprint.sh`의 CLI 버전 줄로 확인하고 CLI를 올림
- 서브에이전트 모델은 이 설정과 별개
  - 각 에이전트 파일의 `model`이 정하고, 전역 지침 §5가 그 밖의 서브에이전트는 Sonnet으로 정함
