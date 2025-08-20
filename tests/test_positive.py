# Triggers: 
# A01 Injection
# A02 Broken Access Control
# A03 Sensitive Data Exposure (Cryptographic Failures)
# A05 Security Misconfiguration
# A07 Identification and Authentication Failures

import sqlite3
import hashlib
import requests
from flask import Flask, Response

# ---------- A05: Security Misconfiguration ----------
SECRET_KEY = "changeme"            # hardcoded secret (A05)
ALLOWED_HOSTS = ['*']              # permissive host policy (A05)
SESSION_COOKIE_SECURE = False      # insecure cookie flag (A05)
CSRF_COOKIE_SECURE = False         # insecure CSRF flag (A05)

# ---------- A03: Sensitive Data Exposure ----------
password = "SuperSecret123"        # potential hardcoded secret (A03)
api_key = "sk_test_123456"         # potential hardcoded key (A03)
hashlib.md5(b"weak")               # weak hashing algorithm (A03)

# ---------- A07: Identification and Authentication Failures ----------
username = "admin"                 # default username (A07)
default_password = "password"      # default password (A07)
requests.get("https://example.com", verify=False)  # TLS verification disabled (A07)

app = Flask(__name__)

# ---------- A02: Broken Access Control ----------
# Sensitive route without auth decorator
@app.route("/admin")
def admin_panel():
    # Wildcard CORS header (A05)
    resp = Response("admin panel")
    resp.headers["Access-Control-Allow-Origin"] = "*"
    return resp

# Login route that should be protected or checked (A07 heuristic)
@app.route("/login")
def login_page():
    return "login page"

# ---------- A01: Injection ----------
user_input = input("Enter your username: ")
# Unparameterized, concatenated query assignment beginning with SELECT
query = "SELECT * FROM users WHERE username = '" + user_input + "'"  # A01

conn = sqlite3.connect("example.db")
cursor = conn.cursor()
cursor.execute(query)  # executes suspicious query var (A01)

# Explicit Flask debug enable (A05)
if __name__ == "__main__":
    app.run(debug=True)
