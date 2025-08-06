# This file should produce clean results 


import sqlite3

username = input("Enter your username: ")
query = "SELECT * FROM users WHERE username = ?"

conn = sqlite3.connect("example.db")
cursor = conn.cursor()
cursor.execute(query, (username,))