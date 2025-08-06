# OWASP PR Scanner

This tool is designed to scan Python files for security vulnerabilities based on the OWASP Top 10.

---

## ✅ Current Functionality

The scanner detects potential vulnerabilities using static analysis (regex and basic logic). Currently implemented:

- **A01: Injection**
  - Detects unparameterized SQL queries
  - Flags SQL built with string concatenation or f-strings

- **Clean vs Vulnerable Detection**
  - Example `test_positive.py` will trigger an alert for SQL injection
  - Example `test_negative.py` is safe and produces no alerts

---

## 🚧 Planned Features (OWASP Top 10 Coverage)
This scanner will be extended to cover the full OWASP Top 10.

Currently implemented:

✅ A01: Injection (e.g. SQL injection detection using regex)

Planned:

A02: Cryptographic Failures (e.g. weak hashing, insecure SSL use)

A03: Injection – more types (e.g. XSS, Command Injection)

A04: Insecure Design (e.g. missing access controls)

A05: Security Misconfiguration (e.g. debug mode, missing headers)

A06: Vulnerable and Outdated Components (dependency scanning)

A07: Identification and Authentication Failures (e.g. missing auth checks)

A08: Software and Data Integrity Failures (e.g. unsafe deserialization)

A09: Security Logging and Monitoring Failures (e.g. no logging in sensitive flows)

A10: Server-Side Request Forgery (SSRF)


## 👤 Author
Developed by Liana Perry (2025)
Cybersecurity SecDevOps Sub-team | Redback Operations

## 🙌 Acknowledgements
This project is inspired by the original vulnerability scanning logic created by Amir Zandieh, and extends it into a modular and OWASP-aligned security scanning tool for pull requests.