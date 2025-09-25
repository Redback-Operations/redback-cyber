# Redback User Access Control Scripts

This repository contains a suite of Bash scripts designed to support basic user and group management for lab-scale Linux environments, particularly those aligned with ASD Essential 8 Maturity Level 1 (ML1) baselines. The scripts were created as part of a postgraduate cybersecurity project, with the aim of enforcing least privilege, simplifying administrative overhead, and enabling consistent reproducibility of access control environments.

---

##  Installation

To use these scripts system-wide without calling them directly via path, you can install them to a directory in your `$PATH`, such as `/usr/local/bin`:

```bash
sudo install -m 0755 bulk-user-group-manager.sh /usr/local/bin/bulk-user-group-manager
sudo install -m 0755 group-manager.sh /usr/local/bin/group-manager
sudo install -m 0755 start-of-tri-cleanup.sh /usr/local/bin/start-of-tri-cleanup
```

This will allow you to call the tools simply as:

```bash
sudo bulk-user-group-manager
sudo group-manager
sudo start-of-tri-cleanup
```

>  You can change the target directory if needed; just ensure it’s included in your `$PATH` and accessible to the appropriate users.

---

## Scripts Overview

- `bulk-user-group-manager.sh` — Interactive CLI for managing user accounts, creating users with sensible defaults, and assigning them to predefined groups.
- `group-manager.sh` — Script to validate, create, and manage group privileges and shared directories.
- `start-of-tri-cleanup.sh` — Script to clean up user accounts and restore the environment to a base state (WIP).

---

## `bulk-user-group-manager.sh`

This script is the primary tool for creating individual user accounts via an interactive prompt. It enforces username sanitisation, sets up home directories with secure permissions, assigns supplementary groups, and logs created credentials for administrative reference.

###  Features

- **Interactive CLI** with username confirmation
- **Username slugification** to prevent invalid account names
- **Secure default permissions** for home directories (`700`)
- **First login password reset enforced**
- **Optional group assignment** during creation
- **Session summary** including usernames and temporary passwords
- **Credential log output** to a file (defaults to `created_users_<timestamp>.csv`)

### Usage

```bash
sudo bulk-user-group-manager
```

You will be presented with a menu:

```
Bulk User/Group Manager (E8 ML1-aligned)

Choose an action:
  [1] Create user
  [2] Create group
  [3] Import users from CSV
  [4] Exit
```

> **Note**: CSV import is currently disabled. Future revisions may restore this functionality.

#### Example Workflow

```bash
First name: Ben
Last name: Stephens
Proposed username: ben.stephens
Accept 'ben.stephens' as the username? [Y/n]: y
Select supplementary groups for ben.stephens (optional): staff-admin
```

The script will:
- Create the user `ben.stephens`
- Set the home directory to `/home/ben.stephens` with `700` permissions
- Generate a temporary password and force a password reset
- Assign the user to `staff-admin` (if the group exists)
- Log the credentials in a timestamped output file

### 🔒 Security Notes

- Passwords are randomly generated and **only output once** to the admin.
- Output CSV is saved with `600` permissions and should be manually secured or deleted. **Note:** This is currently commented out; I have had issues accessing the file when created with 600 permissions so this is a high-priority fix for future trimesters.
- You can enforce root-only access to this log file:
  ```bash
  sudo chown root:root created_users_2025-09-04.csv
  sudo chmod 600 created_users_2025-09-04.csv
  ```

---

## `group-manager.sh`

This script checks for the existence of default groups aligned with E8 ML1 conventions, offers to create any that are missing, and allows administrators to assign sudo privileges to groups via multiple selection options or custom commands.

###  Features

- **Predefined group check** with feedback
- **Group creation** for any missing entries
- **Interactive sudo rules assignment**
  - Select from a list of known command sets
  - Or enter custom comma-separated sudo rules
- **Shared folder structure planning** *(future enhancement)*

### Usage

```bash
sudo group-manager
```

You'll be prompted to confirm creation of missing groups and then offered two ways to assign sudo access:

1. Choose from a list of common command groups
2. Enter a comma-separated list of binaries manually (e.g., `/sbin/shutdown,/usr/bin/apt`)

> ✳ Useful when preparing per-group sudoers files under `/etc/sudoers.d/`

### Default Groups

The following groups are assumed as part of your base configuration:

```
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
```

You can modify this list in the script header if needed.

Note that the staff-admin group is intended to be used in conjunction with the staff-user group; i.e., anyone in the staff-admin group should also be staff-user

---

##  `start-of-tri-cleanup.sh` *(Work in Progress)*

This script is designed to automate cleanup at the start of a new trimester, supporting temporary stashing, deletion, or promotion of user accounts depending on their status.

>  Still undergoing testing and error handling improvements.

###  Features

- **Detects and categorises** user accounts by group type
- **Interactive exclusions** for:
  - Repeating students (stashed)
  - Students no longer participating (deleted)
  - Staff accounts (optional delete)
  - Manual overrides (excluded from batch operations)
- **Promotes juniors to seniors**
- **Deletes remaining seniors**
- **Restores previously stashed users**

### Usage

```bash
sudo start-of-tri-cleanup
```

You’ll be walked through four confirmation steps:

1. Identify and stash repeaters (junior/senior)
2. Remove students no longer enrolled
3. Exclude students not participating this trimester
4. Manual exclusion of any other accounts

Once filtered, the script will:
- Promote juniors → seniors
- Delete all non-excluded seniors
- Restore any previously stashed users

>  A dry-run mode is available for testing. Full auditing and logging is planned for future versions.

---

## File Structure

```text
.
├── bulk-user-group-manager.sh   # Interactive user creation tool
├── group-manager.sh             # Group validation and sudo policy tool
├── start-of-tri-cleanup.sh                   # Environment cleanup utility (WIP)
├── created_users_*.csv          # Output logs of created users and passwords
└── README.md                    # This file
```

---

## Assumptions

This script assumes the administrator has:

- Sudo/root access on a Linux system (Debian/Ubuntu tested)
- Familiarity with UNIX permissions, `passwd`, `usermod`, and `sudoers`
- Understanding of secure access control and ASD Essential 8 ML1 principles

Scripts were tested against Ubuntu 22.04 LTS, but should work with minimal modifications on other modern Linux distributions.

---

## Licence and Attribution

This project is for educational and lab-use purposes only. No warranty is provided for production deployments. Authored by Kim Brvenik (Anonixiate on GitHub).

---

## 🚀 Roadmap

- [ ] Fix user password csv permissions issues
- [ ] Finalise and debug `start-of-tri-cleanup.sh` for stable use
- [ ] Add specific sudoers commands to `group-manager.sh`
- [ ] Add automated test harness for validation in CI environments
- [ ] Package as `.deb` or `.rpm` for easier installation?
