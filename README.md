# dotfiles

this repo mirrors `$HOME` under `home/`. `sync.zsh` symlinks those files into place.

## setup

- clone to `~/code/dotfiles`
- run `./sync.zsh --dry-run`
- run `./sync.zsh`

## zsh

- `~/.zshrc` is a tiny loader (tracked) that sources:
  - `~/.config/zsh/public.zsh` (tracked)
  - `~/.config/zsh/private.zsh` (not tracked; work + secrets)

once sourced, run `dotsync` to re-apply symlinks.

