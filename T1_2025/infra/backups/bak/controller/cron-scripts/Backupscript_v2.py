#!/usr/bin/env python3

# Backup script with disk space check, auto backup, and email notifications

import os
import sys
import shutil
import subprocess
from datetime import datetime
from emailnotify import send_email # Ensure this module is in the same directory

# Settings
home_dir = os.path.expanduser("~")
source_dir = os.path.join(home_dir, "testdata")
backup_root = os.path.join(home_dir, "backup", "snapshots")
previous_versions_dir = os.path.join(home_dir, "backup", "previous_versions")
last_snapshot_record = os.path.join(home_dir, "backup", "last_snapshot.txt")
max_snapshots = 3  # Max number of snapshots to retain
disk_threshold_percent = 10  # Minimum % free space required to run backup

# Create necessary directories
os.makedirs(backup_root, exist_ok=True)
os.makedirs(previous_versions_dir, exist_ok=True)

# Check disk space before backup
def check_disk_space(path, threshold):
    total, used, free = shutil.disk_usage(path)
    free_percent = free / total * 100

    if free_percent < threshold:
        raise RuntimeError(f"Not enough disk space for backup! Only {free_percent:.2f}% free.")
    else:
        print(f"Disk space check passed: {free_percent:.2f}% free.")

def take_snapshot():
    current_time = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
    new_backup_path = os.path.join(backup_root, current_time)

    # Check for previous snapshot for hard-linking
    if os.path.exists(last_snapshot_record):
        with open(last_snapshot_record, 'r') as f:
            previous_snapshot_path = f.read().strip()
        link_dest_option = f"--link-dest={previous_snapshot_path}"
    else:
        link_dest_option = None

    # Create new backup directory
    os.makedirs(new_backup_path, exist_ok=True)

    # Build rsync command
    rsync_command = [
        "rsync", "-a", "--delete", "--backup",
        f"--backup-dir={os.path.join(previous_versions_dir, current_time)}"
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
        raise RuntimeError(f"Snapshot failed: {e}")

def cleanup_old_snapshots():
    snapshots = sorted(os.listdir(backup_root))
    if len(snapshots) >= max_snapshots:
        oldest_snapshot = snapshots[0]
        oldest_snapshot_path = os.path.join(backup_root, oldest_snapshot)
        try:
            subprocess.run(["rm", "-rf", oldest_snapshot_path], check=True)
            print(f"Deleted oldest snapshot: {oldest_snapshot_path}")
        except subprocess.CalledProcessError as e:
            raise RuntimeError(f"Failed to delete oldest snapshot: {e}")
    else:
        print(f"No need to delete snapshots. Current count: {len(snapshots)}")

def main():
    try:
        check_disk_space(path=backup_root, threshold=disk_threshold_percent)
        take_snapshot()
        cleanup_old_snapshots()

        # Send success email
        send_email(
            subject="Backup Successful",
            body=f"Backup and cleanup completed successfully at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}.",
            to_email="recipient-email@example.com"  # Replace with actual team email
        )

    except Exception as e:
        # Send failure email
        send_email(
            subject="Backup Failed",
            body=f"Backup or cleanup failed at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}.\n\nError Details:\n{str(e)}",
            to_email="recipient-email@example.com"
        )
        print(f"Error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
