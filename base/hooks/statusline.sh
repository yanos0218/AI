#!/usr/bin/env bash
# Claude Code 상태줄: [모델] 디렉터리 (브랜치) | ▓▓▓░░ 37% | $0.12
# stdin으로 세션 JSON을 받는다. jq → python → node 순으로 있는 것을 쓴다(Windows Git Bash엔 jq가 없는 경우가 많음).
# 필드는 탭으로 구분한다 — 모델명("Fable 5.1")과 경로에 공백이 들어갈 수 있어서.
input="$(cat)"

if command -v jq >/dev/null 2>&1; then
  fields="$(printf '%s' "$input" | jq -r '[.model.display_name // "?", .workspace.current_dir // "", (.context_window.used_percentage // 0 | floor), (.cost.total_cost_usd // 0)] | @tsv')"
elif command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1; then
  py="$(command -v python3 || command -v python)"
  fields="$(printf '%s' "$input" | "$py" -c '
import json,sys
d=json.load(sys.stdin)
cw=d.get("context_window") or {}
print(d.get("model",{}).get("display_name") or "?", d.get("workspace",{}).get("current_dir") or "", int(cw.get("used_percentage") or 0), (d.get("cost") or {}).get("total_cost_usd") or 0, sep="\t")')"
elif command -v node >/dev/null 2>&1; then
  fields="$(printf '%s' "$input" | node -e '
let s="";process.stdin.on("data",c=>s+=c).on("end",()=>{const d=JSON.parse(s);
console.log([d.model?.display_name??"?", d.workspace?.current_dir??"", Math.floor(d.context_window?.used_percentage??0), d.cost?.total_cost_usd??0].join("\t"))})')"
else
  echo "[Claude]"; exit 0
fi

IFS=$'\t' read -r model dir pct cost <<<"$fields"
pct=${pct%%.*}; pct=${pct:-0}

branch="$(git -C "$dir" branch --show-current 2>/dev/null)"
filled=$(( pct / 10 )); bar=""
for ((i=0;i<10;i++)); do if (( i < filled )); then bar+="▓"; else bar+="░"; fi; done

# 70% 넘으면 노란색, 85% 넘으면 빨간색 — 컴팩션 전에 /clear 또는 /compact 판단용
if (( pct >= 85 )); then color=$'\e[31m'; elif (( pct >= 70 )); then color=$'\e[33m'; else color=$'\e[32m'; fi
reset=$'\e[0m'

printf '[%s] %s%s | %s%s %s%%%s | $%.2f\n' "$model" "$(basename "$dir")" "${branch:+ ($branch)}" "$color" "$bar" "$pct" "$reset" "$cost"
