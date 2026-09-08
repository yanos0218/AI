# 새 Windows 기기에서 VS Code 확장·설정을 한 번에 맞추는 스크립트.
# 평소 동기화는 VS Code Settings Sync가 담당하고, 이 스크립트는 "처음 세팅"과 "Sync가 꺼진 기기" 용도다.
# 실행: pwsh -File base/vscode/install.ps1
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
  Write-Error "VS Code CLI(code)가 PATH에 없습니다. VS Code에서 'Shell Command: Install code command' 실행 후 다시 시도하세요."
}

Write-Host "== 확장 설치"
Get-Content (Join-Path $here "extensions.txt") | Where-Object { $_ -and -not $_.StartsWith("#") } | ForEach-Object {
  code --install-extension $_ --force | Out-Null
  Write-Host "  $_"
}

$target = Join-Path $env:APPDATA "Code\User\settings.json"
if (Test-Path $target) {
  Write-Host "== settings.json 이미 있음 → 덮어쓰지 않음. 필요한 키는 base/vscode/settings.json에서 직접 옮기세요: $target"
} else {
  New-Item -ItemType Directory -Force (Split-Path $target) | Out-Null
  Copy-Item (Join-Path $here "settings.json") $target
  Write-Host "== settings.json 복사 완료: $target"
}

Write-Host "== 끝. VS Code를 다시 열고 Settings Sync(계정 메뉴 → Backup and Sync Settings)를 켜세요."
