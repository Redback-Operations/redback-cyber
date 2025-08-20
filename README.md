# OWASP PR Scanner

This tool scans Python files for security vulnerabilities based on the **OWASP Top 10**.  
It is designed for lightweight static analysis of pull requests, helping developers catch common issues early.

---

## ✅ Current Functionality

The scanner detects potential vulnerabilities using static analysis (regex + simple logic).  
Implemented rules:

- **A01: Injection**
  - Detects unparameterized SQL queries
  - Flags SQL built with string concatenation or f-strings

- **A02: Broken Access Control**
  - Detects Flask routes without authentication decorators

- **A03: Sensitive Data Exposure (Cryptographic Failures)**
  - Detects weak hashing algorithms (e.g., MD5, SHA1)
  - Flags hardcoded sensitive values (secrets, passwords, API keys)
  - Warns about unsafe patterns like environment variable fallbacks if misused

- **A05: Security Misconfiguration**
  - Detects `debug=True` in Flask apps
  - Flags permissive host settings (e.g., `ALLOWED_HOSTS = ['*']`)
  - Insecure cookie/CSRF flags
  - Hardcoded Flask secrets

- **A07: Identification and Authentication Failures**
  - Detects default credentials (`admin`, `password`, etc.)
  - Flags routes like `/login` without authentication checks
  - Warns about disabled TLS verification in requests (`verify=False`)

---

## 📂 Test Cases

- **`test_positive.py`**  
  Contains vulnerable code that should trigger A01 (SQL Injection).

- **`test_positive_all.py`**  
  Triggers multiple rules (A01, A02, A03, A05, A07) in one file.

- **`test_negative.py`**  
  Safe code sample — should pass with **no findings** (used for regression testing).

---

## 🚧 Planned Features (Remaining OWASP Top 10)

- **A04: Insecure Design** (missing access control design patterns)  
- **A06: Vulnerable and Outdated Components** (dependency scanning)  
- **A08: Software and Data Integrity Failures** (e.g., unsafe deserialization)  
- **A09: Security Logging and Monitoring Failures** (e.g., missing audit logging)  
- **A10: Server-Side Request Forgery (SSRF)**  

---

## Running the Script 
### 1. Navigate to your project root
cd path/to/owasp-scanner

### 2. Set PYTHONPATH so Python recognizes `scanner/` as a package
set PYTHONPATH=.

### 3. Run the script with the file to scan as an argument
python scanner/main.py tests/test_positive.py

## 👤 Author
Developed by Liana Perry (2025)
Cybersecurity SecDevOps Sub-team | Redback Operations

## 🙌 Acknowledgements
This project is inspired by the original vulnerability scanning logic created by Amir Zandieh, and extends it into a modular and OWASP-aligned security scanning tool for pull requests.