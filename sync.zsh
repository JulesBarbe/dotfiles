#!/usr/bin/env zsh
emulate -L zsh
set -euo pipefail

repo_dir="${0:A:h}"
src_root="$repo_dir/home"

dry_run=0
if [[ "${1-}" == "--dry-run" ]]; then
  dry_run=1
fi

if [[ ! -d "$src_root" ]]; then
  print -u2 -- "error: expected '$src_root' to exist"
  exit 1
fi

timestamp="$(date +"%Y%m%d-%H%M%S")"
backup_root="$HOME/.dotfiles-backup/$timestamp"

typeset -gi linked=0 backed_up=0 skipped=0

do_cmd() {
  if (( dry_run )); then
    print -- "dry-run: $*"
    return 0
  fi
  "$@"
}

backup_if_needed() {
  local rel="$1"
  local dst="$HOME/$rel"

  if [[ -e "$dst" && ! -L "$dst" ]]; then
    do_cmd mkdir -p -- "$backup_root/${rel:h}"
    do_cmd mv -- "$dst" "$backup_root/$rel"
    (( backed_up += 1 ))
    print -- "backup: $rel -> $backup_root/$rel"
  fi
}

link_one() {
  local rel="$1"
  local src="$src_root/$rel"
  local dst="$HOME/$rel"

  if [[ ! -e "$src" ]]; then
    (( skipped += 1 ))
    print -u2 -- "skip (missing src): $rel"
    return 0
  fi

  do_cmd mkdir -p -- "${dst:h}"
  backup_if_needed "$rel"

  do_cmd ln -sfn -- "$src" "$dst"
  (( linked += 1 ))
  print -- "link: $dst -> $src"
}

for src in "$src_root"/**/*(.DN); do
  rel="${src#$src_root/}"
  link_one "$rel"
done

print -- "done: linked=$linked backed_up=$backed_up skipped=$skipped"

