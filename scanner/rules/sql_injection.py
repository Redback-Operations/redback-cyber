# This module implements a check for OWASP A01: Injection vulnerabilities.

# Specifically, it searches for suspicious SQL query patterns in Python code,
# such as unparameterized queries or string concatenation in `execute()` calls.

# Function:
# - `check(code_lines, add_vulnerability)`: Accepts lines of code and a callback to report findings.
#   Uses regular expressions to detect potential SQLi and sends alerts via `add_vulnerability()`.

import re

def check(code_lines, add_vulnerability):
    sqli_patterns = [
        r'(?i)cursor\.execute\([^,]+["\'].*?(SELECT|INSERT|DELETE|UPDATE).*?["\']',
        r'(?i)execute\([^,]+["\'].*?(SELECT|INSERT|DELETE|UPDATE).*?["\']',
        r'(?i)"\s*\+\s*[\w\[]+.*\+\s*"'
    ]
    for i, line in enumerate(code_lines):
        for pattern in sqli_patterns:
            if re.search(pattern, line):
                add_vulnerability(
                    "A01: Injection",
                    f"Potential SQL injection: {line.strip()}",
                    i + 1,
                    "HIGH",
                    "HIGH"
                )
