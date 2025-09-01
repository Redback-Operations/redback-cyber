# Triggers:
# A01 Injection
# A02 Broken Access Control
# A03 Sensitive Data Exposure (Cryptographic Failures)
# A04 Insecure Design
# A05 Security Misconfiguration
# A06 Vulnerable and Outdated Components
# A07 Identification and Authentication Failures
# A08 Software and Data Integrity Failures
# A09 Security Logging and Monitoring Failures
# A10 Server-Side Request Forgery (SSRF)

import sqlite3
import hashlib
import requests
import yaml
import pickle
import subprocess
from flask import Flask, Response

# ---------- A05: Security Misconfiguration ----------
SECRET_KEY = "changeme"            # hardcoded secret
ALLOWED_HOSTS = ['*']              # permissive hosts
SESSION_COOKIE_SECURE = False      # insecure cookie flag
CSRF_COOKIE_SECURE = False         # insecure CSRF flag

# ---------- A03: Sensitive Data Exposure ----------
password = "SuperSecret123"        # potential hardcoded password
api_key = "sk_test_123456"         # potential hardcoded API key
hashlib.md5(b"weak")               # weak hashing algorithm

# ---------- A07: Identification and Authentication Failures ----------
username = "admin"                 # default username
default_password = "password"      # default password
requests.get("https://example.com", verify=False)  # TLS verification disabled

app = Flask(__name__)

# ---------- A02: Broken Access Control ----------
# Sensitive route without auth decorator
@app.route("/admin")
def admin_panel():
    # Wildcard CORS header (also A05)
    resp = Response("admin panel")
    resp.headers["Access-Control-Allow-Origin"] = "*"
    return resp

# Login route that should be protected or checked (A07 heuristic)
@app.route("/login")
def login_page():
    print("login attempt for user")  # A09: print in auth flow
    return "login page"

# ---------- A04: Insecure Design ----------
# TODO insecure: temporary admin override without proper checks

# ---------- A06: Vulnerable and Outdated Components ----------
# Simulated vulnerable pins inside code string (still scanned by our rule)
requirements_block = """
flask==0.12
django==1.11
"""

# ---------- A08: Software and Data Integrity Failures ----------
user_code = "1 + 2"
result = eval(user_code)                     # dangerous dynamic evaluation
data = yaml.load("key: value")               # unsafe YAML load (should be yaml.safe_load)
with open("tmp.bin", "wb") as fh:
    pickle.dump({"x": 1}, fh)                # create a pickle to then load (unsafe)
with open("tmp.bin", "rb") as fh:
    obj = pickle.load(fh)                    # unsafe deserialization
subprocess.run("echo hi", shell=True)        # shell=True

# ---------- A09: Security Logging and Monitoring Failures ----------
try:
    raise ValueError("x")
except:
    print("error:", default_password)        # prints secret-ish value and uses bare-except

# ---------- A10: SSRF ----------
url = input("Enter URL: ")
requests.get(url)                             # user-controlled URL

# ---------- A01: Injection ----------
user_input = input("Enter your username: ")
# Unparameterized, concatenated query assignment beginning with SELECT
query = "SELECT * FROM users WHERE username = '" + user_input + "'"

conn = sqlite3.connect("example.db")
cursor = conn.cursor()
cursor.execute(query)  # executes suspicious query var (A01)

# Explicit Flask debug enable (A05)
if __name__ == "__main__":
    app.run(debug=True)
