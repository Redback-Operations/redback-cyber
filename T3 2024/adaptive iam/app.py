from flask import Flask, render_template, request, redirect, url_for, flash
from prometheus_client import start_http_server, Counter, generate_latest, CONTENT_TYPE_LATEST
import random
import datetime
import logging
import os
import sqlite3
from bs4 import BeautifulSoup
import requests
from sklearn.neighbors import LocalOutlierFactor
import numpy as np
from user_agents import parse
from sklearn.ensemble import IsolationForest

app = Flask(__name__)
app.secret_key = os.urandom(24)

logging.basicConfig(level=logging.INFO)
logging.info(f"Current working directory: {os.getcwd()}")

login_attempts_total = Counter('login_attempts_total', 'Total number of login attempts')
successful_logins_total = Counter('successful_logins_total', 'Total number of successful logins')
risky_logins_total = Counter('risky_logins_total', 'Total number of risky logins')
failed_logins_total = Counter('failed_logins_total', 'Total number of failed logins')

USER_DATA = {"username": "admin", "password": "password123"}

def adapt_datetime(dt):
    return dt.isoformat()

def convert_datetime(s):
    return datetime.datetime.fromisoformat(s.decode())

sqlite3.register_adapter(datetime.datetime, adapt_datetime)
sqlite3.register_converter("timestamp", convert_datetime)

def init_db():
    try:
        conn = sqlite3.connect('login.db', detect_types=sqlite3.PARSE_DECLTYPES)
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS logins (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT,
                success BOOLEAN,
                login_time timestamp,
                ip_address TEXT,
                risky BOOLEAN,
                browser TEXT,
                os TEXT,
                user_agent TEXT
            )
        ''')
        conn.commit()
        conn.close()
        logging.info("SQLite database initialized successfully.")
    except Exception as e:
        logging.error(f"Error initializing SQLite database: {e}")

def extract_info_from_html(html_content):
    soup = BeautifulSoup(html_content, 'html.parser')
    title = soup.title.string if soup.title else 'No title'
    meta_description = soup.find('meta', attrs={'name': 'description'})
    description = meta_description['content'] if meta_description else 'No description'
    headings = [heading.get_text() for heading in soup.find_all(['h1', 'h2', 'h3', 'h4', 'h5', 'h6'])]
    return title, description, headings

model = IsolationForest(contamination=0.1, random_state=42)
login_features = []

@app.route('/')
def index():
    return render_template('login.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        login_attempts_total.inc()
        username = request.form['username']
        password = request.form['password']
        login_time = datetime.datetime.now()
        ip_address = request.remote_addr
        user_agent_string = request.headers.get('User-Agent')
        user_agent = parse(user_agent_string)

        browser = user_agent.browser.family
        os = user_agent.os.family

        success = (username == USER_DATA['username'] and password == USER_DATA['password'])

        if success:
            successful_logins_total.inc()
            login_message = "Login successful!"
            
            feature_vector = [hash(ip_address) % 1000, hash(user_agent_string) % 1000, login_time.hour]
            login_features.append(feature_vector)
            
            if len(login_features) > 3:
                X = np.array(login_features)
                model.fit(X)
            
            if len(login_features) > 3:
                is_risky = model.predict([feature_vector])[0] == -1
                if is_risky:
                    risky_logins_total.inc()
                    login_message = "Login risky!"
                    return render_template('login.html', login_message=login_message)
            else:
                is_risky = False
        else:
            failed_logins_total.inc()
            login_message = "Invalid credentials."
            is_risky = False

        if is_risky:
            risky_logins_total.inc()

        try:
            conn = sqlite3.connect('login.db', detect_types=sqlite3.PARSE_DECLTYPES)
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO logins (username, success, login_time, ip_address, risky, browser, os, user_agent)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ''', (username, success, login_time, ip_address, is_risky, browser, os, user_agent_string))
            conn.commit()
            conn.close()
        except sqlite3.Error as e:
            logging.error(f"Error logging login attempt: {e}")

        return render_template('login.html', login_message=login_message)

@app.route('/scrape', methods=['GET', 'POST'])
def scrape():
    if request.method == 'POST':
        url = request.form['url']
        response = requests.get(url)
        if response.status_code == 200:
            title, description, headings = extract_info_from_html(response.text)
            return render_template('scrape_result.html', title=title, description=description, headings=headings)
        else:
            return f"Failed to retrieve the page. Status code: {response.status_code}"
    return render_template('scrape.html')

@app.route('/metrics')
def metrics():
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

def setup():
    init_db()
    start_http_server(5000)

if __name__ == '__main__':
    setup()
    app.run(debug=True, port=8080)
