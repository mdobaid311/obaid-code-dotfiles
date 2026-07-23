# ⚡ Obaid's PowerShell

A fast, futuristic, elegant PowerShell 7 environment. No update checks at
startup, no network calls, heavy modules lazy-load in the background — the
shell is ready in a few hundred milliseconds and everything degrades
gracefully if a tool is missing.

## Install (fresh machine)

```powershell
git clone https://github.com/mdobaid311/obaid-code-dotfiles.git H:\Dotfiles
H:\Dotfiles\PowerShell\setup.ps1
```

Then set your terminal font to **JetBrainsMono NF** and restart.
(Windows Terminal is already configured by [windows-terminal/settings.json](../windows-terminal/settings.json).)

## The one command to remember

```
shortcuts            # every command, keybinding and setting, grouped
shortcuts git        # filter by keyword
shortcuts -i         # fuzzy-pick with fzf, copies the command to clipboard
```

(`cheat` works too.)

## What's inside

| Piece | Role |
|---|---|
| [Microsoft.PowerShell_profile.ps1](Microsoft.PowerShell_profile.ps1) | The profile — prompt, keybindings, ~60 commands |
| [Themes/obaid.omp.json](Themes/obaid.omp.json) | Custom oh-my-posh theme (neon cyan / violet on void) |
| [setup.ps1](setup.ps1) | Idempotent bootstrap for a new machine |

**Toolchain** (auto-detected, all optional): oh-my-posh · zoxide · fzf + PSFzf ·
eza · bat · fd · ripgrep · fastfetch · lazygit · Terminal-Icons ·
CompletionPredictor.

## Highlights

- **Prompt** — two-line, git-aware (dirty/ahead/behind change its color),
  node/python versions appear only inside projects, execution time shows for
  slow commands, transient prompt collapses old prompts to a single `❯`.
- **Predictions** — ghost-text + list view from history and completions
  (`F2` toggles, `→` accepts).
- **Fuzzy everything** — `Ctrl+r` history, `Ctrl+t` file paths, `fcd`/`fe`/
  `fkill`/`fbr`/`hist` pickers.
- **Smart cd** — zoxide learns your directories; `cd proj` jumps from anywhere.
- **Unix muscle memory** — `touch grep sed which head tail df pkill pgrep
  export unzip watch`.
- **Git flow** — `gs ga gc gp gpl gco gb gd gl gundo gcom lazyg lg`.
- **Kubernetes** — `k kgp kgs kgn kgd kctx kns klog kexec kportfwd`.

## Speed rules baked into the profile

1. Nothing touches the network at startup (updates are manual:
   `Update-PowerShell`, `Update-AllApps`).
2. Terminal-Icons, PSFzf, CompletionPredictor and gh completions load on the
   first idle moment *after* the prompt appears.
3. Every external tool is behind a `Test-Cmd` check with a pure-PowerShell
   fallback.

Set `$env:OBAID_PROFILE_QUIET = 1` to suppress the greeting line.
