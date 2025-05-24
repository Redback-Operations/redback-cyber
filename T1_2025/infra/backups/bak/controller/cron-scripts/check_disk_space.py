#!/usr/bin/env python3

import shutil
import sys

def check_disk_space(path="/backup", threshold=10):
    total, used, free = shutil.disk_usage(path)
    free_percent = free / total * 100

    if free_percent < threshold:
        print(f"Not enough disk space for backup! Only {free_percent:.2f}% free.")
        sys.exit(1)
    else:
        print(f"Enough space available: {free_percent:.2f}% free")

if __name__ == "__main__":
    check_disk_space()
