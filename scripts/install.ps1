#requires -Version 5.1
# Install into ~/.agents/skills. Link Cursor / Codex / Hermes only if present.
$ErrorActionPreference = "Stop"

$Name = "fans-daily-register"
$UserHome = if ($HOME) { $HOME } else { $env:USERPROFILE }
$Root = Split-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) -Parent
$Dest = Join-Path $UserHome ".agents\skills\$Name"

if (-not (Test-Path (Join-Path $Root "SKILL.md"))) {
  Write-Error "missing $Root\SKILL.md"
  exit 1
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
