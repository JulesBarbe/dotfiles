# dotfiles

mirrors `$HOME` under `home/`. `sync.zsh` symlinks everything into place and installs brew dependencies.

## setup

```zsh
git clone <repo-url> ~/code/dotfiles
~/code/dotfiles/sync.zsh
```

open a new shell afterwards. `dotsync` re-syncs anytime.

## what's in here

### brew

`~/.Brewfile` — shared tool dependencies (neovim, ripgrep, fd, fzf, etc.). installed automatically by `dotsync`.

### zsh

`~/.zshrc` sources:
- `~/.config/zsh/public.zsh` (tracked) — oh-my-zsh, aliases, helpers, assemblers
- `~/.config/zsh/private.zsh` (not tracked) — work secrets, env vars

copy `private.example.zsh` to `private.zsh` to get started.

### ghostty

`~/.config/ghostty/config` — terminal config.

### neovim

`~/.config/nvim/init.lua` — single-file config, lazy.nvim managed. plugins auto-install on first launch. LSP servers auto-install via Mason on first open of a supported filetype.

### claude code

public/private split — public files are tracked; private files are local-only. `public.zsh` assembles them on every shell init.

**CLAUDE.md** — `public.md` + `private.md` concatenated at shell init. copy `CLAUDE.private.example.md` to `~/.claude/CLAUDE.private.md` to add private instructions.

**settings.json** — `settings.public.json` deep-merged with `settings.private.json` (private wins). requires `jq`.

**obsidian integration** — plans and logs stored in an obsidian vault. set `OBSIDIAN_VAULT` in `private.zsh`. a `SessionStart` hook auto-configures `plansDirectory` per project; no-op if unset.

**other:** `/dump` command (log to obsidian), statusline script (dir, branch, model, context %, cost).
