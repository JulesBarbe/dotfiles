# dotfiles

this repo mirrors `$HOME` under `home/`. `sync.zsh` symlinks those files into place.

## setup

- clone to `~/code/dotfiles`
- run `./sync.zsh --dry-run`
- run `./sync.zsh`
- open a new shell — assemblers in `public.zsh` generate the final `CLAUDE.md` and `settings.json`

once sourced, run `dotsync` to re-apply symlinks.

## zsh

`~/.zshrc` is a tiny loader (tracked) that sources:
- `~/.config/zsh/public.zsh` (tracked) — oh-my-zsh, aliases, assemblers
- `~/.config/zsh/private.zsh` (not tracked; work + secrets)

copy `private.example.zsh` → `private.zsh` to get started.

## claude code

public/private split — same pattern as zsh. public files are tracked and symlinked; private files are local-only. `public.zsh` assembles them on every shell init.

### CLAUDE.md (instructions)

| file | tracked | description |
|------|---------|-------------|
| `~/.claude/CLAUDE.public.md` | yes | general instructions, preferences, obsidian integration |
| `~/.claude/CLAUDE.private.md` | no | work-specific context (projects, team, etc.) |
| `~/.claude/CLAUDE.md` | generated | concatenation of public + private, built on shell init |

copy `CLAUDE.private.example.md` → `~/.claude/CLAUDE.private.md` to add private instructions.

### settings.json (permissions, hooks, preferences)

| file | tracked | description |
|------|---------|-------------|
| `~/.claude/settings.public.json` | yes | permissions, hooks, model, preferences |
| `~/.claude/settings.private.json` | no | work-specific overrides (e.g. plugin marketplaces) |
| `~/.claude/settings.json` | generated | deep merge (`jq -s '.[0] * .[1]'`), private wins on conflicts |

create `~/.claude/settings.private.json` to add private settings. requires `jq`.

### obsidian integration

plans and conversation logs are stored in an obsidian vault. set `OBSIDIAN_VAULT` in `private.zsh`:

```zsh
export OBSIDIAN_VAULT="$HOME/Documents/MyVault"
```

a `SessionStart` hook auto-configures `plansDirectory` per project. if `OBSIDIAN_VAULT` is unset, the hook is a no-op.

### other tracked files

- `hooks/obsidian-init.sh` — SessionStart hook for plan directory setup
- `statusline-command.sh` — status bar showing dir, branch, model, effort, context %, cost
- `commands/dump.md` — `/dump` skill for logging decisions to obsidian vault
