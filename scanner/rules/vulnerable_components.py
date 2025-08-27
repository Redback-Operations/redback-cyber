# OWASP A06: Vulnerable and Outdated Components
# Placeholder rule: looks for requirements with outdated versions.

import re

def check(code_lines, add_vulnerability):
    for i, line in enumerate(code_lines):
        if "==" in line and ("django" in line.lower() or "flask" in line.lower()):
            add_vulnerability(
                "A06: Vulnerable and Outdated Components",
                f"Dependency pin detected (manual review required): {line.strip()}",
                i + 1,
                "MEDIUM",
                "LOW"
            )
