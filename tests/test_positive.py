# Triggers: A01 (Injection), A02 (Broken Access Control), A05 (Security Misconfiguration)

import sqlite3
from flask import Flask, Response

# ---------- A05: Security Misconfiguration ----------
# Obvious default-like secret
SECRET_KEY = "changeme"

# Permissive host policy
ALLOWED_HOSTS = ['*']

# Insecure cookie/transport flags
SESSION_COOKIE_SECURE = False
CSRF_COOKIE_SECURE = False

app = Flask(__name__)

# ---------- A02: Broken Access Control ----------
# Sensitive admin route with NO auth decorator present
@app.route("/admin")
def admin_panel():
    # Wildcard CORS header (also A05)
    resp = Response("admin panel")
    resp.headers["Access-Control-Allow-Origin"] = "*"
    return resp

# ---------- A01: Injection ----------
username = input("Enter your username: ")
# Unparameterized concatenated query assignment that starts with SELECT
query = "SELECT * FROM users WHERE username = '" + username + "'"

conn = sqlite3.connect("example.db")
cursor = conn.cursor()

# Execute the suspicious query variable
cursor.execute(query)

# Explicit Flask debug enable (A05)
if __name__ == "__main__":
    app.run(debug=True)
