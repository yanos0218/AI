# Claude Code 설정(base/)을 Windows에 설치한다. bash·git·python이 없어도 PowerShell만으로 시작한다(Issue #247).
#   irm https://raw.githubusercontent.com/yanos0218/AI/main/tools/install.ps1 | iex
# 1단계(PowerShell만): 최신 릴리즈 zip에서 base/를 꺼내 ~/.claude에 복사, settings.json이 없으면 훅을 뺀 값으로 생성
# 2단계(bash·python 있을 때): zip 안의 tools/install.sh로 훅 포함 전체 병합. 없으면 동의를 받아 winget으로 설치
# 환경변수(선택, 시험·무인 실행용)
#   CLAUDE_CONFIG_DIR     설치 대상 폴더(기본 %USERPROFILE%\.claude)
#   CLAUDE_CONFIG_ZIP     내려받지 않고 쓸 로컬 zip 경로
#   CLAUDE_CONFIG_ASSUME  yes 또는 no. 프로그램 설치 질문에 자동으로 답함
# iex로 실행되므로 exit를 쓰지 않는다(사용자의 PowerShell 창이 닫힘).

function Install-ClaudeConfig {
  $ErrorActionPreference = 'Stop'
  $ProgressPreference = 'SilentlyContinue'
  try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}

  $ts = Get-Date -Format 'yyyyMMddHHmmss'
  $claude = $env:CLAUDE_CONFIG_DIR
  if (-not $claude) { $claude = Join-Path $env:USERPROFILE '.claude' }
  $source = Join-Path $claude '.config-source'
  $backupRoot = Join-Path (Join-Path $claude 'backups') (Join-Path 'claude-config' $ts)
  $utf8 = New-Object System.Text.UTF8Encoding($false)

  function Say($m) { Write-Host $m }

  function Get-DirSig($p) {
    if (-not (Test-Path $p)) { return '' }
    $b = (Resolve-Path $p).Path
    $items = Get-ChildItem $p -Recurse -File | Where-Object { $_.FullName -notmatch '__pycache__' } | Sort-Object FullName
    return (($items | ForEach-Object { $_.FullName.Substring($b.Length) + ':' + (Get-FileHash $_.FullName -Algorithm SHA256).Hash }) -join '|')
  }

  function Copy-OneFile($src, $dst) {
    if (Test-Path $dst) {
      if ((Get-FileHash $src -Algorithm SHA256).Hash -eq (Get-FileHash $dst -Algorithm SHA256).Hash) { return }
      $bk = Join-Path $backupRoot ([IO.Path]::GetFileName($dst))
      New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
      Copy-Item $dst $bk -Force
    }
    New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
    Copy-Item $src $dst -Force
  }

  function Copy-Files($srcDir, $dstDir, $filter) {
    if (-not (Test-Path $srcDir)) { return }
    Get-ChildItem $srcDir -File -Filter $filter | ForEach-Object { Copy-OneFile $_.FullName (Join-Path $dstDir $_.Name) }
  }

  function Confirm-Install($what) {
    $a = $env:CLAUDE_CONFIG_ASSUME
    if ($a -eq 'yes') { return $true }
    if ($a -eq 'no') { return $false }
    $r = Read-Host "$what 설치할까요? [Y/n]"
    return ($r -eq '' -or $r -match '^[Yy]')
  }

  function Update-SessionPath {
    $m = [Environment]::ExpandEnvironmentVariables([Environment]::GetEnvironmentVariable('Path', 'Machine'))
    $u = [Environment]::ExpandEnvironmentVariables([Environment]::GetEnvironmentVariable('Path', 'User'))
    $env:Path = $env:Path + ';' + $m + ';' + $u
  }

  # 'bash'라는 이름은 WSL(System32\bash.exe)일 수 있어 쓰지 않고 Git 설치 위치에서만 찾는다
  function Find-GitBash {
    # 일부 환경변수는 없을 수 있어(32비트 Windows 등) 값이 있는 것만 쓴다
    $bases = @(
      @($env:ProgramFiles, 'Git\bin\bash.exe'),
      @(${env:ProgramFiles(x86)}, 'Git\bin\bash.exe'),
      @($env:LOCALAPPDATA, 'Programs\Git\bin\bash.exe')
    )
    foreach ($b in $bases) {
      if (-not $b[0]) { continue }
      $c = Join-Path $b[0] $b[1]
      if (Test-Path $c) { return $c }
    }
    $g = Get-Command git.exe -ErrorAction SilentlyContinue
    if ($g) {
      $c = Join-Path (Split-Path (Split-Path $g.Source)) 'bin\bash.exe'
      if (Test-Path $c) { return $c }
    }
    return $null
  }

  # 스토어 별칭(실행하면 스토어가 열리는 가짜 python)을 거르려고 실제로 실행해 본다
  function Find-Python {
    foreach ($n in @('python', 'python3')) {
      $c = Get-Command $n -ErrorAction SilentlyContinue
      if (-not $c) { continue }
      try {
        $v = & $c.Source -c 'import sys;print(sys.version_info[0])' 2>$null
        if ($LASTEXITCODE -eq 0 -and "$v".Trim() -eq '3') { return $c.Source }
      } catch {}
    }
    # 방금 설치한 Python은 스토어 별칭(WindowsApps)보다 PATH 뒤에 붙어 이름으로는 못 찾으므로 설치 위치에서도 찾는다
    foreach ($b in @((Join-Path $env:LOCALAPPDATA 'Programs\Python'), (Join-Path $env:ProgramFiles 'Python3*'))) {
      if (-not $b) { continue }
      foreach ($f in @(Get-ChildItem -Path $b -Filter 'python.exe' -Recurse -Depth 2 -ErrorAction SilentlyContinue)) {
        try {
          $v = & $f.FullName -c 'import sys;print(sys.version_info[0])' 2>$null
          if ($LASTEXITCODE -eq 0 -and "$v".Trim() -eq '3') { return $f.FullName }
        } catch {}
      }
    }
    return $null
  }

  function Install-WithWinget($id, $name) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { Say "  winget이 없음"; return $false }
    Say "  $name 설치 중(winget)..."
    try { & winget install --id $id -e --accept-package-agreements --accept-source-agreements | Out-Host } catch { Say "  winget 실행 실패($($_.Exception.Message))"; return $false }
    if ($LASTEXITCODE -ne 0) { Say "  winget 설치 실패(종료 코드 $LASTEXITCODE)"; return $false }
    return $true
  }

  # 설치 파일을 받아 무음 설치한다. 권한 창(UAC)은 사용자가 화면에서 결정하고, 거절하면 실패로 돌려준다
  function Install-Exe($name, $url, $expectSha, $installArgs) {
    $dl = Join-Path ([IO.Path]::GetTempPath()) ('claude-config-dl-' + $ts)
    New-Item -ItemType Directory -Force -Path $dl | Out-Null
    $exe = Join-Path $dl ([IO.Path]::GetFileName($url))
    Say "  $name 설치 파일 내려받는 중: $url"
    Invoke-WebRequest -Uri $url -OutFile $exe -UseBasicParsing -UserAgent 'claude-config-installer'
    if ($expectSha) {
      $got = (Get-FileHash $exe -Algorithm SHA256).Hash
      if ($got -ne $expectSha) { Remove-Item $exe -Force -ErrorAction SilentlyContinue; Say "  sha256이 달라 설치하지 않음"; return $false }
      Say '  sha256 일치 확인'
    }
    Say "  $name 설치 중(권한 창이 뜨면 화면에서 선택해 주세요)..."
    try { $pr = Start-Process -FilePath $exe -ArgumentList $installArgs -Wait -PassThru } catch { Say "  $name 설치를 시작하지 못함(권한 창을 거절했거나 실행이 막힘)"; return $false } finally { Remove-Item $dl -Recurse -Force -ErrorAction SilentlyContinue }
    if ($pr.ExitCode -ne 0) { Say "  $name 설치 실패(종료 코드 $($pr.ExitCode))"; return $false }
    return $true
  }

  function Install-Direct($kind) {
    $arch = if ($env:PROCESSOR_ARCHITEW6432) { $env:PROCESSOR_ARCHITEW6432 } else { $env:PROCESSOR_ARCHITECTURE }
    if ($arch -ne 'AMD64') { Say "  직접 설치는 64비트(x64) Windows만 지원함(현재 $arch)"; return $false }
    if ($kind -eq 'git') {
      $rel = Invoke-RestMethod -Uri 'https://api.github.com/repos/git-for-windows/git/releases/latest' -UserAgent 'claude-config-installer'
      $asset = $rel.assets | Where-Object { $_.name -match '^Git-.*-64-bit\.exe$' } | Select-Object -First 1
      if (-not $asset -or -not $asset.digest -or $asset.digest -notmatch '^sha256:') { Say '  Git 설치 파일 또는 sha256 정보를 찾지 못해 설치하지 않음'; return $false }
      return (Install-Exe 'Git for Windows' $asset.browser_download_url ($asset.digest -replace '^sha256:', '').ToUpper() @('/VERYSILENT', '/NORESTART', '/SUPPRESSMSGBOXES'))
    }
    # python.org는 해시를 따로 알려주지 않아 주소 고정과 HTTPS에 의존한다
    return (Install-Exe 'Python 3' 'https://www.python.org/ftp/python/3.12.10/python-3.12.10-amd64.exe' $null @('/quiet', 'InstallAllUsers=0', 'PrependPath=1', 'Include_launcher=0', 'Include_test=0'))
  }

  # winget이 되면 쓰고, 안 되면 직접 내려받아 설치한다
  function Install-Program($wingetId, $name, $kind) {
    # 함수 안 외부 프로그램 출력이 반환값에 섞이므로 결과는 -eq $true로만 판정한다
    if ((Install-WithWinget $wingetId $name) -eq $true) { Update-SessionPath; return $true }
    Say "  winget을 쓸 수 없어 $name 설치 파일을 직접 받음"
    try { $ok = Install-Direct $kind } catch { Say "  직접 설치 실패($($_.Exception.Message))"; $ok = $false }
    if ($ok) { Update-SessionPath }
    return $ok
  }

  try {
    Say "== 대상: $claude"
    New-Item -ItemType Directory -Force -Path $claude | Out-Null

    # 1. 설정 패키지 받기 (저장소 없이 최신 릴리즈 zip만 사용)
    $work = Join-Path ([IO.Path]::GetTempPath()) ("claude-config-" + $ts)
    New-Item -ItemType Directory -Force -Path $work | Out-Null
    $zip = $env:CLAUDE_CONFIG_ZIP
    $tag = 'local'
    if (-not $zip) {
      $rel = Invoke-RestMethod -Uri 'https://api.github.com/repos/yanos0218/AI/releases/latest' -UserAgent 'claude-config-installer'
      $tag = $rel.tag_name
      $zip = Join-Path $work 'pkg.zip'
      Say "== 내려받기: $tag"
      Invoke-WebRequest -Uri "https://github.com/yanos0218/AI/archive/refs/tags/$tag.zip" -OutFile $zip -UserAgent 'claude-config-installer'
    }
    Expand-Archive -Path $zip -DestinationPath (Join-Path $work 'x') -Force
    $root = (Get-ChildItem (Join-Path $work 'x') -Directory | Select-Object -First 1).FullName
    if (-not (Test-Path (Join-Path $root 'base'))) { throw "패키지에 base/가 없음: $zip" }

    # 2. 다음 실행에서도 쓰도록 압축 푼 폴더를 설치 폴더 안에 둔다(저장소 clone과 겹치지 않음)
    if (Test-Path $source) { Remove-Item $source -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $source | Out-Null
    Copy-Item (Join-Path $root '*') $source -Recurse -Force
    Remove-Item $work -Recurse -Force
    $base = Join-Path $source 'base'

    # 3. 1단계 복사 (bash 불필요)
    Say '== 1단계: 파일 복사'
    Copy-OneFile (Join-Path $base 'claude-md\CLAUDE.md') (Join-Path $claude 'CLAUDE.md')
    Copy-Files (Join-Path $base 'hooks') (Join-Path $claude 'hooks') '*'
    Copy-Files (Join-Path $base 'agents') (Join-Path $claude 'agents') '*.md'
    Copy-Files (Join-Path $base 'rules') (Join-Path $claude 'rules') '*.md'
    Copy-Files (Join-Path $base 'claude-md-details') (Join-Path $claude 'claude-md-details') '*.md'
    Get-ChildItem (Join-Path $base 'skills') -Directory | Where-Object { $_.Name -notlike '_*' } | ForEach-Object {
      $dst = Join-Path (Join-Path $claude 'skills') $_.Name
      if ((Get-DirSig $_.FullName) -ne (Get-DirSig $dst)) {
        if (Test-Path $dst) {
          $bk = Join-Path (Join-Path $backupRoot 'skills') $_.Name
          New-Item -ItemType Directory -Force -Path (Split-Path $bk) | Out-Null
          Move-Item $dst $bk -Force
        }
        New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
        Copy-Item $_.FullName $dst -Recurse -Force
      }
    }
    Say '  CLAUDE.md, hooks 파일, agents, rules, claude-md-details, skills 복사 끝'

    # 4. settings.json - 없을 때만 훅과 상태줄을 뺀 값으로 만든다(bash 없이 훅을 등록하면 git-guardrails가 명령을 막을 수 있음)
    $settingsPath = Join-Path $claude 'settings.json'
    $hooksOn = $false
    if (-not (Test-Path $settingsPath)) {
      $ex = Get-Content (Join-Path $base 'settings.example.json') -Raw -Encoding UTF8 | ConvertFrom-Json
      foreach ($k in @('hooks', 'statusLine', '//')) { $ex.PSObject.Properties.Remove($k) }
      $dirs = @($claude, $source)
      if ($ex.permissions) { $ex.permissions | Add-Member -NotePropertyName additionalDirectories -NotePropertyValue $dirs -Force }
      [IO.File]::WriteAllText($settingsPath, ($ex | ConvertTo-Json -Depth 20), $utf8)
      Say '  settings.json 생성(훅·상태줄 제외)'
    } else {
      Say '  settings.json이 이미 있어 건드리지 않음. 훅 등록은 2단계에서 병합함'
    }

    # 5. 버전 표시 파일 - 2단계 install.sh가 덮어쓴다
    [IO.File]::WriteAllText((Join-Path $claude '.claude-config-version'), ($source + "`n" + $tag + "`n`n"), $utf8)

    # 6. 2단계: bash와 python이 있으면 훅까지 전체 병합
    $bash = Find-GitBash
    $py = Find-Python
    if (-not $bash -or -not $py) {
      $need = @()
      if (-not $bash) { $need += 'Git for Windows' }
      if (-not $py) { $need += 'Python 3' }
      Say ("== 2단계에 필요한 것이 없음: " + ($need -join ', '))
      if (Confirm-Install ((($need -join ', ') + '을(를)'))) {
        if (-not $bash) { [void](Install-Program 'Git.Git' 'Git for Windows' 'git') }
        if (-not $py) { [void](Install-Program 'Python.Python.3.12' 'Python 3' 'python') }
        $bash = Find-GitBash
        $py = Find-Python
      }
    }
    if ($bash -and $py) {
      Say '== 2단계: 훅 포함 전체 병합 (install.sh)'
      # install.sh가 쓰는 python이 스토어 별칭보다 먼저 잡히도록 찾은 python 위치를 PATH 앞에 둔다
      $env:Path = (Split-Path $py) + ';' + $env:Path
      Push-Location $source
      $env:CLAUDE_CONFIG_BASE_VER = $tag
      try { & $bash 'tools/install.sh'; $code = $LASTEXITCODE } finally { Pop-Location; Remove-Item Env:CLAUDE_CONFIG_BASE_VER -ErrorAction SilentlyContinue }
      if ($code -eq 0) {
        $hooksOn = $true
      } else { Say "  install.sh가 실패함(종료 코드 $code). 위 메시지 확인 후 같은 명령을 다시 실행함." }
    }

    if ($hooksOn) {
      Say '== 끝. 훅까지 설치됨. Claude Code를 새 세션으로 시작함.'
    } else {
      Say '== 1단계만 끝남. 훅과 상태줄은 꺼져 있고 git-guardrails 보호가 없음.'
      $miss = @(); if (-not $bash) { $miss += 'Git for Windows' }; if (-not $py) { $miss += 'Python 3' }
      if ($miss.Count) { Say ('   아직 못 찾은 것: ' + ($miss -join ', ') + ' (방금 설치했다면 새 PowerShell 창에서 같은 명령을 다시 실행하면 찾을 수 있음)') }
      Say '   Git for Windows(https://git-scm.com/download/win)와 Python 3(https://www.python.org/downloads/, 설치 때 Add to PATH 체크)를'
      Say '   직접 설치한 뒤 새 PowerShell 창에서 같은 명령을 다시 실행하면 훅까지 설치됨.'
    }
  } catch {
    Write-Host ("설치 실패: " + $_.Exception.Message) -ForegroundColor Red
    Write-Host '같은 명령을 다시 실행해도 안전함(이미 같은 파일은 건드리지 않고, 다른 파일은 백업 후 교체).'
  }
}

Install-ClaudeConfig
