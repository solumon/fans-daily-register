#requires -Version 5.1
$ErrorActionPreference = "Stop"

$UserHome = if ($HOME) { $HOME } else { $env:USERPROFILE }
$Api = if ($env:TIMESHEET_API) { $env:TIMESHEET_API } else { "https://timesheet-manage.up366demo.cn" }
$Cookie = if ($env:TIMESHEET_COOKIE) { $env:TIMESHEET_COOKIE } else { Join-Path $env:TEMP "fans-timesheet-cookies.txt" }
$EmailFile = if ($env:TIMESHEET_EMAIL_FILE) { $env:TIMESHEET_EMAIL_FILE } else { Join-Path $UserHome ".config\fans-daily-register\email" }
$AppName = "timesheet-html"

function Write-Utf8NoBom([string]$Path, [string]$Text) {
  $enc = New-Object System.Text.UTF8Encoding $false
  [System.IO.File]::WriteAllText($Path, $Text, $enc)
}

function Usage {
  [Console]::Error.WriteLine("Usage: timesheet.ps1 email | login [email] | me | daily [YYYY-MM-DD] | submit <json> | range <json>")
  exit 2
}

function Invoke-Timesheet([string]$Path, [string]$Data = "{}") {
  $tmp = [System.IO.Path]::GetTempFileName()
  Write-Utf8NoBom $tmp $Data
  try {
    & curl.exe -sS "$Api$Path" `
      -H "Content-Type: application/json" `
      -H "X-App-Name: $AppName" `
      -b $Cookie -c $Cookie `
      --data-binary "@$tmp"
  } finally {
    Remove-Item -Force $tmp -ErrorAction SilentlyContinue
  }
}

function Read-SavedEmail {
  if ($env:TIMESHEET_EMAIL) { return $env:TIMESHEET_EMAIL.Trim() }
  if (Test-Path $EmailFile) { return ((Get-Content -Raw $EmailFile) -replace "\s", "") }
  return ""
}

function Save-Email([string]$Email) {
  $dir = Split-Path $EmailFile -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
  Write-Utf8NoBom $EmailFile $Email
}

function Test-JsonOk([string]$Text) {
  $obj = $Text | ConvertFrom-Json
  return ($obj.code -eq 0)
}

$Cmd = $args[0]
$Arg = $args[1]

switch ($Cmd) {
  "email" {
    $saved = Read-SavedEmail
    if (-not $saved) {
      [Console]::Error.WriteLine("NO_EMAIL")
      exit 3
    }
    Write-Output $saved
  }
  "login" {
    $email = if ($Arg) { $Arg } else { Read-SavedEmail }
    if (-not $email) {
      [Console]::Error.WriteLine("NO_EMAIL")
      exit 3
    }
    $body = (@{ userName = $email } | ConvertTo-Json -Compress)
    $resp = Invoke-Timesheet "/front/auth/login" $body
    Write-Output $resp
    if (Test-JsonOk $resp) { Save-Email $email } else { exit 1 }
  }
  "me" {
    Invoke-Timesheet "/front/auth/me" "{}"
  }
  "daily" {
    $day = if ($Arg) { $Arg } else { Get-Date -Format "yyyy-MM-dd" }
    $body = (@{ workDate = $day } | ConvertTo-Json -Compress)
    Invoke-Timesheet "/front/timesheet/daily" $body
  }
  { $_ -in "submit", "range" } {
    if (-not $Arg) { Usage }
    $path = if ($Cmd -eq "range") { "/front/timesheet/range" } else { "/front/timesheet/submit" }
    Invoke-Timesheet $path $Arg
  }
  default { Usage }
}
