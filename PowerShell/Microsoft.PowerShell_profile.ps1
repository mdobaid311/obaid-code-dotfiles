###############################################################################
#
#   ██████╗ ██████╗  █████╗ ██╗██████╗     ██████╗ ██╗    ██╗███████╗██╗  ██╗
#  ██╔═══██╗██╔══██╗██╔══██╗██║██╔══██╗    ██╔══██╗██║    ██║██╔════╝██║  ██║
#  ██║   ██║██████╔╝███████║██║██║  ██║    ██████╔╝██║ █╗ ██║███████╗███████║
#  ██║   ██║██╔══██╗██╔══██║██║██║  ██║    ██╔═══╝ ██║███╗██║╚════██║██╔══██║
#  ╚██████╔╝██████╔╝██║  ██║██║██████╔╝    ██║     ╚███╔███╔╝███████║██║  ██║
#   ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝╚═════╝     ╚═╝      ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝
#
#  Fast · Futuristic · Elegant — lives in H:\Dotfiles\PowerShell
#  Type `shortcuts` to see every command, keybinding and setting.
#
###############################################################################

# ── Startup timer ────────────────────────────────────────────────────────────
$__profileStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# ── Environment ──────────────────────────────────────────────────────────────
$env:POWERSHELL_TELEMETRY_OPTOUT = '1'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$script:DotfilesRoot = Split-Path $PSScriptRoot -Parent   # H:\Dotfiles
$script:ThemeFile    = Join-Path $PSScriptRoot 'Themes\obaid.omp.json'

function script:Test-Cmd { param([string]$Name) [bool](Get-Command $Name -ErrorAction Ignore) }

# ── Editor ───────────────────────────────────────────────────────────────────
$script:EDITOR = foreach ($e in 'nvim', 'code', 'vim', 'notepad') {
    if (Test-Cmd $e) { $e; break }
}
$env:EDITOR = $script:EDITOR
Set-Alias -Name vim -Value $script:EDITOR -ErrorAction Ignore

# ══════════════════════════════════════════════════════════════════════════════
#  COMMAND REGISTRY — single source of truth that powers `shortcuts`
# ══════════════════════════════════════════════════════════════════════════════
$global:__ProfileCommands = [System.Collections.Generic.List[pscustomobject]]::new()
function script:Reg {
    param([string]$Name, [string]$Desc, [string]$Category, [string]$Usage = '')
    $global:__ProfileCommands.Add([pscustomobject]@{
        Name = $Name; Desc = $Desc; Category = $Category
        Usage = $(if ($Usage) { $Usage } else { $Name })
    })
}

# ══════════════════════════════════════════════════════════════════════════════
#  PROMPT — oh-my-posh with custom theme (fallback: minimal neon prompt)
# ══════════════════════════════════════════════════════════════════════════════
# Init scripts for oh-my-posh/zoxide are cached to disk — regenerating them
# spawns the binary (~500ms); dot-sourcing the cache is near-instant.
$script:CacheDir = Join-Path $env:LOCALAPPDATA 'obaid-pwsh-cache'
if (-not (Test-Path $script:CacheDir)) { New-Item -ItemType Directory -Path $script:CacheDir -Force | Out-Null }
function script:Get-CachedInit {
    param([string]$Name, [string]$Exe, [scriptblock]$Generator, [string[]]$AlsoWatch = @())
    $cache = Join-Path $script:CacheDir "$Name-init.ps1"
    $exePath = (Get-Command $Exe -ErrorAction Ignore).Source
    if (-not $exePath) { return $null }
    $stale = -not (Test-Path $cache)
    if (-not $stale) {
        $cacheTime = (Get-Item $cache).LastWriteTime
        foreach ($dep in @($exePath) + $AlsoWatch) {
            if ((Test-Path $dep) -and (Get-Item $dep).LastWriteTime -gt $cacheTime) { $stale = $true; break }
        }
    }
    if ($stale) { & $Generator | Out-File $cache -Encoding UTF8 }
    return $cache
}

if ((Test-Cmd oh-my-posh) -and (Test-Path $script:ThemeFile)) {
    $env:POSH_THEME_SOURCE = $script:ThemeFile
    $ompInit = Get-CachedInit -Name 'omp' -Exe 'oh-my-posh' -AlsoWatch $script:ThemeFile -Generator {
        oh-my-posh init pwsh --config $script:ThemeFile
    }
    if ($ompInit) { . $ompInit }
}
else {
    # Elegant fallback prompt — no dependencies
    function prompt {
        $lastOk   = $?
        $path     = $executionContext.SessionState.Path.CurrentLocation.Path
        $path     = $path.Replace($HOME, '~')
        $branch   = if (Test-Path .git) { git branch --show-current 2>$null }
        $gitPart  = if ($branch) { "$($PSStyle.Foreground.FromRgb(0xa277ff))  $branch" } else { '' }
        $charCol  = if ($lastOk) { $PSStyle.Foreground.FromRgb(0x7de2ff) } else { $PSStyle.Foreground.FromRgb(0xff5c8a) }
        $dim      = $PSStyle.Foreground.FromRgb(0x3b4261)
        $cyan     = $PSStyle.Foreground.FromRgb(0x7de2ff)
        "$dim╭─$($PSStyle.Reset) $cyan$path$($PSStyle.Reset)$gitPart`n$dim╰─$($PSStyle.Reset)$charCol❯$($PSStyle.Reset) "
    }
}

# ══════════════════════════════════════════════════════════════════════════════
#  PSREADLINE — predictions, neon syntax colors, smart keybindings
# ══════════════════════════════════════════════════════════════════════════════
if ((Get-Module PSReadLine) -and -not [Console]::IsOutputRedirected) {
    try {
        Set-PSReadLineOption `
            -EditMode Windows `
            -PredictionSource HistoryAndPlugin `
            -PredictionViewStyle ListView `
            -HistoryNoDuplicates `
            -HistorySearchCursorMovesToEnd `
            -MaximumHistoryCount 20000 `
            -BellStyle None
    } catch {
        try { Set-PSReadLineOption -PredictionSource History } catch {}
    }

    Set-PSReadLineOption -Colors @{
        Command                = '#7de2ff'
        Parameter              = '#a277ff'
        Operator               = '#ff6ac1'
        String                 = '#5ef1b3'
        Number                 = '#ffd580'
        Member                 = '#7de2ff'
        Type                   = '#56b6c2'
        Variable               = '#ff9ac1'
        Comment                = '#6b7089'
        Keyword                = '#ff6ac1'
        InlinePrediction       = '#6b7089'
        ListPrediction         = '#a277ff'
        ListPredictionSelected = "$($PSStyle.Background.FromRgb(0x1e2233))"
        Selection              = "$($PSStyle.Background.FromRgb(0x264f78))"
    }

    # History search with arrows, menu completion with Tab
    Set-PSReadLineKeyHandler -Chord UpArrow   -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Chord DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Chord Tab       -Function MenuComplete
    Set-PSReadLineKeyHandler -Chord Enter     -Function ValidateAndAcceptLine
    Set-PSReadLineKeyHandler -Chord Ctrl+d    -Function DeleteCharOrExit
    Set-PSReadLineKeyHandler -Chord Ctrl+w    -Function BackwardKillWord
    Set-PSReadLineKeyHandler -Chord Ctrl+z    -Function Undo
    Set-PSReadLineKeyHandler -Chord Ctrl+y    -Function Redo
    Set-PSReadLineKeyHandler -Chord Ctrl+l    -Function ClearScreen
    Set-PSReadLineKeyHandler -Chord F2        -Function SwitchPredictionView
    Set-PSReadLineKeyHandler -Chord Alt+a     -Function SelectCommandArgument

    # Alt+s — prepend `admin ` to run the current line elevated
    Set-PSReadLineKeyHandler -Chord Alt+s -ScriptBlock {
        $line = $null; $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        if ($line -notmatch '^admin ') {
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition(0)
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert('admin ')
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 6)
        }
    }
}

# ══════════════════════════════════════════════════════════════════════════════
#  FZF — fuzzy everything (themed to match the prompt)
# ══════════════════════════════════════════════════════════════════════════════
$script:HasFzf = Test-Cmd fzf
if ($script:HasFzf) {
    $env:FZF_DEFAULT_OPTS = @(
        '--height=45%', '--layout=reverse', '--border=rounded', '--info=inline'
        "--prompt=❯ ", "--pointer=▶", "--marker=✓"
        '--color=fg:#c8d3f5,bg:-1,hl:#7de2ff'
        '--color=fg+:#ffffff,bg+:#1e2233,hl+:#7de2ff'
        '--color=info:#a277ff,prompt:#7de2ff,pointer:#ff6ac1'
        '--color=marker:#5ef1b3,spinner:#ffd580,header:#6b7089,border:#3b4261'
    ) -join ' '
    if (Test-Cmd fd) { $env:FZF_DEFAULT_COMMAND = 'fd --type f --hidden --exclude .git' }
}

# ══════════════════════════════════════════════════════════════════════════════
#  DEFERRED LOADING — heavy modules load in the background after first prompt,
#  keeping shell startup instant
# ══════════════════════════════════════════════════════════════════════════════
$null = Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action {
    Import-Module Terminal-Icons       -Global -ErrorAction Ignore
    Import-Module CompletionPredictor  -Global -ErrorAction Ignore
    if ((Get-Command fzf -ErrorAction Ignore) -and (Get-Module -ListAvailable PSFzf -ErrorAction Ignore)) {
        Import-Module PSFzf -Global -ErrorAction Ignore
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r' -ErrorAction Ignore
    }
    if (Get-Command gh -ErrorAction Ignore) {
        gh completion -s powershell 2>$null | Out-String | Invoke-Expression
    }
}

# ══════════════════════════════════════════════════════════════════════════════
#  ZOXIDE — smarter cd that learns your habits
# ══════════════════════════════════════════════════════════════════════════════
if (Test-Cmd zoxide) {
    $zoxInit = Get-CachedInit -Name 'zoxide' -Exe 'zoxide' -Generator { zoxide init --cmd cd powershell }
    if ($zoxInit) { . $zoxInit }
    Set-Alias -Name z  -Value __zoxide_z  -Option AllScope -Scope Global -Force
    Set-Alias -Name zi -Value __zoxide_zi -Option AllScope -Scope Global -Force
    Reg 'cd <query>'  'Smart jump to any dir you have visited (zoxide frecency)' 'Navigation' 'cd proj'
    Reg 'cdi / zi'    'Interactive directory picker from zoxide history'          'Navigation' 'cdi'
}

# ══════════════════════════════════════════════════════════════════════════════
#  NAVIGATION
# ══════════════════════════════════════════════════════════════════════════════
function ..    { Set-Location .. }                                 ; Reg '..'    'Go up one directory'  'Navigation'
function ...   { Set-Location ..\.. }                              ; Reg '...'   'Go up two directories' 'Navigation'
function ....  { Set-Location ..\..\.. }                           ; Reg '....'  'Go up three directories' 'Navigation'
function docs  { Set-Location (Join-Path $HOME 'Documents') }      ; Reg 'docs'  'Jump to ~\Documents'  'Navigation'
function dtop  { Set-Location (Join-Path $HOME 'Desktop') }        ; Reg 'dtop'  'Jump to ~\Desktop'    'Navigation'
function dl    { Set-Location (Join-Path $HOME 'Downloads') }      ; Reg 'dl'    'Jump to ~\Downloads'  'Navigation'
function dotfiles { Set-Location $script:DotfilesRoot }            ; Reg 'dotfiles' 'Jump to your dotfiles repo' 'Navigation'
function mkcd  { param([string]$Dir) New-Item -ItemType Directory -Path $Dir -Force | Out-Null; Set-Location $Dir }
Reg 'mkcd <dir>' 'Create a directory and cd into it' 'Navigation' 'mkcd new-project'
function cwd   { Split-Path -Leaf (Get-Location) }                 ; Reg 'cwd'   'Print current folder name' 'Navigation'

# ══════════════════════════════════════════════════════════════════════════════
#  FILES & LISTING — eza with icons when available
# ══════════════════════════════════════════════════════════════════════════════
if (Test-Cmd eza) {
    Remove-Item Alias:ls -Force -ErrorAction Ignore
    function ls { eza --icons --group-directories-first @args }
    function ll { eza -l  --icons --git --group-directories-first --header @args }
    function la { eza -la --icons --git --group-directories-first --header @args }
    function lt { eza --tree --level=2 --icons --group-directories-first @args }
    Reg 'ls'  'List files (icons, dirs first)'                 'Files & Listing'
    Reg 'll'  'Long list with git status column'               'Files & Listing'
    Reg 'la'  'Long list including hidden files'               'Files & Listing'
    Reg 'lt'  'Tree view, 2 levels deep'                       'Files & Listing' 'lt --level=3'
}
else {
    function ll { Get-ChildItem -Force @args | Format-Table -AutoSize }
    function la { Get-ChildItem -Force @args | Format-Table -AutoSize }
    Reg 'll / la' 'List all files (install eza for icons + git status)' 'Files & Listing'
}

if (Test-Cmd bat) {
    Remove-Item Alias:cat -Force -ErrorAction Ignore
    function cat { bat --style=plain --paging=never @args }
    Reg 'cat <file>' 'Print file with syntax highlighting (bat)' 'Files & Listing' 'cat script.ps1'
}

function touch {
    param([Parameter(Mandatory)][string]$File)
    if (Test-Path $File) { (Get-Item $File).LastWriteTime = Get-Date }
    else { New-Item -ItemType File -Path $File | Out-Null }
}
Reg 'touch <file>' 'Create empty file / update its timestamp' 'Files & Listing'

function nf   { param([string]$Name) New-Item -ItemType File -Path . -Name $Name }
Reg 'nf <name>' 'Create a new file in the current dir' 'Files & Listing'

function mkd {
    param([Parameter(ValueFromRemainingArguments)][string[]]$Dirs)
    foreach ($d in $Dirs) { if ($d.Trim()) { New-Item -ItemType Directory -Path $d -Force | Out-Null } }
}
Reg 'mkd <a> <b> …' 'Create multiple directories at once' 'Files & Listing' 'mkd src tests docs'

function ff {
    param([Parameter(Mandatory)][string]$Name)
    if (Test-Cmd fd) { fd --hidden --exclude .git $Name }
    else { Get-ChildItem -Recurse -Filter "*$Name*" -ErrorAction Ignore | ForEach-Object FullName }
}
Reg 'ff <name>' 'Find files by name, recursively (fd-powered)' 'Files & Listing' 'ff config'

function grep {
    param([Parameter(ValueFromRemainingArguments)][string[]]$Rest)
    if (Test-Cmd rg) { if ($MyInvocation.ExpectingInput) { $input | rg @Rest } else { rg @Rest } }
    else { if ($MyInvocation.ExpectingInput) { $input | Select-String @Rest } else { Select-String @Rest } }
}
Reg 'grep <pattern>' 'Search text in files (ripgrep-powered)' 'Files & Listing' 'grep TODO src\'

function unzip {
    param([Parameter(Mandatory)][string]$File, [string]$Dest = $PWD)
    Expand-Archive -Path $File -DestinationPath $Dest -Force
}
Reg 'unzip <file>' 'Extract a zip archive here' 'Files & Listing'

function size {
    param([string]$Path = '.')
    Get-ChildItem $Path -Directory -ErrorAction Ignore | ForEach-Object {
        $bytes = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction Ignore | Measure-Object Length -Sum).Sum
        [pscustomobject]@{ Folder = $_.Name; SizeMB = [math]::Round($bytes / 1MB, 1) }
    } | Sort-Object SizeMB -Descending
}
Reg 'size [path]' 'Folder sizes, sorted largest first' 'Files & Listing' 'size ~\Downloads'

function sed {
    param([Parameter(Mandatory)][string]$File, [Parameter(Mandatory)][string]$Find, [Parameter(Mandatory)][string]$Replace)
    (Get-Content $File).Replace($Find, $Replace) | Set-Content $File
}
Reg 'sed <file> <find> <replace>' 'Replace text inside a file' 'Files & Listing'

function head { param([Parameter(Mandatory)][string]$Path, [int]$n = 10) Get-Content $Path -TotalCount $n }
function tail { param([Parameter(Mandatory)][string]$Path, [int]$n = 10, [switch]$f) Get-Content $Path -Tail $n -Wait:$f }
Reg 'head <file> [n]' 'First n lines of a file (default 10)' 'Files & Listing'
Reg 'tail <file> [n] [-f]' 'Last n lines; -f follows live'    'Files & Listing' 'tail app.log 50 -f'

function which { param([Parameter(Mandatory)][string]$Name) Get-Command $Name -All | Select-Object Name, CommandType, Source }
Reg 'which <cmd>' 'Show what a command resolves to' 'Files & Listing'

# ══════════════════════════════════════════════════════════════════════════════
#  GIT
# ══════════════════════════════════════════════════════════════════════════════
Remove-Item Alias:gc -Force -ErrorAction Ignore   # built-in Get-Content alias — shadows git commit
Remove-Item Alias:gp -Force -ErrorAction Ignore   # built-in Get-ItemProperty alias — shadows git push
Remove-Item Alias:gl -Force -ErrorAction Ignore   # built-in Get-Location alias

function gs    { git status -sb @args }                        ; Reg 'gs'   'git status (short + branch)' 'Git'
function ga    { git add @($(if ($args) { $args } else { '.' })) } ; Reg 'ga [paths]' 'git add (default: everything)' 'Git'
function gc    { param([Parameter(Mandatory)][string]$m) git commit -m "$m" } ; Reg 'gc "<msg>"' 'git commit -m' 'Git' 'gc "fix login bug"'
function gp    { git push @args }                              ; Reg 'gp'   'git push' 'Git'
function gpl   { git pull @args }                              ; Reg 'gpl'  'git pull' 'Git'
function gco   { git checkout @args }                          ; Reg 'gco <branch>' 'git checkout' 'Git'
function gb    { git branch -a @args }                         ; Reg 'gb'   'List all branches' 'Git'
function gd    { git diff @args }                              ; Reg 'gd'   'git diff' 'Git'
function gcl   { git clone @args }                             ; Reg 'gcl <url>' 'git clone' 'Git'
function gl    { git log --graph --pretty=format:'%C(cyan)%h%Creset -%C(magenta)%d%Creset %s %C(dim white)(%cr) %C(green)<%an>%Creset' -20 @args }
Reg 'gl' 'Pretty git log graph (last 20)' 'Git' 'gl -50'
function gundo { git reset --soft HEAD~1 }                     ; Reg 'gundo' 'Undo last commit, keep changes staged' 'Git'
function gcom  { param([Parameter(Mandatory)][string]$m) git add .; git commit -m "$m" }
Reg 'gcom "<msg>"' 'git add all + commit' 'Git' 'gcom "quick save"'
function lazyg { param([Parameter(Mandatory)][string]$m) git add .; git commit -m "$m"; git push }
Reg 'lazyg "<msg>"' 'add + commit + push, one shot' 'Git' 'lazyg "ship it"'
if (Test-Cmd lazygit) { Set-Alias -Name lg -Value lazygit; Reg 'lg' 'Open lazygit TUI' 'Git' }

# ══════════════════════════════════════════════════════════════════════════════
#  FUZZY (fzf)
# ══════════════════════════════════════════════════════════════════════════════
if ($script:HasFzf) {
    function fcd {
        $dir = $(if (Test-Cmd fd) { fd --type d --hidden --exclude .git } else { Get-ChildItem -Recurse -Directory -ErrorAction Ignore | ForEach-Object FullName }) | fzf
        if ($dir) { Set-Location $dir }
    }
    Reg 'fcd' 'Fuzzy-pick any subdirectory and cd into it' 'Fuzzy (fzf)'

    function fe {
        $file = $(if (Test-Cmd fd) { fd --type f --hidden --exclude .git } else { Get-ChildItem -Recurse -File -ErrorAction Ignore | ForEach-Object FullName }) | fzf
        if ($file) { & $script:EDITOR $file }
    }
    Reg 'fe' 'Fuzzy-pick a file and open it in your editor' 'Fuzzy (fzf)'

    function fkill {
        $sel = Get-Process | Sort-Object CPU -Descending |
            ForEach-Object { '{0,-8} {1,-30} {2,8:n1} MB' -f $_.Id, $_.ProcessName, ($_.WorkingSet64 / 1MB) } |
            fzf --header 'PID      NAME                             MEMORY'
        if ($sel) { Stop-Process -Id ([int]($sel -split '\s+')[0]) -Confirm }
    }
    Reg 'fkill' 'Fuzzy-pick a process and kill it' 'Fuzzy (fzf)'

    function fbr {
        $branch = git branch --all --format='%(refname:short)' 2>$null | fzf
        if ($branch) { git checkout ($branch -replace '^origin/', '') }
    }
    Reg 'fbr' 'Fuzzy-pick a git branch and check it out' 'Fuzzy (fzf)'

    function hist {
        $cmd = [Microsoft.PowerShell.PSConsoleReadLine]::GetHistoryItems().CommandLine |
            Select-Object -Unique | Select-Object -Last 2000 | fzf --tac
        if ($cmd) { Set-Clipboard $cmd; Write-Host "  ✓ copied to clipboard: $cmd" -ForegroundColor DarkCyan }
    }
    Reg 'hist' 'Fuzzy-search full command history → clipboard' 'Fuzzy (fzf)'
}

# ══════════════════════════════════════════════════════════════════════════════
#  KUBERNETES
# ══════════════════════════════════════════════════════════════════════════════
function k    { kubectl @args }                       ; Reg 'k'    'kubectl' 'Kubernetes'
function kgp  { kubectl get pods @args }              ; Reg 'kgp'  'Get pods' 'Kubernetes'
function kgs  { kubectl get svc @args }               ; Reg 'kgs'  'Get services' 'Kubernetes'
function kgn  { kubectl get nodes @args }             ; Reg 'kgn'  'Get nodes' 'Kubernetes'
function kgd  { kubectl get deployments @args }       ; Reg 'kgd'  'Get deployments' 'Kubernetes'
function kctx { kubectl config use-context @args }    ; Reg 'kctx <ctx>' 'Switch kube context' 'Kubernetes'
function kns  {
    param([Parameter(Mandatory)][string]$Namespace)
    kubectl config set-context --current --namespace=$Namespace
}
Reg 'kns <namespace>' 'Switch current namespace' 'Kubernetes'
function klog {
    param([Parameter(Mandatory)][string]$Pod, [string]$Container, [switch]$Follow)
    $kargs = @('logs', $Pod)
    if ($Container) { $kargs += @('-c', $Container) }
    if ($Follow)    { $kargs += '-f' }
    kubectl @kargs
}
Reg 'klog <pod> [-Follow]' 'Pod logs, -Follow to stream' 'Kubernetes' 'klog api-7f9 -Follow'
function kexec {
    param([Parameter(Mandatory)][string]$Pod, [string]$Container, [string]$Cmd = '/bin/sh')
    $kargs = @('exec', '-it', $Pod)
    if ($Container) { $kargs += @('-c', $Container) }
    $kargs += @('--', $Cmd)
    kubectl @kargs
}
Reg 'kexec <pod>' 'Shell into a pod' 'Kubernetes'
function kportfwd {
    param([Parameter(Mandatory)][string]$Pod, [Parameter(Mandatory)][int]$LocalPort, [Parameter(Mandatory)][int]$RemotePort)
    kubectl port-forward pod/$Pod "${LocalPort}:${RemotePort}"
}
Reg 'kportfwd <pod> <local> <remote>' 'Port-forward to a pod' 'Kubernetes' 'kportfwd api-7f9 8080 80'

# ══════════════════════════════════════════════════════════════════════════════
#  NETWORK
# ══════════════════════════════════════════════════════════════════════════════
function Get-PubIP { (Invoke-RestMethod 'https://api.ipify.org?format=json').ip }
Reg 'Get-PubIP' 'Your public IP address' 'Network'
function myip { Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notmatch 'Loopback' } | Select-Object InterfaceAlias, IPAddress }
Reg 'myip' 'Local IPv4 addresses per interface' 'Network'
function flushdns { Clear-DnsClientCache; Write-Host '  ✓ DNS cache flushed' -ForegroundColor Green }
Reg 'flushdns' 'Clear the DNS resolver cache' 'Network'
function ports {
    Get-NetTCPConnection -State Listen | Sort-Object LocalPort | ForEach-Object {
        $p = Get-Process -Id $_.OwningProcess -ErrorAction Ignore
        [pscustomobject]@{ Port = $_.LocalPort; Address = $_.LocalAddress; PID = $_.OwningProcess; Process = $p.ProcessName }
    } | Sort-Object Port -Unique
}
Reg 'ports' 'All listening TCP ports + owning process' 'Network'
function weather { param([string]$City = '') Invoke-RestMethod "https://wttr.in/${City}?format=%l:+%c+%t+%h+%w" }
Reg 'weather [city]' 'Current weather one-liner' 'Network' 'weather Mumbai'

# ══════════════════════════════════════════════════════════════════════════════
#  SYSTEM
# ══════════════════════════════════════════════════════════════════════════════
function admin {
    if ($args.Count -gt 0) {
        Start-Process wt -Verb RunAs -ArgumentList "pwsh.exe -NoExit -Command & {$args}"
    } else { Start-Process wt -Verb RunAs }
}
Set-Alias -Name su -Value admin
Reg 'admin / su [cmd]' 'Elevated terminal (or run one command elevated)' 'System' 'admin choco upgrade all'

function uptime {
    $boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $span = (Get-Date) - $boot
    '{0}d {1:hh\:mm} — booted {2:ddd dd MMM HH:mm}' -f $span.Days, $span, $boot
}
Reg 'uptime' 'How long since last boot' 'System'

function sysinfo { Get-ComputerInfo | Select-Object OsName, OsVersion, OsArchitecture, CsProcessors, CsTotalPhysicalMemory }
Reg 'sysinfo' 'OS / CPU / RAM summary' 'System'
if (Test-Cmd fastfetch) { Set-Alias -Name neofetch -Value fastfetch; Reg 'fastfetch' 'Full system info with style' 'System' }

function df { Get-Volume | Where-Object DriveLetter | Sort-Object DriveLetter }
Reg 'df' 'Disk / volume usage' 'System'

function pkill { param([Parameter(Mandatory)][string]$Name) Get-Process $Name -ErrorAction Ignore | Stop-Process }
function pgrep { param([Parameter(Mandatory)][string]$Name) Get-Process $Name -ErrorAction Ignore }
function k9    { param([Parameter(Mandatory)][string]$Name) Stop-Process -Name $Name -Force }
Reg 'pkill <name>' 'Kill processes by name' 'System'
Reg 'pgrep <name>' 'Find processes by name' 'System'
Reg 'k9 <name>'    'Force-kill a process'   'System'

function export { param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$Value) Set-Item -Force -Path "env:$Name" -Value $Value }
Reg 'export <name> <value>' 'Set an environment variable' 'System' 'export DEBUG true'

function path { $env:PATH -split ';' | Where-Object { $_ } }
Reg 'path' 'Show PATH entries, one per line' 'System'

function Update-AllApps { winget upgrade --all --include-unknown --accept-source-agreements }
Reg 'Update-AllApps' 'Upgrade every winget-managed app' 'System'

function Update-PowerShell {
    Write-Host '  Checking for PowerShell updates…' -ForegroundColor Cyan
    $latest = (Invoke-RestMethod 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest').tag_name.Trim('v')
    if ([version]$latest -gt $PSVersionTable.PSVersion) {
        winget upgrade Microsoft.PowerShell --accept-source-agreements --accept-package-agreements
    } else { Write-Host "  ✓ Already on the latest ($($PSVersionTable.PSVersion))" -ForegroundColor Green }
}
Reg 'Update-PowerShell' 'Update pwsh itself (manual, never at startup)' 'System'

function watch {
    param([Parameter(Mandatory)][string]$Command, [int]$Interval = 5)
    $sb = [scriptblock]::Create($Command)
    while ($true) {
        Clear-Host
        Write-Host "Every ${Interval}s: $Command    $(Get-Date -Format HH:mm:ss)`n" -ForegroundColor DarkGray
        & $sb | Out-Host
        Start-Sleep -Seconds $Interval
    }
}
Reg "watch '<cmd>' [sec]" 'Re-run a command on an interval' 'System' "watch 'kgp' 3"

function ide {
    $dir = Get-Location
    wt.exe -w 0 -d $dir pwsh `; split-pane -H -s 0.3 -d $dir pwsh `; split-pane -V -d $dir pwsh
}
Reg 'ide' 'Split Windows Terminal into a 3-pane IDE layout' 'System'

# ══════════════════════════════════════════════════════════════════════════════
#  CLIPBOARD & TEXT
# ══════════════════════════════════════════════════════════════════════════════
function cpy { param([Parameter(ValueFromPipeline, Position = 0)]$Text) process { Set-Clipboard $Text } }
function pst { Get-Clipboard }
Reg 'cpy <text>' 'Copy to clipboard (also accepts pipeline)' 'Clipboard & Text' 'gl | cpy'
Reg 'pst'        'Paste clipboard contents'                  'Clipboard & Text'

# ══════════════════════════════════════════════════════════════════════════════
#  PROFILE & META
# ══════════════════════════════════════════════════════════════════════════════
function ep     { & $script:EDITOR (Join-Path $PSScriptRoot 'Microsoft.PowerShell_profile.ps1') }
Reg 'ep' 'Edit this profile (in your dotfiles repo)' 'Profile & Meta'
function reload { . $PROFILE; Write-Host '  ✓ profile reloaded' -ForegroundColor Green }
Reg 'reload' 'Reload the profile without restarting' 'Profile & Meta'
function themes { oh-my-posh config export --output "$env:TEMP\current.omp.json" 2>$null; & $script:EDITOR $script:ThemeFile }
Reg 'themes' 'Open the prompt theme file for editing' 'Profile & Meta'

# ── Keybindings & settings registered for the cheatsheet ─────────────────────
Reg 'Ctrl+r'    'Fuzzy-search command history (PSFzf)'            'Keybindings'
Reg 'Ctrl+t'    'Fuzzy-insert a file path at the cursor (PSFzf)'  'Keybindings'
Reg 'Tab'       'Menu completion — cycle through candidates'      'Keybindings'
Reg '↑ / ↓'     'Search history filtered by what you typed'       'Keybindings'
Reg '→'         'Accept the ghost-text suggestion'                'Keybindings'
Reg 'F2'        'Toggle prediction view: inline ⇄ list'           'Keybindings'
Reg 'Alt+a'     'Jump between command arguments'                  'Keybindings'
Reg 'Alt+s'     'Prefix line with `admin` (run elevated)'         'Keybindings'
Reg 'Ctrl+w'    'Delete previous word'                            'Keybindings'
Reg 'Ctrl+d'    'Delete char / exit shell on empty line'          'Keybindings'
Reg 'Ctrl+l'    'Clear screen'                                    'Keybindings'
Reg 'Ctrl+z / Ctrl+y' 'Undo / redo edits on the line'             'Keybindings'

Reg 'Predictions'  'HistoryAndPlugin, ListView — type to see matching history' 'Settings'
Reg 'History'      '20 000 entries, no duplicates, saved across sessions'      'Settings'
Reg 'Theme'        "oh-my-posh → $script:ThemeFile"                            'Settings'
Reg 'Editor'       "`$EDITOR = $script:EDITOR"                                 'Settings'
Reg 'Modules'      'Terminal-Icons, PSFzf, CompletionPredictor (lazy-loaded)'  'Settings'

# ══════════════════════════════════════════════════════════════════════════════
#  SHORTCUTS — the command matrix. `shortcuts`, `shortcuts git`, `shortcuts -i`
# ══════════════════════════════════════════════════════════════════════════════
function Show-Shortcuts {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)][string]$Filter,
        [Alias('i')][switch]$Interactive
    )

    $cyan   = $PSStyle.Foreground.FromRgb(0x7de2ff)
    $violet = $PSStyle.Foreground.FromRgb(0xa277ff)
    $mint   = $PSStyle.Foreground.FromRgb(0x5ef1b3)
    $dim    = $PSStyle.Foreground.FromRgb(0x6b7089)
    $bold   = $PSStyle.Bold
    $r      = $PSStyle.Reset

    $items = $global:__ProfileCommands
    if ($Filter) {
        $items = $items | Where-Object { $_.Name -like "*$Filter*" -or $_.Desc -like "*$Filter*" -or $_.Category -like "*$Filter*" }
        if (-not $items) { Write-Host "$dim  nothing matches '$Filter' — try 'shortcuts' for everything$r"; return }
    }

    if ($Interactive -and $script:HasFzf) {
        $sel = $items | ForEach-Object { '{0,-28} {1}  [{2}]' -f $_.Name, $_.Desc, $_.Category } |
            fzf --header 'ENTER copies the command to your clipboard'
        if ($sel) {
            $name = ($sel -split '\s{2,}')[0].Trim()
            $hit  = $global:__ProfileCommands | Where-Object { $_.Name -eq $name } | Select-Object -First 1
            if ($hit) { Set-Clipboard $hit.Usage; Write-Host "  ✓ copied: $($hit.Usage)" -ForegroundColor DarkCyan }
        }
        return
    }

    Write-Host ''
    Write-Host "  $violet╭──────────────────────────────────────────────────────────────╮$r"
    Write-Host "  $violet│$r   ${bold}${cyan}⚡ COMMAND MATRIX$r$dim — your PowerShell, mapped$r                    $violet│$r"
    Write-Host "  $violet│$r   ${dim}shortcuts <word> to filter · shortcuts -i for fuzzy pick$r    $violet│$r"
    Write-Host "  $violet╰──────────────────────────────────────────────────────────────╯$r"

    $order = 'Navigation', 'Files & Listing', 'Git', 'Fuzzy (fzf)', 'Kubernetes', 'Network', 'System',
             'Clipboard & Text', 'Profile & Meta', 'Keybindings', 'Settings'
    $groups = $items | Group-Object Category | Sort-Object { [array]::IndexOf($order, $_.Name) }

    foreach ($g in $groups) {
        $icon = switch ($g.Name) {
            'Navigation'       { '' }  'Files & Listing' { '' }  'Git'        { '' }
            'Fuzzy (fzf)'      { '' }  'Kubernetes'      { '󱃾' }  'Network'    { '󰖩' }
            'System'           { '' }  'Clipboard & Text'{ '' }  'Profile & Meta' { '' }
            'Keybindings'      { '' }  'Settings'        { '' }  default      { '·' }
        }
        Write-Host ''
        Write-Host "  $mint$icon $bold$($g.Name.ToUpper())$r"
        Write-Host "  $dim$('─' * 62)$r"
        foreach ($c in $g.Group) {
            Write-Host ("  $cyan{0,-26}$r {1}" -f $c.Name, $c.Desc)
        }
    }
    Write-Host ''
}
Set-Alias -Name shortcuts -Value Show-Shortcuts
Set-Alias -Name cheat     -Value Show-Shortcuts
Reg 'shortcuts [filter] [-i]' 'This cheatsheet — every command, key & setting' 'Profile & Meta' 'shortcuts git'

# ══════════════════════════════════════════════════════════════════════════════
#  COMPLETIONS — cheap to register, run only on Tab
# ══════════════════════════════════════════════════════════════════════════════
Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
    $word = $wordToComplete.Replace('"', '""')
    $ast  = $commandAst.ToString().Replace('"', '""')
    winget complete --word="$word" --commandline "$ast" --position $cursorPosition | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    dotnet complete --position $cursorPosition $commandAst.ToString() | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

# ══════════════════════════════════════════════════════════════════════════════
#  GREETING — one quiet line, no network calls, no update checks
# ══════════════════════════════════════════════════════════════════════════════
$__profileStopwatch.Stop()
if (-not $env:OBAID_PROFILE_QUIET) {
    $ms   = $__profileStopwatch.ElapsedMilliseconds
    $dim  = $PSStyle.Foreground.FromRgb(0x6b7089)
    $cyan = $PSStyle.Foreground.FromRgb(0x7de2ff)
    Write-Host "$dim  ⚡ pwsh $($PSVersionTable.PSVersion) ready in $cyan${ms}ms$dim · type ${cyan}shortcuts$dim for your command map$($PSStyle.Reset)"
}
Remove-Variable __profileStopwatch -ErrorAction Ignore
