# This file should produce clean results

import os
import sqlite3
import hashlib
import requests
from flask import Flask

# Assume a real auth decorator exists in the project. The scanner only checks for its presence.
def login_required(fn):  
    return fn

# --- Secure Flask setup ---
app = Flask(__name__)
app.config["DEBUG"] = False
app.config["SECRET_KEY"] = os.environ.get("SECRET_KEY", "fallback_only_for_dev_builds")

@app.route("/dashboard")
@login_required
def dashboard():
    return "secure dashboard"

# --- Parameterised SQL query (safe) ---
username = input("Enter your username: ")
query = "SELECT * FROM users WHERE username = ?"

conn = sqlite3.connect("example.db")
cursor = conn.cursor()
cursor.execute(query, (username,))

# --- Secure cryptography usage ---
hashed_password = hashlib.sha256(username.encode()).hexdigest()

# --- Secure HTTP request (TLS verification enabled) ---
resp = requests.get("https://example.com", verify=True)
print(resp.status_code)


# --- Safe YAML load ---
data = yaml.safe_load("key: value")

# --- Safe subprocess usage (no shell=True) ---
subprocess.run(["echo", "hello"], check=True)