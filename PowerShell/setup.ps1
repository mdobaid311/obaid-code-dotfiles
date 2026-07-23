<#
.SYNOPSIS
    One-shot bootstrap for the Obaid PowerShell environment.
.DESCRIPTION
    Installs the CLI toolchain (oh-my-posh, zoxide, fzf, eza, bat, fd, ripgrep,
    fastfetch, lazygit), the JetBrainsMono Nerd Font, the PowerShell modules
    (Terminal-Icons, PSFzf, CompletionPredictor), and points $PROFILE at the
    profile in this repo. Idempotent — safe to re-run any time.
.NOTES
    Run from the repo:  .\setup.ps1
#>
#Requires -Version 7

$ErrorActionPreference = 'Continue'
$repoProfile = Join-Path $PSScriptRoot 'Microsoft.PowerShell_profile.ps1'

function Step { param([string]$Msg) Write-Host "`n━━ $Msg" -ForegroundColor Cyan }
function Ok   { param([string]$Msg) Write-Host "   ✓ $Msg" -ForegroundColor Green }
function Skip { param([string]$Msg) Write-Host "   ○ $Msg" -ForegroundColor DarkGray }

if (-not (Get-Command winget -ErrorAction Ignore)) {
    Write-Error 'winget is required but not found. Install "App Installer" from the Microsoft Store first.'
    return
}

# ── CLI toolchain ─────────────────────────────────────────────────────────────
Step 'Installing CLI tools (winget)'
$packages = @(
    @{ Id = 'JanDeDobbeleer.OhMyPosh';      Cmd = 'oh-my-posh' }
    @{ Id = 'ajeetdsouza.zoxide';           Cmd = 'zoxide' }
    @{ Id = 'junegunn.fzf';                 Cmd = 'fzf' }
    @{ Id = 'eza-community.eza';            Cmd = 'eza' }
    @{ Id = 'sharkdp.bat';                  Cmd = 'bat' }
    @{ Id = 'sharkdp.fd';                   Cmd = 'fd' }
    @{ Id = 'BurntSushi.ripgrep.MSVC';      Cmd = 'rg' }
    @{ Id = 'Fastfetch-cli.Fastfetch';      Cmd = 'fastfetch' }
    @{ Id = 'JesseDuffield.lazygit';        Cmd = 'lazygit' }
)
foreach ($p in $packages) {
    if (Get-Command $p.Cmd -ErrorAction Ignore) { Skip "$($p.Cmd) already installed"; continue }
    winget install --id $p.Id -e --silent --accept-package-agreements --accept-source-agreements --disable-interactivity | Out-Null
    Ok $p.Id
}

# ── Nerd Font ─────────────────────────────────────────────────────────────────
Step 'Installing JetBrainsMono Nerd Font'
[void][System.Reflection.Assembly]::LoadWithPartialName('System.Drawing')
$fonts = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name
if ($fonts -match 'JetBrainsMono N(erd )?F') {
    Skip 'font already installed'
} else {
    winget install --id DEVCOM.JetBrainsMonoNerdFont -e --silent --accept-package-agreements --accept-source-agreements | Out-Null
    Ok "JetBrainsMono Nerd Font — set your terminal font to 'JetBrainsMono NF' for icons"
}

# ── PowerShell modules ────────────────────────────────────────────────────────
Step 'Installing PowerShell modules'
foreach ($m in 'Terminal-Icons', 'PSFzf', 'CompletionPredictor') {
    if (Get-Module -ListAvailable $m) { Skip "$m already installed"; continue }
    Install-Module -Name $m -Scope CurrentUser -Force -SkipPublisherCheck
    Ok $m
}

# ── Wire up $PROFILE → this repo ──────────────────────────────────────────────
Step 'Linking $PROFILE to this repo'
$profileDir = Split-Path $PROFILE
if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }

$stub = ". `"$repoProfile`""
if ((Test-Path $PROFILE) -and (Get-Content $PROFILE -Raw).Trim() -ne $stub) {
    Copy-Item $PROFILE "$PROFILE.bak" -Force
    Ok "existing profile backed up to $PROFILE.bak"
}
Set-Content -Path $PROFILE -Value $stub
Ok "$PROFILE → $repoProfile"

Write-Host "`n Done. Restart your terminal (and set its font to 'JetBrainsMono Nerd Font')." -ForegroundColor Magenta
Write-Host "   Then type " -NoNewline; Write-Host "shortcuts" -ForegroundColor Cyan -NoNewline; Write-Host " to see everything you can do.`n"
