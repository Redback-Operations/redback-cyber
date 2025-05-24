#!/usr/bin/bash

# -------------------------------------------------------------------
# File:    bak-rsync.sh
# Author:  Codey Funston [cfeng44@github.com]
# Brief:   Performs rsync backup of passed in Docker volume.
# Changelog:
#     09/04/2025: Initial creation. Not finished, only POC.
#
#     29/04/2025: Added proper date formatting for backup names.
#
#     30/04/2025: 
#                - Moved metadata to separate file.
#                - Added version rotation/deletion. 
#
#     09/05/2025 
#   - 13/05/2025: Finished ready for demo :)
# -------------------------------------------------------------------

# Default output of `date` is "Tue 29 Apr 2025 19:39:42 AEST",
# need to shorten it for dir names and remove spaces. If we consider
# the shortest development change that could make the container go
# bad we should use a date format that can keep that information. As
# such 1 hour will be the smallest increment of time for container
# versioning. A team should be careful setting it this low because
# that means that the oldest volume state will be from 3 hours prior.
# We want "day-month-year-hour" with - instead of / to not confuse 
# with path names.

BACKUPS_LOCATION="/infra/bak/volume-backups"
DOCKER_SOURCE="/var/lib/docker/volumes"
LOG_PATH="/var/log/infra/bak/rsync.log"

# Script args
vol_name="$1"
backup_description="$2"

# fmt_date=$(date +"%d-%b-%Y-%I%p") # e.g. 29-Apr-2025-10PM # note: silly way around, move year etc for sort in ll etc.
fmt_date=$(date)
src="$DOCKER_SOURCE/$vol_name/"
dst_base="$BACKUPS_LOCATION/$vol_name"

# Use: __bak_rsync_full src dst
__bak_rsync_full() {
    # The -a flag is the same as using -Dgloprt
    # Too long too explain lol, but basically is what we 
    # want to keep all the information, include all dirs,
    # etc etc etc ;)

    # To copy the volume contents but also the volume
    # directory ie keep backups neat and in order, you
    # need to do "rsync src dir" not "rsync src/ dir".
    # Incase you forget this function checks the last
    # char of the string and removes it if it is a
    # trailing slash.
    if [[ "${src: -1}" == "/" ]]; then
        src="${src::-1}"
    fi

    src=$1
    dst=$2

    rsync -a --delete $src $dst
}

# Use: __bak_rsync_snapshot link src dst
__bak_rsync_snapshot() {
    if [[ "${src: -1}" == "/" ]]; then
        src="${src::-1}"
    fi

    link=$1
    src=$2
    dst=$3

    rsync -a --delete --link-dest=$link $src $dst
}

log_og() {
    vol_name=$1
    dst=$2
    echo "[$fmt_date] First copy of volume: $vol_name at: $dst" >> "$LOG_PATH"
}

log_snap() {
    vol_name=$1
    dst=$2
    echo "[$fmt_date] Snapshot of volume: $vol_name at: $dst" >> "$LOG_PATH"
}

# +-----------------------------+
# | First time for a container: |
# |         (Full copy)         |
# +-----------------------------+

og="$dst_base/readonly_original"
if [[ ! -d "$og" ]]; then
    mkdir -p $og
    __bak_rsync_full $src $og
    log_og $vol_name $og

# +----------------------------+
# |      Consecutive times     |
# |       (Snapshot only)      |
# +----------------------------+

else 
    dst="$dst_base/$fmt_date"
    mkdir -p $dst
    __bak_rsync_snapshot $og $src $dst
    log_snap $vol_name $dst
fi