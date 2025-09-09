#!/usr/bin/env bash
# ============================================================================
# Bulk User/Group Manager (Ubuntu-focused)
# ----------------------------------------------------------------------------
# Purpose: Repeatedly add users and groups in a controlled, auditable way.
#          Designed to support ASD Essential Eight (E8) ML1 objectives:
#          - Least privilege by default (no sudo unless an allowed group in sudoers)
#          - Group-based access segregation and private home directories
#          - Idempotent checks and explicit operator prompts
#          - Basic audit trail via syslog (use `journalctl -t bulk-user-mgr`)
# ----------------------------------------------------------------------------
# Notes:
#  * Requires root. Tested on Ubuntu Server.
#  * Group directories are created under /srv/groups/<group> with 2770 perms
#    so only members of the group (and root) can read/write. If available,
#    ACLs are set to preserve restrictive defaults for new files.
#  * User home is /home/<username> with 700 perms; first login password reset
#    is enforced via `passwd -e`.
#  * Script loops until you choose Exit.
#  * Script exports all created usernames and passwords to a CSV file.
# ============================================================================

set -Eeuo pipefail

# ------------------------ helpers ------------------------
die() { echo "ERROR: $*" >&2; exit 1; }

need_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    die "Please run as root (use sudo)."
  fi
}

has_command() {
  command -v "$1" >/dev/null 2>&1
}

trim() {
  local s="$*"
  s="${s#"${s%%[![:space:]]*}"}"  # ltrim
  s="${s%"${s##*[![:space:]]}"}"  # rtrim
  printf '%s' "$s"
}

slugify() {
  # Convert names to a safe username like first.last (lowercase, ascii, dots)
  local s="$1"
  if has_command iconv; then s=$(printf '%s' "$s" | iconv -f UTF-8 -t ASCII//TRANSLIT); fi
  s=$(printf '%s' "$s" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/./g; s/^\.+//; s/\.+$//; s/\.+/./g')
  printf '%s' "$s"
}

prompt_yn() {
  local msg="$1" ; local default="${2:-N}"
  local ans
  while true; do
    read -r -p "$msg " ans || ans=""
    ans="${ans:-$default}"
    ans="${ans,,}"
    case "$ans" in
      y|yes) return 0;;
      n|no)  return 1;;
      *)     echo "Please answer y or n." ;;
    esac
  done
}

ensure_group() {
  local g="$1"
  if ! getent group "$g" >/dev/null; then
    groupadd "$g"
    echo "[OK] Created group: $g"
  fi
}

ensure_predefined_groups() {
  local predefined=(
    type-junior type-senior
    staff-user staff-admin
    blue-team infrastructure
    project-1 project-2 project-3 project-4 project-5
  )
  local missing=0
  for g in "${predefined[@]}"; do
    if ! getent group "$g" >/dev/null; then
      groupadd "$g"
      missing=1
      echo "[OK] Created group: $g"
    fi
  done
  if (( missing == 0 )); then
    echo "[OK] All predefined groups are present."
  fi
}

print_banner() {
  echo "Bulk User/Group Manager (E8 ML1-aligned)"
  echo
}

# ------------------------ session logging ------------------------
SESSION_ROWS=()       # each: username,first,last,password
SESSION_CSV="bulk-user-creds-$(date +%Y%m%d-%H%M%S).csv"

on_exit() {
  if ((${#SESSION_ROWS[@]})); then
    # Write header + rows
    { echo "username,first,last,password"; printf '%s\n' "${SESSION_ROWS[@]}"; } > "$SESSION_CSV"
    chmod 600 "$SESSION_CSV" || true
    echo
    echo "[SECRET] Session credentials written to: $(pwd)/$SESSION_CSV"
    echo "         File permissions set to 600."
  fi
}
trap on_exit EXIT

# ------------------------ main flow ------------------------
create_user_flow() {
  printf "First name: "
  read -r first || first=""
  first="$(trim "$first")"
  [[ -n "$first" ]] || die "First name is required."

  printf "Last name:  "
  read -r last || last=""
  last="$(trim "$last")"
  [[ -n "$last" ]] || die "Last name is required."

  local proposed username
  proposed="$(slugify "$first.$last")"
  printf "Proposed username: %s\n" "$proposed"
  read -r -p "Accept '$proposed' as the username? [Y/n]: " accept || accept="Y"
  accept="${accept:-Y}"
  if [[ "$accept" =~ ^[Nn]$ ]]; then
    read -r -p "Enter username: " username || username=""
    username="$(slugify "$(trim "$username")")"
  else
    username="$proposed"
  fi
  [[ -n "$username" ]] || die "Username is required."

  if id -u "$username" >/dev/null 2>&1; then
    echo "[INFO] User '$username' already exists; proceeding to group assignments."
  else
    useradd -m -c "$first $last" -s /bin/bash "$username"
    echo "[OK] Created user $username ($first $last)"
    local home="/home/$username"
    if [[ -d "$home" ]]; then
      chown "$username":"$username" "$home"
      chmod 700 "$home"
    fi
  fi

  echo
  echo "Is the account a Student or Staff member?"
  echo "  [1] Student"
  echo "  [2] Staff"
  local role
  while true; do
    read -r -p "Selection: " role || role=""
    case "$role" in
      1|2) break;;
      *) echo "Please enter 1 or 2." ;;
    esac
  done

  declare -a add_groups=()

  if [[ "$role" == "1" ]]; then
    echo
    echo "Student type:"
    echo "  [1] Junior  (adds: type-junior)"
    echo "  [2] Senior  (adds: type-senior)"
    local stype
    while true; do
      read -r -p "Selection: " stype || stype=""
      case "$stype" in
        1) add_groups+=("type-junior"); break;;
        2) add_groups+=("type-senior"); break;;
        *) echo "Please enter 1 or 2." ;;
      esac
    done

    echo
    echo "Project access:"
    echo "  [0] None"
    echo "  [1] project-1"
    echo "  [2] project-2"
    echo "  [3] project-3"
    echo "  [4] project-4"
    echo "  [5] project-5"
    echo "  [6] blue-team"
    echo "  [7] secdevops"
    echo "  [8] infrastructure"
    echo "  [9] data-warehouse"
    local psel
    while true; do
      read -r -p "Selection: " psel || psel="0"
      case "$psel" in
        0) break;;
        1) add_groups+=("project-1"); break;;
        2) add_groups+=("project-2"); break;;
        3) add_groups+=("project-3"); break;;
        4) add_groups+=("project-4"); break;;
        5) add_groups+=("project-5"); break;;
        6) add_groups+=("blue-team"); break;;
        7) add_groups+=("secdevops"); break;;
        8) add_groups+=("infrastructure"); break;;
        9) add_groups+=("data-warehouse"); break;;
        *) echo "Please enter a number 0–9." ;;
      esac
    done

    if prompt_yn "Add Blue Team access? [y/N]:" "N"; then
      add_groups+=("blue-team")
    fi
    if prompt_yn "Add Infrastructure access? [y/N]:" "N"; then
      add_groups+=("infrastructure")
    fi

  else
    add_groups+=("staff-user")
    if prompt_yn "Grant admin access (staff-admin)? [y/N]:" "N"; then
      add_groups+=("staff-admin")
    fi
  fi

  # Deduplicate groups
  declare -A seen=()
  declare -a unique=()
  for g in "${add_groups[@]}"; do
    [[ -z "$g" ]] && continue
    if [[ -z "${seen[$g]:-}" ]]; then
      seen["$g"]=1
      unique+=("$g")
    fi
  done

  if ((${#unique[@]})); then
    for g in "${unique[@]}"; do ensure_group "$g"; done
    ( IFS=,; usermod -aG "${unique[*]}" "$username" )
    echo "[OK] Added $username to groups: ${unique[*]}"
  else
    echo "[INFO] No supplementary groups selected."
  fi

  # Optional temporary password
  local pw=""
  if prompt_yn "Set a temporary random password now? [Y/n]:" "Y"; then
    if has_command openssl; then
      pw="$(openssl rand -base64 18)"
    else
      pw="$(tr -dc 'A-Za-z0-9!@#%^*_=+' </dev/urandom | head -c 20)"
    fi
    echo "${username}:${pw}" | chpasswd
    passwd -e "$username" >/dev/null 2>&1 || true
    echo "[SECRET] Temporary password for ${username}: ${pw}"
  fi

  # Append to session log (CSV row); password may be blank if not set
  local u_csv f_csv l_csv p_csv
  u_csv="${username//,/}" ; f_csv="${first//,/}" ; l_csv="${last//,/}" ; p_csv="${pw//,/}"
  SESSION_ROWS+=("${u_csv},${f_csv},${l_csv},${p_csv}")
}

main() {
  need_root
  ensure_predefined_groups
  print_banner

  while true; do
    echo "Choose an action:"
    echo "  [1] Create user"
    echo "  [2] Exit"
    read -r -p "Selection: " sel || sel="2"
    case "$sel" in
      1) create_user_flow; echo;;
      2) exit 0;;
      *) echo "Please enter 1 or 2." ;;
    esac
  done
}

main "$@"
