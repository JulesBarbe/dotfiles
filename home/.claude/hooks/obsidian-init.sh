#!/bin/bash
# auto-configure plansDirectory for the current project to point at the obsidian vault
set -euo pipefail

VAULT="${OBSIDIAN_VAULT:-}"
[[ -z "$VAULT" ]] && exit 0
ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
# worktree-safe: resolve the real repo name, not the worktree directory name
PROJECT=$(basename "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)")")
SETTINGS="$ROOT/.claude/settings.local.json"
PLANS_DIR="$VAULT/Projects/$PROJECT/plans"

# skip if already configured
if [[ -f "$SETTINGS" ]] && python3 -c "
import json, sys
with open('$SETTINGS') as f:
    d = json.load(f)
if 'plansDirectory' in d:
    sys.exit(0)
sys.exit(1)
" 2>/dev/null; then
    exit 0
fi

# create vault project dirs
mkdir -p "$PLANS_DIR"

# create or update settings.local.json
mkdir -p "$(dirname "$SETTINGS")"
if [[ -f "$SETTINGS" ]]; then
    python3 -c "
import json
with open('$SETTINGS') as f:
    d = json.load(f)
d['plansDirectory'] = '$PLANS_DIR'
with open('$SETTINGS', 'w') as f:
    json.dump(d, f, indent=2)
    f.write('\n')
"
else
    python3 -c "
import json
d = {'plansDirectory': '$PLANS_DIR'}
with open('$SETTINGS', 'w') as f:
    json.dump(d, f, indent=2)
    f.write('\n')
"
fi

echo "Configured plansDirectory for $PROJECT -> $PLANS_DIR"
