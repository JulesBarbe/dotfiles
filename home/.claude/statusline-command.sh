#!/bin/bash

input=$(cat)

ESC=$'\033'
DIM="${ESC}[2m"
RST="${ESC}[0m"
RED="${ESC}[0;31m"
GRN="${ESC}[0;32m"
YLW="${ESC}[0;33m"
CYN="${ESC}[0;36m"

# US separator, not tab: tab is IFS whitespace, so runs of it collapse and
# empty fields would shift every later variable left by one
IFS=$'\x1f' read -r cwd model_raw ctx_pct cost effort fast_mode rl5 < <(
  jq -r '[ .workspace.current_dir // .cwd // ""
         , .model.display_name // .model.id // ""
         , .context_window.used_percentage // 0
         , .cost.total_cost_usd // 0
         , .effort.level // ""
         , (.fast_mode // false | tostring)
         , .rate_limits.five_hour.used_percentage // ""
         ] | join("\u001f")' <<< "$input"
)
[ -z "$cwd" ] && cwd="$PWD"
dir=$(basename "$cwd")

g() { git -C "$cwd" --no-optional-locks "$@" 2>/dev/null; }

case "$model_raw" in
  *[Oo]pus*)   model="opus" ;;
  *[Ss]onnet*) model="sonnet" ;;
  *[Hh]aiku*)  model="haiku" ;;
  *[Ff]able*)  model="fable" ;;
  *)           model="${model_raw##*-}" ;;
esac

pct_color() {
  local n=${1%.*}
  if   (( n >= 80 )); then printf '%s' "$RED"
  elif (( n >= 50 )); then printf '%s' "$YLW"
  else                     printf '%s' "$GRN"
  fi
}

# "3 files changed, 61 insertions(+), 8 deletions(-)" -> "61 8"
parse_shortstat() {
  local a=0 d=0
  [[ $1 =~ ([0-9]+)\ insertion ]] && a=${BASH_REMATCH[1]}
  [[ $1 =~ ([0-9]+)\ deletion ]]  && d=${BASH_REMATCH[1]}
  printf '%s %s' "$a" "$d"
}

# Nearest merge-base is only meaningful among integration branches: over all
# refs it resolves to whatever stale branch happens to fork closest to HEAD,
# and any ref at/ahead of HEAD scores 0 and wins with an empty diff.
pick_base() {
  local override ref sha head_sha dist best="" best_dist=-1

  override=$(g config --get claude.baseBranch)
  if [ -n "$override" ]; then printf '%s' "$override"; return; fi

  head_sha=$(g rev-parse HEAD) || return

  # an empty suffix would leave the bare prefix refs/remotes/origin/, which
  # for-each-ref expands to every remote branch
  local remote_head patterns=()
  remote_head=$(g symbolic-ref --short refs/remotes/origin/HEAD)
  [ -n "${remote_head##*/}" ] && patterns+=("refs/remotes/origin/${remote_head##*/}")
  local name
  for name in main master develop development trunk staging; do
    patterns+=("refs/remotes/origin/$name" "refs/heads/$name")
  done

  while read -r ref sha; do
    [ -z "$sha" ] && continue
    [ "$sha" = "$head_sha" ] && continue
    dist=$(g rev-list --count HEAD "^$sha")
    [ -z "$dist" ] && continue
    if (( best_dist < 0 || dist < best_dist )); then
      best_dist=$dist
      best="$ref"
    fi
  done < <(g for-each-ref --format='%(refname:short)%09%(objectname)' "${patterns[@]}")

  printf '%s' "$best"
}

branch=$(g symbolic-ref --short HEAD)
[ -z "$branch" ] && branch=$(g rev-parse --short HEAD)

# left side
left="${CYN}${dir}${RST}"
if [ -n "$branch" ]; then
  left+=" ${DIM}│${RST} ${branch}"
  [ -n "$(g status --porcelain)" ] && left+=" ${YLW}✗${RST}"
  if ahead_behind=$(g rev-list --count --left-right '@{upstream}...HEAD'); then
    behind=${ahead_behind%%[[:space:]]*}
    ahead=${ahead_behind##*[[:space:]]}
    (( ahead > 0 ))  && left+=" ${DIM}↑${ahead}${RST}"
    (( behind > 0 )) && left+=" ${DIM}↓${behind}${RST}"
  fi
fi

# right side — three groups: [code changes]   [model │ effort]   [usage │ cost]
sep=" ${DIM}│${RST} "
gap="            "
groups=("$left")

# code changes
code_parts=()
if [ -n "$branch" ]; then
  read -r wt_add wt_del <<< "$(parse_shortstat "$(g diff --shortstat HEAD)")"
  if (( wt_add > 0 || wt_del > 0 )); then
    code_parts+=("${GRN}+${wt_add}${RST} ${RED}-${wt_del}${RST}")
  fi

  base_branch=$(pick_base)
  if [ -n "$base_branch" ]; then
    merge_base=$(g merge-base HEAD "$base_branch")
    if [ -n "$merge_base" ]; then
      read -r br_add br_del <<< "$(parse_shortstat "$(g diff --shortstat "$merge_base" HEAD)")"
      if (( br_add > 0 || br_del > 0 )); then
        code_parts+=("Δ${base_branch#origin/} ${GRN}+${br_add}${RST} ${RED}-${br_del}${RST}")
      fi
    fi
  fi
fi

# group 2: model │ effort
meta_parts=()
[ -n "$model" ] && meta_parts+=("${DIM}${model}${RST}")
[ "$fast_mode" = "true" ] && meta_parts+=("${YLW}⚡${RST}")
[ -n "$effort" ] && meta_parts+=("$effort")

# group 3: context │ 5h limit │ cost
usage_parts=()
usage_parts+=("$(pct_color "$ctx_pct")${ctx_pct%.*}%${RST}")
if [ -n "$rl5" ]; then
  usage_parts+=("${DIM}5h${RST} $(pct_color "$rl5")${rl5%.*}%${RST}")
fi
if [ "$cost" != "0" ]; then
  usage_parts+=("$(printf '$%.2f' "$cost")")
fi

join_parts() {
  local result="" i
  for i in "${!parts[@]}"; do
    (( i > 0 )) && result+="$sep"
    result+="${parts[$i]}"
  done
  printf '%s' "$result"
}

for group_ref in code_parts meta_parts usage_parts; do
  all="$group_ref[@]"
  parts=("${!all}")
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
