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
SECRET_KEY = "changeme"           
ALLOWED_HOSTS = ['*']              
SESSION_COOKIE_SECURE = False      
CSRF_COOKIE_SECURE = False         

# ---------- A03: Sensitive Data Exposure ----------
password = "SuperSecret123"        
api_key = "sk_test_123456"         
hashlib.md5(b"weak")               

# ---------- A07: Identification and Authentication Failures ----------
username = "admin"                 
default_password = "password"     
requests.get("https://example.com", verify=False)  

app = Flask(__name__)

# ---------- A02: Broken Access Control ----------
@app.route("/admin")
def admin_panel():
    resp = Response("admin panel")
    resp.headers["Access-Control-Allow-Origin"] = "*"
    return resp

@app.route("/login")
def login_page():
    return "login page"

# ---------- A01: Injection ----------
user_input = input("Enter your username: ")
query = "SELECT * FROM users WHERE username = '" + user_input + "'"  

conn = sqlite3.connect("example.db")
cursor = conn.cursor()
cursor.execute(query)  

if __name__ == "__main__":
    app.run(debug=True)
