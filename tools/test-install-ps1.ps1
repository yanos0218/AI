# tools/install.ps1 test for CI (Windows PowerShell 5.1) - Issue #249
#   powershell -File tools/test-install-ps1.ps1   (run from the repo root)
# ASCII only on purpose: Windows PowerShell 5.1 reads a BOM-less UTF-8 .ps1 as ANSI and garbles non-ASCII text.
# So this test judges by state (files, settings.json content), never by Korean messages.
# Scenario A runs everywhere (bash hidden), scenario B needs the real Git for Windows + Python of the runner.
$ErrorActionPreference = 'Stop'
$repo = (Get-Location).Path
$tmp = Join-Path ([IO.Path]::GetTempPath()) ('ccfg-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
$script:pass = 0
$script:fail = 0
function Ok($m) { $script:pass++; Write-Host "  ok   $m" }
function Bad($m) { $script:fail++; Write-Host "  FAIL $m" }
function Check($cond, $m) { if ($cond) { Ok $m } else { Bad $m } }

$zip = Join-Path $tmp 'pkg.zip'
& git archive --format=zip --prefix=AI-test/ HEAD -o $zip
if ($LASTEXITCODE -ne 0) { throw 'git archive failed' }
# the installer is run the way users run it (iex of the decoded text), not as a .ps1 file
$installer = [IO.File]::ReadAllText((Join-Path (Join-Path $repo 'tools') 'install.ps1'), (New-Object System.Text.UTF8Encoding($false)))

function Set-Env($name, $value) { [Environment]::SetEnvironmentVariable($name, $value, 'Process') }

function Invoke-Installer($dir, $isolate) {
  $names = @('CLAUDE_CONFIG_DIR', 'CLAUDE_CONFIG_ZIP', 'CLAUDE_CONFIG_ASSUME', 'ProgramFiles', 'ProgramFiles(x86)', 'LOCALAPPDATA', 'Path')
  $saved = @{}
  foreach ($n in $names) { $saved[$n] = [Environment]::GetEnvironmentVariable($n, 'Process') }
  try {
    # forward slashes so the Git Bash side of install.sh gets a path it understands
    Set-Env 'CLAUDE_CONFIG_DIR' ($dir -replace '\\', '/')
    Set-Env 'CLAUDE_CONFIG_ZIP' $zip
    Set-Env 'CLAUDE_CONFIG_ASSUME' 'no'
    if ($isolate) {
      # hide Git for Windows: installer looks at ProgramFiles, LOCALAPPDATA and git.exe on PATH
      $empty = Join-Path $tmp 'empty'
      New-Item -ItemType Directory -Force -Path $empty | Out-Null
      Set-Env 'ProgramFiles' $empty
      Set-Env 'ProgramFiles(x86)' $empty
      Set-Env 'LOCALAPPDATA' $empty
      $sep = [IO.Path]::PathSeparator
      $kept = @($saved['Path'] -split [regex]::Escape($sep)) | Where-Object { $_ -and ($_ -notmatch '[\\/]Git([\\/]|$)') }
      Set-Env 'Path' ($kept -join $sep)
    }
    return (Invoke-Expression $installer *>&1 | Out-String)
  } finally {
    foreach ($n in $names) { Set-Env $n $saved[$n] }
  }
}

function Read-Settings($dir) {
  $p = Join-Path $dir 'settings.json'
  if (-not (Test-Path $p)) { return $null }
  $bytes = [IO.File]::ReadAllBytes($p)
  $bom = ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191)
  $obj = [Text.Encoding]::UTF8.GetString($bytes) | ConvertFrom-Json
  return @{ Bom = $bom; Obj = $obj }
}

Write-Host "PowerShell $($PSVersionTable.PSVersion)"

Write-Host '== A: no bash (phase 1 only)'
$a = Join-Path $tmp 'a'
$null = Invoke-Installer $a $true
Check ((Test-Path (Join-Path $a 'CLAUDE.md')) -and (Test-Path (Join-Path (Join-Path $a 'skills') 'config-update')) -and (Test-Path (Join-Path (Join-Path $a 'hooks') 'git-guardrails.sh'))) 'CLAUDE.md, skills and hooks files copied'
$s = Read-Settings $a
Check ($null -ne $s) 'settings.json created'
if ($s) {
  Check (-not $s.Bom) 'settings.json has no BOM'
  $props = @($s.Obj.PSObject.Properties | ForEach-Object { $_.Name })
  Check (($props -notcontains 'hooks') -and ($props -notcontains 'statusLine')) 'settings.json has no hooks and no statusLine'
  Check (@($s.Obj.permissions.allow).Count -gt 0) 'settings.json keeps permissions.allow'
}

if ([Environment]::OSVersion.Platform -eq 'Win32NT') {
  Write-Host '== B: real Git for Windows + Python (phase 2)'
  $b = Join-Path $tmp 'b'
  $null = Invoke-Installer $b $false
  $s = Read-Settings $b
  Check ($null -ne $s) 'settings.json created'
  if ($s) {
    $props = @($s.Obj.PSObject.Properties | ForEach-Object { $_.Name })
    Check (($props -contains 'hooks') -and ($props -contains 'statusLine')) 'hooks and statusLine merged by install.sh'
  }
  $vf = Join-Path $b '.claude-config-version'
  $lines = if (Test-Path $vf) { [IO.File]::ReadAllLines($vf) } else { @() }
  Check (($lines.Count -ge 2) -and ($lines[1] -eq 'local')) 'version file records the release tag (CLAUDE_CONFIG_BASE_VER)'
} else {
  Write-Host '== B: skipped (not Windows)'
}

Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "result: $($script:pass) passed, $($script:fail) failed"
if ($script:fail -gt 0) { exit 1 }
