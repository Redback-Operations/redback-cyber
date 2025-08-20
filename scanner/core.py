# Responsibilities:
# - Reads target file, stores code lines
# - Manages vulnerability list
# - Runs all rule checks
# - Provides add_vulnerability callback
# - Prints a simple report

import os
from scanner.rules import sql_injection, broken_access_control, security_misconfig, sensitive_data_exposure, auth_failures

RULE_MODULES = [
    sql_injection,
    broken_access_control,
    security_misconfig,
    sensitive_data_exposure,
    auth_failures,
]

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
            "confidence": confidence,
        })

    def parse_file(self):
        if not os.path.exists(self.file_path):
            print(f"File {self.file_path} does not exist.")
            return False
        with open(self.file_path, "r", encoding="utf-8") as f:
            self.code_lines = f.readlines()
        return True

    def run_checks(self):
        sql_injection.check(self.code_lines, self.add_vulnerability)
        broken_access_control.check(self.code_lines, self.add_vulnerability)
        security_misconfig.check(self.code_lines, self.add_vulnerability)
        sensitive_data_exposure.check(self.code_lines, self.add_vulnerability)
        auth_failures.check(self.code_lines, self.add_vulnerability)

    def run(self):
        if not self.parse_file():
            return
        self.run_checks()

    def report(self):
        import os

        # ---- colour helpers ----
        def supports_truecolor() -> bool:
            # Most modern terminals set COLORTERM=truecolor or 24bit
            return os.environ.get("COLORTERM", "").lower() in ("truecolor", "24bit")

        def rgb(r, g, b) -> str:
            return f"\033[38;2;{r};{g};{b}m"

        # Fallback 8/16-colour palette
        ANSI = {
            "reset": "\033[0m", "bold": "\033[1m",
            "cyan": "\033[96m", "magenta": "\033[95m",
            "yellow": "\033[93m", "red": "\033[91m",
            "green": "\033[92m", "blue": "\033[94m",
        }

        TRUECOLOR = supports_truecolor()

        # Severity colours (true-color -> fallback)
        CRIT = (rgb(220, 20, 60) if TRUECOLOR else ANSI["red"] + ANSI["bold"])    # crimson
        HIGH = (rgb(255, 0, 0)   if TRUECOLOR else ANSI["red"])                   # red
        MED  = (rgb(255, 165, 0) if TRUECOLOR else ANSI["yellow"])                # orange-ish
        LOW  = (rgb(0, 200, 0)   if TRUECOLOR else ANSI["green"])                 # green

        RESET = ANSI["reset"]; BOLD = ANSI["bold"]
        HDR   = (rgb(180, 130, 255) if TRUECOLOR else ANSI["magenta"])            # section header
        TITLE = (rgb(120, 220, 200) if TRUECOLOR else ANSI["cyan"])               # title
        SUM   = (rgb(255, 215, 0)   if TRUECOLOR else ANSI["yellow"])             # summary label

        sev_color = {
            "CRITICAL": CRIT,
            "HIGH": HIGH,
            "MEDIUM": MED,
            "LOW": LOW,
        }

        print(f"\n{BOLD}{TITLE}Scan Results for {self.file_path}:{RESET}")

        if not self.vulnerabilities:
            ok = rgb(0, 200, 0) if TRUECOLOR else ANSI["green"]
            print(f"{ok}✅ No vulnerabilities found.{RESET}")
            return

        # Group by category
        groups = {}
        for v in self.vulnerabilities:
            groups.setdefault(v["category"], []).append(v)

        def cat_key(cat: str):
            # Sort A01..A10 first, then alphabetically
            head = cat.split(":", 1)[0].strip()
            return (0, int(head[1:])) if head.startswith("A") and head[1:].isdigit() else (1, cat.lower())

        for cat in sorted(groups.keys(), key=cat_key):
            items = sorted(groups[cat], key=lambda x: x["line"])
            # tally
            sev_counts = {"CRITICAL": 0, "HIGH": 0, "MEDIUM": 0, "LOW": 0}
            for v in items:
                sev_counts[v["severity"]] = sev_counts.get(v["severity"], 0) + 1

            total = len(items)
            print(f"\n{BOLD}{HDR}=== {cat} ({total} finding{'s' if total!=1 else ''}) ==={RESET}")

            # coloured summary chips
            chips = []
            for k in ["CRITICAL", "HIGH", "MEDIUM", "LOW"]:
                n = sev_counts.get(k, 0)
                if n:
                    chips.append(f"{sev_color[k]}{k.title()}{RESET}: {n}")
            if chips:
                print(f"{SUM}Summary:{RESET} " + ", ".join(chips))

            # entries
            for v in items:
                sc = sev_color.get(v["severity"], ANSI["blue"])
                print(
                    f"\n  {BOLD}• Line {v['line']} |{RESET} "
                    f"Severity {sc}{v['severity']}{RESET} | "
                    f"Confidence {v['confidence']}"
                )
                print(f"    → {v['description']}")
