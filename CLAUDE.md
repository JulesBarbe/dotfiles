# dotfiles — repo guide for Claude

Personal dotfiles. `home/` mirrors `$HOME`; `sync.zsh` symlinks every file under `home/**` into the matching `$HOME` path and installs brew/npm/plugin deps. `dotsync` re-runs it. See `README.md` for the human-facing overview.

## CRITICAL: some live dotfiles are GENERATED — don't edit them

Several files in `$HOME` are **assembled at shell init** by `home/.config/zsh/public.zsh` from tracked `*.public.*` sources plus optional local-only `*.private.*` parts. Editing the generated file is futile — it gets overwritten on the next shell startup, and it isn't synced.

| Generated (do NOT edit) | Edit this source instead | How it's built |
|---|---|---|
| `~/.claude/CLAUDE.md` | `home/.claude/CLAUDE.public.md` | `cat public private > out` (or `cp public out` if no private) |
| `~/.claude/settings.json` | `home/.claude/settings.public.json` | deep-merged with `settings.private.json` via `jq`, private wins |

`*.private.*` files are local-only (untracked, not in repo) and hold secrets/work-specific config. `.example` templates show their shape.

**To change my global Claude Code instructions → edit `home/.claude/CLAUDE.public.md`.** It is the synced source of truth that becomes `~/.claude/CLAUDE.md`.

After editing a source, the live file refreshes on the next shell. To apply immediately in-session, re-run the assembly (`cp`/`cat`/`jq` as above) — but only do this if asked.

## Private plugins/skills via an internal marketplace

Private Claude Code plugins (and the skills/commands they bundle) live in a **separate private marketplace repo**, never in this dotfiles repo. They're wired in through `~/.claude/settings.private.json` (local-only): an `extraKnownMarketplaces` entry naming the marketplace source, plus `enabledPlugins` entries (`plugin@marketplace`). `sync.zsh` merges public+private settings, registers any marketplace not yet in `~/.claude/plugins/known_marketplaces.json` via `claude plugin marketplace add`, then installs enabled plugins — so a fresh machine reproduces everything from `dotsync`, and the private marketplace URL/plugin list stay out of the tracked repo. `settings.private.example.json` shows the shape.

## Everything else under `home/` is a direct symlink

`home/.zshrc`, `home/.config/nvim/init.lua`, `home/.Brewfile`, `home/.claude/commands/`, `home/.claude/hooks/`, etc. are symlinked as-is — edit them directly in the repo and the change is live immediately (no rebuild step).

## Note on `~/.claude/CLAUDE.md`'s own instructions

The live `~/.claude/CLAUDE.md` (built from `CLAUDE.public.md`) tells me to store plans in an Obsidian vault and to follow a commit-by-commit flow. Those apply here too. In particular: organize work into logical commit-sized steps and surface the boundaries, but **the user runs the commits** — don't commit or stage unless explicitly asked.
