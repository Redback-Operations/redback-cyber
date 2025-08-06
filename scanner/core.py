# Responsibilities:
# - Reads the target Python file and stores code lines.
# - Manages the vulnerability list.
# - Coordinates execution of all defined rule checks (e.g., SQL injection, XSS).
# - Provides an interface (`add_vulnerability`) for rules to report findings.
# - Generates a user-friendly vulnerability report after scanning.

# To extend functionality, add new rule modules to scanner/rules and call them in 

import os
from scanner.rules import sql_injection  # Import your first rule here

class VulnerabilityScanner:
    def __init__(self, file_path):
        self.file_path = file_path
        self.code_lines = []
        self.vulnerabilities = []

    def add_vulnerability(self, category, description, line, severity, confidence):
        self.vulnerabilities.append({
            "category": category,
            "description": description,
            "line": line,
            "severity": severity,
            "confidence": confidence
        })

    def parse_file(self):
        if not os.path.exists(self.file_path):
            print(f"File {self.file_path} does not exist.")
            return False
        with open(self.file_path, "r", encoding="utf-8") as f:
            self.code_lines = f.readlines()
        return True

    def run_checks(self):
        # Add each rule here
        sql_injection.check(self.code_lines, self.add_vulnerability)

    def run(self):
        if not self.parse_file():
            return
        self.run_checks()

    def report(self):
        print(f"\nScan Results for {self.file_path}:")
        if not self.vulnerabilities:
            print("✅ No vulnerabilities found.")
        else:
            for vuln in self.vulnerabilities:
                print(f"\n⚠️  {vuln['category']} at line {vuln['line']}")
                print(f"    → {vuln['description']}")
                print(f"    Severity: {vuln['severity']} | Confidence: {vuln['confidence']}")
