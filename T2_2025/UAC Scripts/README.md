# Redback User Access Control Scripts

This repository contains a suite of Bash scripts designed to support basic user and group management for lab-scale Linux environments, particularly those aligned with ASD Essential 8 Maturity Level 1 (ML1) baselines. The scripts were created as part of a postgraduate cybersecurity project, with the aim of enforcing least privilege, simplifying administrative overhead, and enabling consistent reproducibility of access control environments.

---

## Installation

To use these scripts system-wide without calling them directly via path, you can install them to a directory in your `$PATH`, such as `/usr/local/bin`:

```bash
sudo install -m 0755 bulk-user-group-manager.sh /usr/local/bin/bulk-user-group-manager
sudo install -m 0755 group-manager.sh /usr/local/bin/group-manager
sudo install -m 0755 cleanup.sh /usr/local/bin/cleanup-users
```

This will allow you to call the tools simply as:

```bash
sudo bulk-user-group-manager
sudo group-manager
sudo cleanup-users
```

> You can change the target directory if needed; just ensure it’s included in your `$PATH` and accessible to the appropriate users.

---

## Scripts Overview

- `bulk-user-group-manager.sh` — Interactive CLI for managing user accounts, creating users with sensible defaults, and assigning them to predefined groups.
- `group-manager.sh` — *(WIP)* Script to validate, create, and manage group privileges and shared directories.
- `cleanup.sh` — *(WIP)* Script to clean up user accounts and restore the environment to a base state.

---

## `bulk-user-group-manager.sh`

This script is the primary tool for creating individual user accounts via an interactive prompt. It enforces username sanitisation, sets up home directories with secure permissions, assigns supplementary groups, and logs created credentials for administrative reference.

### Features

- **Interactive CLI** with username confirmation
- **Username slugification** to prevent invalid account names
- **Secure default permissions** for home directories (`700`)
- **First login password reset enforced**
- **Optional group assignment** during creation
- **Session summary** including usernames and temporary passwords
- **Credential log output** to a file (defaults to `created_users_<timestamp>.csv`)

### Usage

```bash
sudo ./bulk-user-group-manager.sh
```

Or, once installed as described in the Installation section:

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

### Security Notes

- Passwords are randomly generated and **only output once** to the admin.
- Output CSV is saved with `600` permissions and should be manually secured or deleted.
- You can enforce root-only access to this log file:
  ```bash
  sudo chown root:root created_users_2025-09-04.csv
  sudo chmod 600 created_users_2025-09-04.csv
  ```

---

## `group-manager.sh` *(Work in Progress)*

This script will:

- Check for predefined groups and create any that are missing
- Ensure group-shared directories exist and have correct permissions
- Apply privilege escalation rules via `sudoers` on a per-group basis
- Provide a menu to modify group privileges, either through:
  - Comma-separated custom commands
  - Selection from predefined allowed command sets

 *Usage, examples, and detailed implementation to be added.*

---

## `cleanup.sh` *(Work in Progress)*

This script will:

- Remove all users and/or groups except core administrative accounts
- Optionally remove home directories and shared folders
- Reset sudoers and access controls to a clean baseline

 *Usage and examples to be added.*

---

##  File Structure

```text
.
├── bulk-user-group-manager.sh   # Interactive user creation tool
├── group-manager.sh             # Group validation and sudo policy tool (WIP)
├── cleanup.sh                   # Environment cleanup utility (WIP)
├── created_users_*.csv          # Output logs of created users and passwords
└── README.md                    # This file
```

---

##  Assumptions

This script assumes the administrator has:

- Sudo/root access on a Linux system (Debian/Ubuntu tested)
- Familiarity with UNIX permissions, `passwd`, `usermod`, and `sudoers`
- Understanding of secure access control and ASD Essential 8 ML1 principles

Scripts were tested against Ubuntu 22.04 LTS, but should work with minimal modifications on other modern Linux distributions.

---

##  Licence and Attribution

This project is for educational and lab-use purposes only. No warranty is provided for production deployments. Authored by Kim Brvenik.

---

##  Roadmap

- [ ] Finalise `group-manager.sh` with sudoer editing functionality
- [ ] Implement `cleanup.sh` safely with confirmation checks
- [ ] Add automated test harness for validation in CI environments
- [ ] Package as `.deb` or `.rpm` for easier installation
- [ ] Add csv import function to bulk user group manager

