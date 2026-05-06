#!/bin/bash

input=$(cat)
cols=$(tput cols 2>/dev/null || echo 120)

ESC=$'\033'
DIM="${ESC}[2m"
RST="${ESC}[0m"
RED="${ESC}[0;31m"
GRN="${ESC}[0;32m"
YLW="${ESC}[0;33m"
BLU="${ESC}[1;34m"
CYN="${ESC}[0;36m"
BGRN="${ESC}[1;32m"

strip_ansi() { sed $'s/\033\\[[0-9;]*m//g' <<< "$1"; }

cwd=$(jq -r '.workspace.current_dir // .cwd // empty' <<< "$input")
[ -z "$cwd" ] && cwd="$PWD"
dir=$(basename "$cwd")

model_raw=$(jq -r '.model.display_name // .model.id // empty' <<< "$input")
ctx_pct=$(jq -r '.context_window.used_percentage // empty' <<< "$input")
cost=$(jq -r '.cost.total_cost_usd // empty' <<< "$input")
effort=$(jq -r '.effort.level // empty' <<< "$input")

case "$model_raw" in
  *[Oo]pus*)   model="opus" ;;
  *[Ss]onnet*) model="sonnet" ;;
  *[Hh]aiku*)  model="haiku" ;;
  *)           model="${model_raw##*-}" ;;
esac

ctx_color="$GRN"
if [ -n "$ctx_pct" ]; then
  ctx_int=${ctx_pct%.*}
  (( ctx_int >= 80 )) && ctx_color="$RED"
  (( ctx_int >= 50 && ctx_int < 80 )) && ctx_color="$YLW"
fi

branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)

# left side
left="${CYN}${dir}${RST}"
if [ -n "$branch" ]; then
  left+=" ${DIM}│${RST} ${branch}"
  dirty=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)
  [ -n "$dirty" ] && left+=" ${YLW}✗${RST}"
fi

# right side — three groups: [code changes]   [model │ effort]   [usage │ cost]
sep=" ${DIM}│${RST} "
gap="            "
groups=("$left")

# code changes
code_parts=()
if [ -n "$branch" ]; then
  wt_stat=$(git -C "$cwd" --no-optional-locks diff --shortstat HEAD 2>/dev/null)
  if [ -n "$wt_stat" ]; then
    wt_add=$(grep -o '[0-9]* insertion' <<< "$wt_stat" | grep -o '[0-9]*')
    wt_del=$(grep -o '[0-9]* deletion' <<< "$wt_stat" | grep -o '[0-9]*')
    : "${wt_add:=0}" "${wt_del:=0}"
    if [ "$wt_add" != "0" ] || [ "$wt_del" != "0" ]; then
      code_parts+=("${GRN}+${wt_add}${RST} ${RED}-${wt_del}${RST}")
    fi
  fi

  # find the branch we're based on (nearest merge-base = what we'd PR against)
  base_branch=""
  best_distance=999999
  for b in $(git -C "$cwd" for-each-ref --format='%(refname:short)' refs/heads/ 2>/dev/null); do
    [ "$b" = "$branch" ] && continue
    mb=$(git -C "$cwd" merge-base HEAD "$b" 2>/dev/null) || continue
    dist=$(git -C "$cwd" rev-list --count "$mb..HEAD" 2>/dev/null) || continue
    if (( dist < best_distance )); then
      best_distance=$dist
      base_branch=$b
    fi
  done

  if [ -n "$base_branch" ] && [ "$branch" != "$base_branch" ]; then
    merge_base=$(git -C "$cwd" --no-optional-locks merge-base HEAD "$base_branch" 2>/dev/null)
    if [ -n "$merge_base" ]; then
      br_stat=$(git -C "$cwd" --no-optional-locks diff --shortstat "$merge_base" HEAD 2>/dev/null)
      if [ -n "$br_stat" ]; then
        br_add=$(grep -o '[0-9]* insertion' <<< "$br_stat" | grep -o '[0-9]*')
        br_del=$(grep -o '[0-9]* deletion' <<< "$br_stat" | grep -o '[0-9]*')
        : "${br_add:=0}" "${br_del:=0}"
        if [ "$br_add" != "0" ] || [ "$br_del" != "0" ]; then
          code_parts+=("Δ${base_branch} ${GRN}+${br_add}${RST} ${RED}-${br_del}${RST}")
        fi
      fi
    fi
  fi
fi

# group 2: model │ effort
meta_parts=()
[ -n "$model" ] && meta_parts+=("${DIM}${model}${RST}")
[ -n "$effort" ] && meta_parts+=("$effort")

# group 3: usage │ cost
usage_parts=()
[ -n "$ctx_pct" ] && usage_parts+=("${ctx_color}${ctx_int}%${RST}")
if [ -n "$cost" ] && [ "$cost" != "0" ]; then
  usage_parts+=("$(printf '$%.2f' "$cost")")
fi

# join within groups, then join groups with wider gap
join_parts() {
  local result="" i
  for i in "${!parts[@]}"; do
    (( i > 0 )) && result+="$sep"
    result+="${parts[$i]}"
  done
  echo -n "$result"
}

for group_ref in code_parts meta_parts usage_parts; do
  local_group="$group_ref[@]"
  parts=("${!local_group}")
  (( ${#parts[@]} == 0 )) && continue
  joined=$(join_parts)
  [ -n "$joined" ] && groups+=("$joined")
done

output=""
for i in "${!groups[@]}"; do
  (( i > 0 )) && output+="$gap"
  output+="${groups[$i]}"
done

printf '%s\n' "$output"
