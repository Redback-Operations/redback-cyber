# OWASP A04: Insecure Design
# Heuristics: comments or lines that indicate insecure-by-design choices.

import re

PATTERNS = [
    re.compile(r'\btodo\b.*\b(insecure|security|auth|bypass)\b', re.IGNORECASE),
    re.compile(r'\btemporary\b.*\boverride\b', re.IGNORECASE),
    re.compile(r'\bdisable(d)?\s+(auth(entication)?|authori[sz]ation)\b', re.IGNORECASE),
    re.compile(r'\bbypass(ing)?\s+(auth|security)\b', re.IGNORECASE),
]

def check(code_lines, add_vulnerability):
    for i, line in enumerate(code_lines):
        stripped = line.strip()
        # do NOT skip comments — we want to catch insecure design notes in comments too
        if any(p.search(stripped) for p in PATTERNS):
            add_vulnerability(
                "A04: Insecure Design",
                f"Potential insecure design marker: {stripped}",
                i + 1,
                "MEDIUM",
                "LOW",
            )