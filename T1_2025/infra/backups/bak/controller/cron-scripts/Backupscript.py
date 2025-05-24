#!/usr/bin/env python3

# This script handles taking a new backup and cleaning old backups (oldest one if count >= 3)

import os
import sys
import subprocess
from datetime import datetime
from email_notify import send_email  # Make sure this file exists!

# Settings
source_dir = "/var/lib/docker/volumes"
backup_root = "/home/susmitha/backup/snapshots"
previous_versions_dir = "/home/susmitha/backup/previous_versions"
last_snapshot_record = "/home/susmitha/backup/last_snapshot.txt"
max_snapshots = 3  # Number of snapshots to keep before deleting oldest

# Create necessary directories if they do not exist
os.makedirs(backup_root, exist_ok=True)
os.makedirs(previous_versions_dir, exist_ok=True)

def take_snapshot():
    current_time = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
    new_backup_path = os.path.join(backup_root, current_time)

    # Check if previous snapshot exists for hard-linking
    if os.path.exists(last_snapshot_record):
        with open(last_snapshot_record, 'r') as f:
            previous_snapshot_path = f.read().strip()
        link_dest_option = f"--link-dest={previous_snapshot_path}"
    else:
        link_dest_option = None

    # Create the new backup directory
    os.makedirs(new_backup_path, exist_ok=True)

    # Build rsync command
    rsync_command = [
        "rsync", "-a", "--delete", "--backup",
        f"--backup-dir={previous_versions_dir}/{current_time}"
    ]

    if link_dest_option:
        rsync_command.append(link_dest_option)

    rsync_command += [f"{source_dir}/", f"{new_backup_path}/"]

    try:
        subprocess.run(rsync_command, check=True)
        with open(last_snapshot_record, 'w') as f:
            f.write(new_backup_path)
        print(f"Snapshot taken successfully at {new_backup_path}")
    except subprocess.CalledProcessError as e:
        print(f"Snapshot failed: {e}")
        sys.exit(1)

def cleanup_old_snapshots():
    snapshots = sorted(os.listdir(backup_root))

    if len(snapshots) >= max_snapshots:
        oldest_snapshot = snapshots[0]
        oldest_snapshot_path = os.path.join(backup_root, oldest_snapshot)
        try:
            subprocess.run(["rm", "-rf", oldest_snapshot_path], check=True)
            print(f"Deleted oldest snapshot: {oldest_snapshot_path}")
        except subprocess.CalledProcessError as e:
            print(f"Failed to delete oldest snapshot: {e}")
            sys.exit(1)
    else:
        print(f"No need to delete snapshots. Current count: {len(snapshots)}")

def main():
    try:
        take_snapshot()
        cleanup_old_snapshots()

        # Send success email
        send_email(
            subject="Backup Successful",
            body=f"Backup and cleanup completed successfully at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}.",
            to_email="recipient-email@example.com"  # Replace with your real team email
        )

    except Exception as e:
        # Send failure email
        send_email(
            subject="Backup Failed",
            body=f"Backup or cleanup failed at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}.\n\nError Details:\n{str(e)}",
            to_email="recipient-email@example.com"  # Replace with your real team email
        )
        sys.exit(1)

if __name__ == "__main__":
    main()
