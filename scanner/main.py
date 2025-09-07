# Entry point for the OWASP PR Scanner CLI tool.
# This script parses the command-line arguments (i.e., the file path to scan),
# initializes the VulnerabilityScanner with the specified file, runs all rule checks,
# and prints a formatted vulnerability report to the console.


import argparse
from scanner.core import VulnerabilityScanner


def main():
    parser = argparse.ArgumentParser(description="OWASP PR Vulnerability Scanner")
    parser.add_argument("path", help="Path to Python file to scan")
    args = parser.parse_args()

    scanner = VulnerabilityScanner(args.path)
    scanner.run()
    scanner.report()

if __name__ == "__main__":
    main()
