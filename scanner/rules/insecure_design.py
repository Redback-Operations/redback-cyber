# OWASP A04: Insecure Design

import re

def check(code_lines, add_vulnerability):
    for i, line in enumerate(code_lines):
        if "TODO insecure" in line.lower():
            add_vulnerability(
                "A04: Insecure Design",
                f"Potential insecure design note found: {line.strip()}",
                i + 1,
                "MEDIUM",
                "LOW"
            )
