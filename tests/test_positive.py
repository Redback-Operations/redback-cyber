# Triggers:
# A01 Injection
# A02 Broken Access Control
# A03 Sensitive Data Exposure (Cryptographic Failures)
# A04 Insecure Design
# A05 Security Misconfiguration
# A06 Vulnerable and Outdated Components
# A07 Identification and Authentication Failures

import sqlite3
import hashlib
import requests
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
    return "login page"

# ---------- A04: Insecure Design ----------
# TODO insecure: temporary admin override without proper checks

# ---------- A06: Vulnerable and Outdated Components ----------
# Simulate vulnerable dependency pins (scanner looks for '==' with flask/django)
requirements_block = """
flask==0.12
django==1.11
"""

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
