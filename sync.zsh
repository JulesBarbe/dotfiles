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

if (( ! dry_run )) && command -v brew &>/dev/null && [[ -f "$HOME/.Brewfile" ]]; then
  print -- "\ninstalling brew dependencies..."
  brew bundle --global
fi

# npm globals needed by claude code lsp plugins
if (( ! dry_run )) && command -v npm &>/dev/null; then
  local -a npm_globals=(typescript typescript-language-server)
  local missing=()
  for pkg in "${npm_globals[@]}"; do
    if ! npm list -g "$pkg" &>/dev/null; then
      missing+=("$pkg")
    fi
  done
  if (( ${#missing} )); then
    print -- "\ninstalling npm globals: ${missing[*]}..."
    npm install -g "${missing[@]}"
  fi
fi

# install enabled claude code plugins that aren't already installed
if (( ! dry_run )) && command -v claude &>/dev/null && command -v jq &>/dev/null; then
  local settings="$src_root/.claude/settings.public.json"
  if [[ -f "$settings" ]]; then
    local -a wanted=(${(f)"$(jq -r '.enabledPlugins // {} | keys[]' "$settings")"})
    if (( ${#wanted} )); then
      local installed_file="$HOME/.claude/plugins/installed_plugins.json"
      for plugin in "${wanted[@]}"; do
        if [[ ! -f "$installed_file" ]] || ! jq -e --arg p "$plugin" '.plugins[$p]' "$installed_file" &>/dev/null; then
          print -- "installing claude plugin: $plugin..."
          claude plugin install "$plugin" 2>&1
        fi
      done
    fi
  fi
fi

# ensure obsidian mcp server is configured in claude code
if (( ! dry_run )) && command -v jq &>/dev/null && [[ -f "$HOME/.claude.json" ]]; then
  if [[ "$(jq -r '.mcpServers.obsidian // empty' "$HOME/.claude.json")" == "" ]]; then
    print -- "\nprovisioning obsidian mcp server in ~/.claude.json..."
    local tmp="$(mktemp)"
    jq --arg home "$HOME" '.mcpServers.obsidian = {
      "type": "stdio",
      "command": "npx",
      "args": ["@bitbonsai/mcpvault@latest", ($home + "/Documents/Scality")],
      "env": {}
    }' "$HOME/.claude.json" > "$tmp"
    mv "$tmp" "$HOME/.claude.json"
  fi
fi