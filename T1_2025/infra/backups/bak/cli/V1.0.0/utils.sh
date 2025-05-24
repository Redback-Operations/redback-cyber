#!/bin/bash

COL_RED="\033[1;31m"
COL_RESET="\033[0m"

CONTROLLER_DNS="sec.redback.it.deakin.edu.au"
PORT=4444

# Print script usage
usage() {
    echo ""
    echo "Usage: bak COMMAND"
    echo ""
    echo "Automated backup and rollback management for containers"
    echo ""
    echo "Commands:"
    echo "  register        Register an instance with a policy."
    echo "  update          Update an instance's policy."
    echo "  version         Get an instance's version history."
    echo "  rollback        Rollback an instance to a previous version."
    echo ""
    echo "Global Flags:"
    echo "  -h, --help      Show this help message."
    echo "  -v, --version   Show version."
    echo ""
    echo "Run bak COMMAND --help for information on that command."
}

# Print error message ($1) to stderr with red text, and exit failure.
err() {
    printf "${COL_RED}$1${COL_RESET}\n" >&2
    exit 0
}

# Checking for global flags
case "$1" in
    -h|--help)
        usage
        exit 0
        ;;

    -v|--version)
        echo "$VERSION"
        exit 0
        ;;

    # Catches syntax errors for flags
    -*)
        echo "Unknown flag: $1"
        usage
        exit 1
        ;;
esac
