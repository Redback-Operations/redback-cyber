# OWASP PR Scanner

This tool scans Python files for security vulnerabilities based on the **OWASP Top 10**.  
It is designed for lightweight static analysis of pull requests, helping developers catch common issues early and enforce secure coding practices.

---

## ✅ Current Functionality

The scanner detects vulnerabilities using static analysis (regex + simple heuristics).  
It groups results by OWASP Top 10 category and highlights severity with colour-coded output.  

Implemented rules:

- **A01: Injection**  
  - Detects unparameterized SQL queries  
  - Flags SQL built with string concatenation or f-strings  

- **A02: Broken Access Control**  
  - Detects Flask routes without authentication decorators  

- **A03: Sensitive Data Exposure (Cryptographic Failures)**  
  - Detects weak hashing algorithms (MD5, SHA1)  
  - Flags hardcoded secrets, API keys, and default passwords  
  - Warns about unsafe fallback values  

- **A04: Insecure Design**  
  - Flags insecure “TODO” markers, temporary overrides, or auth bypass notes  

- **A05: Security Misconfiguration**  
  - Detects `debug=True` in Flask apps  
  - Flags permissive host settings (`ALLOWED_HOSTS = ['*']`)  
  - Insecure cookie/CSRF flags  
  - Hardcoded Flask secrets  

- **A06: Vulnerable and Outdated Components**  
  - Detects dependency pins like `flask==0.12` or `django==1.11`  
  - Helps identify outdated or risky components  

- **A07: Identification and Authentication Failures**  
  - Detects default credentials (`admin`, `password`)  
  - Flags login routes without auth checks  
  - Warns about disabled TLS verification (`verify=False`)  

- **A08: Software and Data Integrity Failures**  
  - Detects dangerous use of `eval()`  
  - Warns about unsafe deserialization (`pickle.load`)  
  - Flags subprocess calls with `shell=True`  

- **A09: Security Logging and Monitoring Failures**  
  - Detects print statements in auth flows  
  - Flags bare `except:` blocks with no logging  
  - Warns when secrets are printed to stdout  

- **A10: Server-Side Request Forgery (SSRF)**  
  - Detects unvalidated user input passed into `requests.get/post`  

---

## 📂 Test Cases

- **`test_positive.py`**  
  A deliberately vulnerable file that triggers all implemented OWASP rules (A01–A10).

- **`test_negative.py`**  
  A safe baseline file with secure practices — should pass with **no findings**.  
  Used for regression testing and validation.

---

## 🎨 Output Example

- Findings are grouped by OWASP category (A01–A10)  
- Severity levels are **colour-coded**:  
  - 🔴 High  
  - 🟠 Medium  
  - 🟢 Low  

Example:
=== A01: Injection (2 findings) ===
Summary: High: 2

• Line 60 | Severity HIGH | Confidence MEDIUM
→ SQL query created via string concatenation: ...

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