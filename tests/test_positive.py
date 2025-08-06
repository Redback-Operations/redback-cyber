# This file should trigger the SQL injection rule

import sqlite3

username = input("Enter your username: ")
query = "SELECT * FROM users WHERE username = '" + username + "'"

conn = sqlite3.connect("example.db")
cursor = conn.cursor()

cursor.execute(query)