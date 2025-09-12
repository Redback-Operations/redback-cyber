#!/usr/bin/env bash
# E8 ML1 Group Manager
# -------------------------------------------------------------
# This script helps you:
#  1) Check for default groups and offer to create any missing
#  2) Ensure a per-group shared dir restricted to group members
#  3) Enforce default least-privilege (only staff-admin is sudoers by default)
#  4) Create new groups
#  5) Grant/modify limited sudo privileges for a group via text input
#     (comma-separated command paths) or a curated multiple-choice menu
#  6) Validate sudoers changes with visudo before enabling them
# -------------------------------------------------------------
# Tested on: Ubuntu 20.04/22.04/24.04 (should work broadly on systemd distros)

set -Eeuo pipefail # nounset is on; keep variables initialized

# ========================= CONFIG ============================
# Base path for per-group shared directories
BASE_DIR="/srv/groups"

# Default groups you expect to exist in this environment
# Adjust this list to match your org. These are sensible starters for E8 ML1.
DEFAULT_GROUPS=(
  staff-admin
  staff-user
  type-junior
  type-senior
  blue-team
  infrastructure
  secdevops
  data-warehouse
  project-1
  project-2
  project-3
  project-4
  project-5
)

# Curated catalog of commonly granted admin/helper commands. The script will
# resolve only those actually present on the host. Extend to suit your stack.
CANDIDATE_NAMES=(
  systemctl
  service
  journalctl
  tail
  less
  cat
  dmesg
  ip
  ss
  ufw
  docker
  podman
)
# Predeclare to avoid nounset (-u) surprises when referencing length
declare -a CANDIDATE_CMDS=()

# Sudoers configuration
SUDOERS_DIR="/etc/sudoers.d"
SUDOERS_PREFIX="grp-"             # Files will be /etc/sudoers.d/grp-<group>
REQUIRE_PASSWORD_DEFAULT=1         # 1=require password, 0=NOPASSWD

# =============================================================

log()  { printf "%s\n" "$*"; }
ok()   { printf "[OK] %s\n" "$*"; }
warn() { printf "[WARN] %s\n" "$*"; }
err()  { printf "[ERROR] %s\n" "$*" 1>&2; }

need_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    err "This script must be run as root."; exit 1
  fi
}

need_bins() {
  local missing=()
  local req=(getent groupadd gpasswd visudo install mkdir chmod chgrp)
  for b in "${req[@]}"; do
    command -v "$b" >/dev/null 2>&1 || missing+=("$b")
  done
  if ((${#missing[@]})); then
    err "Missing required utilities: ${missing[*]}"; exit 1
  fi
}

trim() { # usage: trimmed=$(trim "  text  ")
  local s="$*"; s="${s##+([[:space:]])}"; s="${s%%+([[:space:]])}"; printf '%s' "$s"
}

press_enter() { read -r -p $'Press Enter to continue… ' _ || true; }

ensure_base_dir() {
  if [[ ! -d "$BASE_DIR" ]]; then
    mkdir -p "$BASE_DIR"
    chmod 0755 "$BASE_DIR"
    ok "Created $BASE_DIR"
  fi
}

valid_group_name() {
  # POSIX-ish group name: start alpha/underscore, then alnum/_/-
  [[ "$1" =~ ^[a-z_][a-z0-9_-]*$ ]]
}

ensure_group() {
  local grp="$1"
  if getent group "$grp" >/dev/null; then
    ok "Group exists: $grp"
  else
    groupadd "$grp"
    ok "Created group: $grp"
  fi
}

ensure_shared_dir() {
  local grp="${1:-}" dir
  if [[ -z "$grp" ]]; then err "ensure_shared_dir: missing group name"; return 1; fi
  dir="$BASE_DIR/$grp"
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
    ok "Created $dir"
  fi
  chgrp "$grp" "$dir"
  chmod 2770 "$dir"      # setgid for consistent group on new files
  if command -v setfacl >/dev/null 2>&1; then
    setfacl -d -m g:"$grp":rwx "$dir" || true
    setfacl -m g:"$grp":rwx "$dir" || true
  fi
  ok "Secured shared dir $dir (root:$grp, 2770, default ACL if available)"
}

resolve_cmd() {
  local p
  p=$(command -v -- "$1" 2>/dev/null || true)
  [[ -n "$p" ]] && printf '%s' "$p"
}

build_candidates() {
  CANDIDATE_CMDS=()
  local p
  for n in "${CANDIDATE_NAMES[@]}"; do
    p=$(resolve_cmd "$n" || true)
    [[ -n "$p" ]] && CANDIDATE_CMDS+=("$p")
  done
}

summary_sudoers_line() {
  local grp="$1"; shift
  local cmds=("$@")
  local npfx=""
  (( REQUIRE_PASSWORD_DEFAULT == 0 )) && npfx="NOPASSWD: "
  local line="%${grp} ALL=(root) ${npfx}"
  local first=1
  local c
  for c in "${cmds[@]}"; do
    if (( first )); then line+="$c"; first=0; else line+=", $c"; fi
  done
  printf '%s
' "$line"
}

install_sudoers_file() {
  local grp="$1"; shift
  local cmds=("$@")
  local tmp
  tmp=$(mktemp)
  local npfx=""; (( REQUIRE_PASSWORD_DEFAULT == 0 )) && npfx="NOPASSWD: "

  {
    printf '%s
' "# Managed by E8 ML1 Group Manager"
    printf '%s
' "# Grant limited commands to group: $grp"
    printf '%%%s ALL=(root) %s' "$grp" "$npfx"
    local first=1 c
    for c in "${cmds[@]}"; do
      if (( first )); then printf '%s' "$c"; first=0; else printf ', %s' "$c"; fi
    done
    printf '
'
  } >"$tmp"

  # Validate standalone syntax and show helpful error if it fails
  local visout
  if ! visout=$(visudo -cf "$tmp" 2>&1); then
    err "visudo validation failed for proposed sudoers snippet. Aborting."
    printf '
----- visudo output -----
%s
-------------------------
' "$visout" 1>&2
    printf '
----- snippet content -----
' 1>&2
    nl -ba "$tmp" 1>&2 || true
    rm -f "$tmp"; return 1
  fi

  local dest="$SUDOERS_DIR/${SUDOERS_PREFIX}${grp}"
  local backup="${dest}.bak.$(date +%Y%m%d-%H%M%S)"
  if [[ -f "$dest" ]]; then
    cp -a "$dest" "$backup"
    ok "Backed up existing sudoers to $backup"
  fi

  install -m 0440 "$tmp" "$dest"
  rm -f "$tmp"

  # Validate the whole config including includes
  if ! visudo -cf /etc/sudoers >/dev/null 2>&1; then
    err "Global visudo check failed after install — rolling back."
    [[ -f "$backup" ]] && install -m 0440 "$backup" "$dest" || rm -f "$dest"
    return 1
  fi

  ok "Sudoers updated: $dest"
}

ensure_staff_admin_full_sudo() {
  local grp="staff-admin"
  if ! getent group "$grp" >/dev/null; then
    warn "Expected group '$grp' does not exist yet; creating it."
    ensure_group "$grp"
  fi
  local dest="$SUDOERS_DIR/${SUDOERS_PREFIX}${grp}"
  if [[ -f "$dest" ]] && grep -qE '^%staff-admin\s+ALL=\(ALL(:ALL)?\)\s+ALL\s*$' "$dest"; then
    ok "staff-admin already has full admin privileges"
    return 0
  fi
  local tmp
  tmp=$(mktemp)
  {
    echo "# Managed by E8 ML1 Group Manager"
    echo "# Full administrative privileges for staff-admin"
    echo "%staff-admin ALL=(ALL:ALL) ALL"
  } >"$tmp"
  if ! visudo -cf "$tmp" >/dev/null 2>&1; then
    rm -f "$tmp"; err "Could not validate staff-admin sudoers snippet"; return 1
  fi
  install -m 0440 "$tmp" "$dest"; rm -f "$tmp"
  if visudo -cf /etc/sudoers >/dev/null 2>&1; then
    ok "Enforced full admin privileges for %staff-admin"
  else
    err "Global visudo check failed after staff-admin install"; return 1
  fi
}

check_defaults_flow() {
  ensure_base_dir

  local missing=()
  local g
  for g in "${DEFAULT_GROUPS[@]}"; do
    if getent group "$g" >/dev/null 2>&1; then
      ok "Group present: $g"
    else
      warn "Missing group: $g"
      missing+=("$g")
    fi
  done

  if ((${#missing[@]})); then
    log "
The following default groups are missing:"
    printf '  - %s
' "${missing[@]}"
    read -r -p $'Create missing groups now? [Y/n]: ' ans
    ans=${ans:-Y}
    if [[ "$ans" =~ ^[Yy]$ ]]; then
      for g in "${missing[@]}"; do
        ensure_group "$g"
      done
    else
      warn "Skipped creating missing groups"
    fi
  fi

  # Ensure shared dirs for all default groups
  for g in "${DEFAULT_GROUPS[@]}"; do
    if getent group "$g" >/dev/null 2>&1; then
      ensure_shared_dir "$g"
    fi
  done

  # Enforce staff-admin full admin
  ensure_staff_admin_full_sudo

  # Optional audit: warn if other group sudoers snippets exist
  shopt -s nullglob
  local f base grp
  local others=()
  for f in "$SUDOERS_DIR"/"${SUDOERS_PREFIX}"*; do
    base=$(basename -- "$f")
    grp="${base#${SUDOERS_PREFIX}}"
    if [[ -n "$grp" && "$grp" != "staff-admin" ]]; then
      others+=("$grp ($f)")
    fi
  done
  shopt -u nullglob

  if ((${#others[@]})); then
    warn "Found sudoers snippets for non-staff-admin groups:"
    printf '  - %s
' "${others[@]}"
  fi
}

create_new_group_flow() {
  read -r -p "New group name: " grp
  grp=$(trim "$grp")
  if [[ -z "$grp" ]]; then err "No group name supplied"; return 1; fi
  if ! valid_group_name "$grp"; then err "Invalid group name: $grp"; return 1; fi
  ensure_group "$grp"
  ensure_shared_dir "$grp"
}

modify_privs_flow() {
  read -r -p "Group to modify: " grp
  grp=$(trim "$grp")
  if [[ -z "$grp" ]]; then err "No group supplied"; return 1; fi
  if ! getent group "$grp" >/dev/null; then err "Group does not exist: $grp"; return 1; fi

  log $'\nChoose input method:'
  log "  [1] Type commands (comma-separated)."
  log "  [2] Multiple choice from curated catalog."
  read -r -p "Selection [1/2]: " mode; mode=${mode:-1}

  local selected=()
  if [[ "$mode" == "1" ]]; then
    cat <<'TIP'
Enter command *paths* (absolute), comma-separated. Examples:
  /bin/systemctl, /usr/bin/journalctl
If you enter bare names, the script will attempt to resolve with `command -v`.
TIP
    read -r -p "Commands: " line
    IFS=',' read -r -a raw <<<"$line"
    for item in "${raw[@]}"; do
      local t; t=$(trim "$item")
      [[ -z "$t" ]] && continue
      if [[ "$t" != /* ]]; then
        # try to resolve name -> path
        local r; r=$(resolve_cmd "$t" || true)
        if [[ -n "$r" ]]; then t="$r"; else warn "Could not resolve '$t' — skipping"; continue; fi
      fi
      selected+=("$t")
    done
  else
    build_candidates
    if ((${#CANDIDATE_CMDS[@]}==0)); then
      err "No candidate commands found on this host. Add items to CANDIDATE_NAMES."; return 1
    fi
    log $'\nAvailable commands:'
    local i=1
    for c in "${CANDIDATE_CMDS[@]}"; do printf "  %2d) %s\n" "$i" "$c"; ((i++)); done
    read -r -p $'Enter numbers (comma-separated): ' picks
    IFS=',' read -r -a nums <<<"$picks"
    for n in "${nums[@]}"; do
      n=$(trim "$n")
      [[ -z "$n" ]] && continue
      if [[ "$n" =~ ^[0-9]+$ ]] && (( n>=1 && n<=${#CANDIDATE_CMDS[@]} )); then
        selected+=("${CANDIDATE_CMDS[$((n-1))]}")
      else
        warn "Skipping invalid choice: $n"
      fi
    done
  fi

  if ((${#selected[@]}==0)); then err "No commands selected"; return 1; fi

  read -r -p "Require password when using sudo? [Y/n]: " pw; pw=${pw:-Y}
  if [[ "$pw" =~ ^[Yy]$ ]]; then REQUIRE_PASSWORD_DEFAULT=1; else REQUIRE_PASSWORD_DEFAULT=0; fi

  log $'\nAbout to grant the following:'
  summary_sudoers_line "$grp" "${selected[@]}"
  read -r -p "Proceed? [y/N]: " go; go=${go:-N}
  if [[ ! "$go" =~ ^[Yy]$ ]]; then warn "Aborted by user"; return 1; fi

  install_sudoers_file "$grp" "${selected[@]}"
}

menu() {
  while true; do
    cat <<MENU

E8 ML1 Group Manager
---------------------
[1] Check & ensure defaults (groups, shared dirs, staff-admin sudo)
[2] Create new group
[3] Modify group privileges (sudoers)
[4] Exit
MENU
    read -r -p "Selection: " sel
    case "${sel:-1}" in
      1) if ! check_defaults_flow; then warn "Defaults check failed"; fi; press_enter ;;
      2) if ! create_new_group_flow; then warn "Group creation failed"; fi; press_enter ;;
      3) if ! modify_privs_flow; then warn "Privilege modification failed"; fi; press_enter ;;
      4) exit 0 ;;
      *) warn "Invalid selection" ;;
    esac
  done
}

main() {
  need_root
  need_bins
  menu
}

main "$@"

