#!/usr/bin/env bash
# start_of_tri_cleanup.sh
#
# Purpose
#   Start-of-trimester cleanup for the E8 ML1 student environment.
#   Flow remains intentionally simple so future cohorts can bolt on CSV imports,
#   roster comparisons, or directory policies without fighting complexity.
#
# What it does
#   0) Staff review: show staff-admins and staff-users; allow admin removal and full staff deletion
#   1) Stash repeaters at the same level (junior->junior, senior->senior)
#   2) Stash left-company
#   3) Stash skipping this trimester
#   4) Stash other exceptions
#   5) Offer to classify ungrouped human accounts into staff-user, staff-admin, type-junior, or type-senior
#   6) Delete remaining Seniors (accounts and homes)
#   7) Promote remaining Juniors to Seniors
#   8) Print a clear action summary and log to /var/log/e8ml1
#
# Assumptions
#   - Linux host with Bash >= 4.0
#   - Role groups exist: type-junior, type-senior, staff-user, staff-admin
#   - System user and group management via getent, usermod, userdel, gpasswd/deluser
#
# Safety
#   - Dry-run by default. Use --apply to actually make changes.
#   - You will be asked to confirm the plan unless -y/--yes is provided.
#
# Usage
#   sudo ./start_of_tri_cleanup.sh                # dry run
#   sudo ./start_of_tri_cleanup.sh --apply        # apply changes after confirm
#   sudo ./start_of_tri_cleanup.sh --apply -y     # apply with no confirm
#
# Exit codes
#   0 on success, non-zero on error
#
# Notes for future students
#   - Add optional --csv path.csv to seed selections
#   - Add --keep-homes to retain home dirs on delete if desired
#   - Add directory per-project cleanup if needed (eg /srv/projects/*/users/$u)
#
set -Euo pipefail

readonly SCRIPT_VERSION="1.2.1"

# Config
JUNIOR_GROUP=${JUNIOR_GROUP:-"type-junior"}
SENIOR_GROUP=${SENIOR_GROUP:-"type-senior"}
STAFF_USER_GROUP=${STAFF_USER_GROUP:-"staff-user"}
STAFF_ADMIN_GROUP=${STAFF_ADMIN_GROUP:-"staff-admin"}
# Comma list of logins to ignore in the "ungrouped" prompt
IGNORE_USERS=${IGNORE_USERS:-"root,ubuntu"}

LOG_DIR=${LOG_DIR:-"/var/log/e8ml1"}
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/start_of_tri_cleanup_$(date +%Y%m%d_%H%M%S).log"

# Flags
APPLY=0
ASSUME_YES=0
DEBUG=0

# TTY IO targets for safe interactive prompts under sudo
TTY_IN="/dev/tty"
TTY_OUT="/dev/tty"
[[ -r "$TTY_IN" ]] || TTY_IN="/proc/self/fd/0"
[[ -w "$TTY_OUT" ]] || TTY_OUT="/proc/self/fd/1"

# ---------- util ----------
log() { echo "$(date +%F' '%T) | $*" | tee -a "$LOG_FILE" ; }
err() { echo "ERROR: $*" >&2 ; log "ERROR: $*" ; }
require_root() { if [[ ${EUID:-$(id -u)} -ne 0 ]]; then err "Run as root"; exit 1; fi }

require_bash4() {
  if [[ -z ${BASH_VERSINFO:-} || ${BASH_VERSINFO[0]} -lt 4 ]]; then
    err "Bash 4+ required"
    exit 2
  fi
}

maybe_debug() {
  if [[ $DEBUG -eq 1 ]]; then
    set -x
    PS4='+ ${BASH_SOURCE##*/}:${LINENO}: '
    log "Debug tracing enabled"
  fi
}

# Trim leading/trailing whitespace, no shell options required
trim() {
  local s="$1"
  # remove leading spaces and tabs
  s="${s#${s%%[!$'\t \r\n']*}}"
  # remove trailing spaces and tabs
  s="${s%${s##*[!$'\t \r\n']}}"
  printf '%s' "$s"
}

# shellcheck disable=SC2207
split_csv() {
  local raw="$1"; raw="${raw//,/ }"; set -- $raw || true
  local out=()
  for tok in "$@"; do
    [[ -z "$tok" ]] && continue
    # accept numbers (indices) or safe usernames [A-Za-z0-9._-]
    if [[ "$tok" =~ ^[0-9]+$ || "$tok" =~ ^[A-Za-z0-9._-]+$ ]]; then
      out+=("$tok")
    fi
  done
  printf '%s\n' "${out[@]:-}"
}

exists_group() { getent group "$1" >/dev/null 2>&1; }

# Return members as a newline list (may be empty)
get_group_members() {
  local g="$1"; local line; line=$(getent group "$g" | awk -F: '{print $4}') || true
  if [[ -z "$line" ]]; then return 0; fi
  echo "$line" | tr ',' '\n' | awk 'NF' | sort -u
}

# Human accounts: uid >= 1000 and interactive shell
get_human_users() {
  getent passwd \
    | awk -F: '$3 >= 1000 && $7 !~ /(nologin|false)/ {print $1}' \
    | sort -u
}

# set minus: prints elements in A not in B
array_minus() {
  local -A seen=()
  while IFS= read -r b; do [[ -n "$b" ]] && seen["$b"]=1; done < <(printf '%s\n' "$2")
  while IFS= read -r a; do [[ -n "$a" && -z ${seen[$a]:-} ]] && echo "$a"; done < <(printf '%s\n' "$1")
  return 0
} ]] && echo "$a"; done < <(printf '%s\n' "$1")
}

# uniq preserving order of left to right input
uniq_lines() { awk 'NF && !seen[$0]++' ; }

print_numbered() {
  local i=1
  while IFS= read -r u; do [[ -n "$u" ]] && printf "[%2d] %s\n" "$i" "$u" && ((i++)); done
}

# Read selection from a displayed list. Accepts numbers or names.
# Args: prompt, allowed_list (newline separated). Echoes newline list of chosen.
prompt_select_list() {
  local prompt="$1"; shift
  local allowed="$1"
  local allowed_arr=(); while IFS= read -r u; do [[ -n "$u" ]] && allowed_arr+=("$u"); done < <(printf '%s\n' "$allowed")
  local total=${#allowed_arr[@]}
  if (( total == 0 )); then echo ""; return 0; fi

  {
    echo
    echo "$prompt"
    print_numbered <<< "$allowed"
    echo "Enter comma separated numbers or names. 'all' selects all. Leave blank for none."
  } > "$TTY_OUT"
  local REPLY=""
  read -r REPLY < "$TTY_IN" || REPLY=""
  local in; in=$(trim "$REPLY")
  [[ -z "$in" ]] && { echo ""; return 0; }
  if [[ "$in" == "all" ]]; then printf '%s\n' "${allowed_arr[@]}"; return 0; fi

  declare -A idx_to_name=()
  local i=1; for u in "${allowed_arr[@]}"; do idx_to_name[$i]="$u"; ((i++)); done

  local chosen=()
  while IFS= read -r tok; do
    tok=$(trim "$tok")
    [[ -z "$tok" ]] && continue
    if [[ "$tok" =~ ^[0-9]+$ ]]; then
      if (( tok >= 1 && tok <= total )); then chosen+=("${idx_to_name[$tok]}"); fi
    else
      if printf '%s\n' "$allowed" | grep -Fxq -- "$tok"; then chosen+=("$tok"); fi
    fi
  done < <(split_csv "$in")

  printf '%s\n' "${chosen[@]:-}" | uniq_lines
}

confirm() {
  local msg="$1"; [[ $ASSUME_YES -eq 1 ]] && return 0
  { echo; printf "%s [y/N]: " "$msg"; } > "$TTY_OUT"
  local ans=""
  read -r ans < "$TTY_IN" || ans=""
  [[ "$ans" == "y" || "$ans" == "Y" ]]
}

safe_del_from_group() {
  local user="$1" group="$2"
  if command -v gpasswd >/dev/null 2>&1; then gpasswd -d "$user" "$group" >/dev/null 2>&1 || true; fi
  if command -v deluser >/dev/null 2>&1;  then deluser "$user" "$group" >/dev/null 2>&1 || true; fi
}

add_to_group() {
  local u="$1" g="$2"
  if [[ $APPLY -eq 1 ]]; then usermod -aG "$g" "$u"; fi
  log "ADD $u -> group $g"
}

promote_junior_to_senior() {
  local u="$1"
  if [[ $APPLY -eq 1 ]]; then
    usermod -aG "$SENIOR_GROUP" "$u"
    safe_del_from_group "$u" "$JUNIOR_GROUP"
  fi
  log "PROMOTE junior->senior: $u"
}

delete_user_account() {
  local u="$1"; local label="${2:-user}"
  if [[ $APPLY -eq 1 ]]; then
    pkill -KILL -u "$u" >/dev/null 2>&1 || true
    userdel -r "$u"
  fi
  log "DELETE $label: $u (account and home)"
}

choose_group_for_user() {
  local u="$1"
  {
    echo
    echo "Assign a group for '$u'"
    echo "  [1] $STAFF_USER_GROUP"
    echo "  [2] $STAFF_ADMIN_GROUP"
    echo "  [3] $JUNIOR_GROUP"
    echo "  [4] $SENIOR_GROUP"
    echo "  [0] Skip"
    printf "Choice: "
  } > "$TTY_OUT"
  local ch=""
  read -r ch < "$TTY_IN" || ch=""
  case "$(trim "$ch")" in
    1) echo "$u:$STAFF_USER_GROUP" ;;
    2) echo "$u:$STAFF_ADMIN_GROUP" ;;
    3) echo "$u:$JUNIOR_GROUP" ;;
    4) echo "$u:$SENIOR_GROUP" ;;
    0|"") echo "" ;;
    *) echo "" ;;
  esac
}

# ---------- main ----------
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --apply) APPLY=1; shift ;;
      -y|--yes) ASSUME_YES=1; shift ;;
      --debug) DEBUG=1; shift ;;
      -h|--help) sed -n '1,200p' "$0"; exit 0 ;;
      *) err "Unknown arg: $1"; exit 2 ;;
    esac
  done
}

main() {
  require_root
  require_bash4
  parse_args "$@"
  maybe_debug
  log "Start-of-tri cleanup v$SCRIPT_VERSION (dry-run=$((1-APPLY)))"

  # Require groups
  local req_groups=("$JUNIOR_GROUP" "$SENIOR_GROUP" "$STAFF_USER_GROUP" "$STAFF_ADMIN_GROUP")
  for g in "${req_groups[@]}"; do
    if ! exists_group "$g"; then err "Required group missing: $g"; exit 3; fi
  done

  # Load current membership
  local juniors seniors staff_users staff_admins all_staff all_humans
  juniors=$(get_group_members "$JUNIOR_GROUP")
  seniors=$(get_group_members "$SENIOR_GROUP")
  staff_users=$(get_group_members "$STAFF_USER_GROUP")
  staff_admins=$(get_group_members "$STAFF_ADMIN_GROUP")
  all_staff=$(printf '%s\n' "$staff_users" "$staff_admins" | uniq_lines)
  all_humans=$(get_human_users)

  log "Detected $(printf '%s\n' "$juniors" | awk 'NF' | wc -l) juniors"
  log "Detected $(printf '%s\n' "$seniors" | awk 'NF' | wc -l) seniors"
  log "Detected $(printf '%s\n' "$staff_users" | awk 'NF' | wc -l) staff-users"
  log "Detected $(printf '%s\n' "$staff_admins" | awk 'NF' | wc -l) staff-admins"

  # Snapshots of original membership before any stashing
  local juniors_all seniors_all staff_users_all staff_admins_all
  juniors_all="$juniors"
  seniors_all="$seniors"
  staff_users_all="$staff_users"
  staff_admins_all="$staff_admins"

  # Staff review (Step 0)
  local staff_to_demote staff_to_delete
  staff_to_demote=$(prompt_select_list "STAFF-ADMIN accounts to remove ADMIN access from:" "$staff_admins")
  staff_to_delete=$(prompt_select_list "STAFF accounts to DELETE entirely:" "$all_staff")

  # Step 1..4: dynamic stash
  local stash_repeat stash_left stash_skip stash_other
  stash_repeat=""; stash_left=""; stash_skip=""; stash_other=""

  local rj rs
  rj=$(prompt_select_list "Repeaters at JUNIOR level to stash:" "$juniors"); juniors=$(array_minus "$juniors" "$rj")
  rs=$(prompt_select_list "Repeaters at SENIOR level to stash:" "$seniors"); seniors=$(array_minus "$seniors" "$rs")
  stash_repeat=$(printf '%s\n' "$rj" "$rs" | uniq_lines)

  local lj ls
  lj=$(prompt_select_list "Users who LEFT company (JUNIORS) to stash:" "$juniors"); juniors=$(array_minus "$juniors" "$lj")
  ls=$(prompt_select_list "Users who LEFT company (SENIORS) to stash:" "$seniors"); seniors=$(array_minus "$seniors" "$ls")
  stash_left=$(printf '%s\n' "$lj" "$ls" | uniq_lines)

  local sj ss
  sj=$(prompt_select_list "Users SKIPPING this trimester (JUNIORS) to stash:" "$juniors"); juniors=$(array_minus "$juniors" "$sj")
  ss=$(prompt_select_list "Users SKIPPING this trimester (SENIORS) to stash:" "$seniors"); seniors=$(array_minus "$seniors" "$ss")
  stash_skip=$(printf '%s\n' "$sj" "$ss" | uniq_lines)

  local oj os
  oj=$(prompt_select_list "Any OTHER JUNIORS to stash:" "$juniors"); juniors=$(array_minus "$juniors" "$oj")
  os=$(prompt_select_list "Any OTHER SENIORS to stash:" "$seniors"); seniors=$(array_minus "$seniors" "$os")
  stash_other=$(printf '%s\n' "$oj" "$os" | uniq_lines)

  # Ungrouped humans (Step 5)
  local union_managed ungrouped add_assignments
  union_managed=$(printf '%s\n' "$juniors_all" "$seniors_all" "$staff_users_all" "$staff_admins_all" | uniq_lines)
  # Apply ignore list
  local ignore_list; ignore_list=$(printf '%s\n' "$IGNORE_USERS" | tr ',' '\n' | awk 'NF')
  local filtered_humans
  filtered_humans=$(array_minus "$all_humans" "$ignore_list")
  ungrouped=$(array_minus "$filtered_humans" "$union_managed")

  add_assignments=""
  if [[ -n "$ungrouped" ]]; then
    {
      echo
      echo "Ungrouped human accounts detected:"
      print_numbered <<< "$ungrouped"
    } > "$TTY_OUT"
    while IFS= read -r u; do
      [[ -z "$u" ]] && continue
      local mapping
      mapping=$(choose_group_for_user "$u")
      [[ -n "$mapping" ]] && add_assignments+="$mapping\n"
    done < <(printf '%s\n' "$ungrouped")
  fi

  # Working sets after dynamic stashing
  local seniors_to_delete juniors_to_promote
  seniors_to_delete="$seniors"
  juniors_to_promote="$juniors"

  # Plan summary (never fail under -e)
  set +e
  echo
  echo "Plan summary"
  echo "------------"
  echo "Demote staff-admin -> staff-user:"
  printf '%s\n' "$staff_to_demote" | awk 'NF{print "  "$0}'
  echo "Delete staff accounts:"
  printf '%s\n' "$staff_to_delete" | awk 'NF{print "  "$0}'
  echo "Stashed (repeaters):";     printf '%s\n' "$stash_repeat" | awk 'NF{print "  "$0}'
  echo "Stashed (left):";          printf '%s\n' "$stash_left"   | awk 'NF{print "  "$0}'
  echo "Stashed (skipping):";      printf '%s\n' "$stash_skip"   | awk 'NF{print "  "$0}'
  echo "Stashed (other):";         printf '%s\n' "$stash_other"  | awk 'NF{print "  "$0}'
  echo "Will DELETE these SENIORS:";  print_numbered <<< "$seniors_to_delete"
  echo "Will PROMOTE these JUNIORS:"; print_numbered <<< "$juniors_to_promote"
  if [[ -n "$add_assignments" ]]; then
    echo "New group assignments for ungrouped users:"
    while IFS=: read -r uu gg; do
      [[ -z "$uu" || -z "$gg" ]] && continue
      printf '  %s -> %s\n' "$uu" "$gg"
    done <<< "$add_assignments"
  else
    echo "No ungrouped user assignments"
  fi
  echo
  echo "Mode: $([[ $APPLY -eq 1 ]] && echo APPLY || echo DRY-RUN)"
  set -e

  if ! confirm "Proceed"; then log "Aborted by user"; exit 0; fi

  # Apply actions
  while IFS= read -r u; do [[ -n "$u" ]] && { safe_del_from_group "$u" "$STAFF_ADMIN_GROUP"; add_to_group "$u" "$STAFF_USER_GROUP"; log "DEMOTE staff-admin->staff-user: $u"; }; done < <(printf '%s\n' "$staff_to_demote")
  while IFS= read -r u; do [[ -n "$u" ]] && delete_user_account "$u" "staff"; done < <(printf '%s\n' "$staff_to_delete")

  if [[ -n "$add_assignments" ]]; then
    while IFS=: read -r u g; do
      [[ -z "$u" || -z "$g" ]] && continue
      add_to_group "$u" "$g"
    done <<< "$add_assignments"
  fi

  while IFS= read -r u; do [[ -n "$u" ]] && delete_user_account "$u" "senior"; done < <(printf '%s\n' "$seniors_to_delete")
  while IFS= read -r u; do [[ -n "$u" ]] && promote_junior_to_senior "$u"; done < <(printf '%s\n' "$juniors_to_promote")

  # Step 7: restore stashed users (no-op, as we never changed them)
  log "Restored stashed users (no changes were made to them)"

  # Output summary (never fail)
  set +e
  echo
  echo "Completed. Log at $LOG_FILE"
  echo
  echo "Summary"
  echo "-------"
  echo "Demoted staff-admin -> staff-user:"; printf '%s\n' "$staff_to_demote"   | awk 'NF{print "  "$0}'
  echo "Deleted staff accounts:";           printf '%s\n' "$staff_to_delete"   | awk 'NF{print "  "$0}'
  echo "Deleted seniors:";                  print_numbered <<< "$seniors_to_delete"
  echo "Promoted juniors:";                 print_numbered <<< "$juniors_to_promote"
  if [[ -n "$add_assignments" ]]; then
    echo "Assignments applied:"; while IFS=: read -r uu gg; do [[ -z "$uu" || -z "$gg" ]] && continue; printf '  %s -> %s\n' "$uu" "$gg"; done <<< "$add_assignments"
  else
    echo "Assignments applied: none"
  fi
  echo "Stashed repeaters:";                printf '%s\n' "$stash_repeat" | awk 'NF{print "  "$0}'
  echo "Stashed left-company:";             printf '%s\n' "$stash_left"   | awk 'NF{print "  "$0}'
  echo "Stashed skipping tri:";             printf '%s\n' "$stash_skip"   | awk 'NF{print "  "$0}'
  echo "Stashed other:";                    printf '%s\n' "$stash_other"  | awk 'NF{print "  "$0}'
  set -e
}

main "$@"

