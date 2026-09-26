# 도구 목록

조사했지만 당장 쓰지 않는 도구까지 한곳에 적어 둔다. 필요할 때 이 표에서 찾아보고, 쓰기로 하면 확인일을 보고 재확인한 뒤 도입한다. 판정 근거는 각 행의 조사 이슈에 있다([Issue #135](https://github.com/yanos0218/AI/issues/135), 2026-09-27 스킬 대신 기록만 남기기로 결정).

- 추가·변경
  - 조사 이슈의 결론이 바뀌면 같은 작업에서 이 표도 고친다.
- 확인일
  - 90일(Claude Code 기능은 30일)이 지났으면 도입 전에 재확인한다([docs/issue-format.md](issue-format.md) 조사 절과 같은 기준).

## 쓰는 중 또는 도입 진행 중

| 도구 | 이럴 때 | 판정 | 주의 | 확인일 | 근거 |
| --- | --- | --- | --- | --- | --- |
| MarkItDown(`pdf-extract` 스킬) | 여러 쪽 PDF를 읽거나 요약할 때 | 도입 | 스캔본·글자 깨짐은 직접 읽기로 전환<br>MCP 서버형은 쓰지 않음 | 2026-09-27 | [#132](https://github.com/yanos0218/AI/issues/132), [#127](https://github.com/yanos0218/AI/issues/127) |
| 용도별 에이전트(researcher·auditor·verifier) | 긴 조사, 문서 점검, 검사 실행 | 검증 중 | 긴 웹 문서는 잘릴 수 있음 | 2026-09-27 | [#131](https://github.com/yanos0218/AI/issues/131), [#130](https://github.com/yanos0218/AI/issues/130) |

## 필요할 때 쓸 후보

| 도구 | 이럴 때 | 판정 | 주의 | 확인일 | 근거 |
| --- | --- | --- | --- | --- | --- |
| kordoc | 한글(hwp·hwpx) 파일 내용을 봐야 할 때 | 조건부 | 품질 미시험<br>`npx kordoc <파일>`로 설치 없이 실행 | 2026-09-26 | [#127](https://github.com/yanos0218/AI/issues/127) |
| ccusage | 세션·모델별 토큰 사용 내역을 보고 싶을 때 | 조건부 | 로컬 기록만 읽음<br>한도 대비 %는 추정치 | 2026-09-26 | [#129](https://github.com/yanos0218/AI/issues/129) |
| Claude-Code-Usage-Monitor | 사용량을 터미널에서 실시간으로 볼 때 | 조건부 | 공식 값·추정치 구분 표시는 미확인 | 2026-09-26 | [#129](https://github.com/yanos0218/AI/issues/129) |
| session-report(공식 플러그인) | 스킬·에이전트별 토큰 원인을 찾을 때 | 필요 시 | 먼저 `/usage`·`/context`로 확인 | 2026-09-26 | [#129](https://github.com/yanos0218/AI/issues/129) |
| hookify(공식 플러그인) | 새 훅 초안을 빠르게 만들 때 | 선택 | 만든 훅은 drafts에서 검증 후 승격 | 2026-09-26 | [#129](https://github.com/yanos0218/AI/issues/129) |
| ponytail 규칙 문구 3개 | 코드가 과하게 커질 때 | 전역 지침 후보 | 플러그인 설치는 하지 않음 | 2026-09-26 | [#127](https://github.com/yanos0218/AI/issues/127) |
| graphify | 파일 수천 개 규모 코드베이스 탐색 | 조건부 | 그 저장소에서 있음·없음 토큰 실측 후 판단<br>보안 자동 감사 D등급 | 2026-09-26 | [#127](https://github.com/yanos0218/AI/issues/127) |
| 에이전트 팀 | 병렬 교차 검증 리서치가 반복될 때 | 조건부 시험만 | 계획 모드 팀원 약 7배 토큰<br>Windows·VS Code 제약 | 2026-09-27 | [#130](https://github.com/yanos0218/AI/issues/130) |

## Claude Code 내장 기능(설치 불필요)

| 기능 | 이럴 때 | 확인일 | 근거 |
| --- | --- | --- | --- |
| `/context`, `/usage` | 무엇이 토큰을 차지하는지 볼 때 | 2026-09-26 | [#128](https://github.com/yanos0218/AI/issues/128) |
| `/model opusplan` | 계획은 Opus, 실행은 Sonnet으로 나눌 때 | 2026-09-26 | [#129](https://github.com/yanos0218/AI/issues/129) |
| `/effort` | 생각 토큰을 줄일 때 | 2026-09-26 | [#129](https://github.com/yanos0218/AI/issues/129) |
| Concise 출력 스타일 | 답변을 짧게 할 때(Proactive 스타일은 쓰지 않음) | 2026-09-26 | [#129](https://github.com/yanos0218/AI/issues/129) |
| `CLAUDE_CODE_SUBAGENT_MODEL` | 서브에이전트 기본 모델을 정할 때 | 2026-09-26 | [#129](https://github.com/yanos0218/AI/issues/129) |
| plan mode, `/rewind` | 바꾸기 전에 계획 확인, 되돌리기 | 2026-09-26 | [#129](https://github.com/yanos0218/AI/issues/129) |

## 쓰지 말 것

| 도구 | 이유 | 확인일 | 근거 |
| --- | --- | --- | --- |
| Find Skills(skills.sh 카탈로그 자동 설치) | 카탈로그 무심사, 공급망 공격 사고(2026-07~08) | 2026-09-26 | [#127](https://github.com/yanos0218/AI/issues/127) |
| markitdown-mcp | 로컬 파일 권한 문제를 제작사가 고치지 않음 | 2026-09-26 | [#127](https://github.com/yanos0218/AI/issues/127) |
| pdftotext로 PDF 표 읽기 | 표의 행이 섞여 틀린 값이 조용히 만들어짐 | 2026-09-26 | [#127](https://github.com/yanos0218/AI/issues/127) |
| taste-skill | 사람 기여자 사실상 1명, 기존 디자인 스킬과 중복 | 2026-09-26 | [#127](https://github.com/yanos0218/AI/issues/127) |
| headroom | 대화형 세션 절감 15~20%로 광고보다 작고 캐시를 깰 수 있음 | 2026-09-26 | [#127](https://github.com/yanos0218/AI/issues/127) |
| chop, contextzip | 제작자 자체 측정뿐(미검증) | 2026-09-26 | [#127](https://github.com/yanos0218/AI/issues/127) |
| OpenTelemetry 모니터링 | 개인에겐 수집 서버 설정 부담 | 2026-09-26 | [#129](https://github.com/yanos0218/AI/issues/129) |
