#requires -Version 5.1
# Install into ~/.agents/skills. Link Cursor / Codex / Hermes only if present.
#
# Remote (no clone): irm https://raw.githubusercontent.com/solumon/fans-daily-register/master/scripts/install.ps1 | iex
# Local (dev):       powershell -NoProfile -File scripts/install.ps1
$ErrorActionPreference = "Stop"

$Name = "fans-daily-register"
$RepoSlug = "solumon/fans-daily-register"
$Ref = if ($env:FANS_DAILY_REGISTER_REF) { $env:FANS_DAILY_REGISTER_REF } else { "master" }
$UserHome = if ($HOME) { $HOME } else { $env:USERPROFILE }
$Dest = Join-Path $UserHome ".agents\skills\$Name"
$ThisScript = $MyInvocation.MyCommand.Path
$FetchTmp = $null
$Root = $null

function New-FetchTmp {
    if ($script:FetchTmp -and (Test-Path $script:FetchTmp)) {
        Remove-Item -Recurse -Force $script:FetchTmp
    }
    $script:FetchTmp = Join-Path ([System.IO.Path]::GetTempPath()) (
        $Name + "-" + [guid]::NewGuid().ToString("N")
    )
    New-Item -ItemType Directory -Force -Path $script:FetchTmp | Out-Null
}

function Find-SkillRoot {
    $dirs = @(Get-ChildItem -LiteralPath $script:FetchTmp -Directory -ErrorAction SilentlyContinue)
    foreach ($d in $dirs) {
        if (Test-Path (Join-Path $d.FullName "SKILL.md")) {
            return $d.FullName
        }
    }
    if (Test-Path (Join-Path $script:FetchTmp "SKILL.md")) {
        return $script:FetchTmp
    }
    return $null
}

try {
    if ($ThisScript -and (Test-Path -LiteralPath $ThisScript)) {
        $candidate = Split-Path (Split-Path $ThisScript -Parent) -Parent
        if (Test-Path (Join-Path $candidate "SKILL.md")) {
            $Root = $candidate
        }
    }

    if (-not $Root) {
        $fetched = $false
        try {
            Write-Host "==> Fetching ${RepoSlug}@${Ref} via curl (no git clone)"
            New-FetchTmp
            $zip = Join-Path $FetchTmp "src.zip"
            $url = "https://github.com/$RepoSlug/archive/refs/heads/$Ref.zip"
            curl.exe -fsSL $url -o $zip
            if ($LASTEXITCODE -eq 0 -and (Test-Path $zip)) {
                Expand-Archive -LiteralPath $zip -DestinationPath $FetchTmp
                $Root = Find-SkillRoot
                if ($Root) { $fetched = $true }
            }
        } catch { $fetched = $false }
        if (-not $fetched) { Write-Host "  curl archive failed, trying next" }

        if (-not $fetched -and (Get-Command gh -ErrorAction SilentlyContinue)) {
            try {
                Write-Host "==> Fetching ${RepoSlug}@${Ref} via gh"
                New-FetchTmp
                $tar = Join-Path $FetchTmp "src.tar.gz"
                gh api "repos/$RepoSlug/tarball/$Ref" --output $tar
                if ($LASTEXITCODE -eq 0 -and (Test-Path $tar)) {
                    tar -xzf $tar -C $FetchTmp
                    $Root = Find-SkillRoot
                    if ($Root) { $fetched = $true }
                }
            } catch { $fetched = $false }
            if (-not $fetched) { Write-Host "  gh tarball failed, trying next" }
        }

        if (-not $fetched -and (Get-Command git -ErrorAction SilentlyContinue)) {
            try {
                Write-Host "==> Fetching ${RepoSlug}@${Ref} via temporary shallow clone"
                New-FetchTmp
                git clone --depth 1 --branch $Ref "https://github.com/${RepoSlug}.git" (Join-Path $FetchTmp "src")
                $Root = Find-SkillRoot
                if ($Root) { $fetched = $true }
            } catch { $fetched = $false }
        }

        if (-not $fetched -or -not $Root) {
            throw "cannot fetch ${RepoSlug}@${Ref}"
        }
    }

    Write-Host "==> Installing skill into $Dest"
    New-Item -ItemType Directory -Force -Path (Split-Path $Dest -Parent) | Out-Null
    if (Test-Path $Dest) { Remove-Item -Recurse -Force $Dest }
    New-Item -ItemType Directory -Force -Path $Dest | Out-Null

    Get-ChildItem -Force $Root | Where-Object {
        $_.Name -notin @(".git", ".cursor", "README.md", ".DS_Store")
    } | ForEach-Object {
        Copy-Item -Recurse -Force $_.FullName (Join-Path $Dest $_.Name)
    }

    $scriptsDest = Join-Path $Dest "scripts"
    foreach ($installer in @("install.sh", "install.ps1")) {
        $p = Join-Path $scriptsDest $installer
        if (Test-Path $p) { Remove-Item -Force $p }
    }

    function Link-IfHost([string]$HostRoot, [string]$SkillsDir, [string]$Label) {
        if (-not (Test-Path $HostRoot)) {
            Write-Host "  skip $Label（未安装，无 $HostRoot）"
            return
        }
        New-Item -ItemType Directory -Force -Path $SkillsDir | Out-Null
        $link = Join-Path $SkillsDir $Name
        if (Test-Path $link) { Remove-Item -Recurse -Force $link }
        cmd /c "mklink /J `"$link`" `"$Dest`"" | Out-Null
        Write-Host "  link $link"
    }

    Link-IfHost (Join-Path $UserHome ".cursor") (Join-Path $UserHome ".cursor\skills") "Cursor"
    Link-IfHost (Join-Path $UserHome ".codex") (Join-Path $UserHome ".codex\skills") "Codex"
    Link-IfHost (Join-Path $UserHome ".hermes") (Join-Path $UserHome ".hermes\skills") "Hermes"

    if (-not (Test-Path (Join-Path $Dest "SKILL.md"))) { Write-Error "SKILL.md missing after copy"; exit 1 }
    if (-not (Test-Path (Join-Path $Dest "scripts\timesheet.ps1"))) { Write-Error "timesheet.ps1 missing after copy"; exit 1 }
    if (Test-Path (Join-Path $Dest "scripts\install.ps1")) { Write-Error "install.ps1 should not be copied"; exit 1 }

    Write-Host "Install complete."
    Write-Host "Skill: $Dest\SKILL.md"
    Write-Host "任何会读 ~/.agents/skills 的 Agent 都能用；没有 Cursor/Codex/Hermes 也不影响。"
}
finally {
    if ($FetchTmp -and (Test-Path $FetchTmp)) {
        Remove-Item -Recurse -Force $FetchTmp
    }
}
