import sqlite3
import models

DB_NAME = "bak.db"

def get_instance_by_hostname(hostname: str):
    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row
    curs = conn.cursor()

    curs.execute("SELECT * FROM Instance WHERE hostname = ?", (hostname,))
    instance = curs.fetchone()
    conn.close()

    if instance:
        return models.Instance(hostname=instance['hostname'])
    else:
        return {"error": "Instance not found."}

def get_instance_policy_by_hostname(hostname: str):
    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row
    curs = conn.cursor()

    curs.execute("""SELECT Policy.*
                    FROM Policy
                    JOIN Instance ON Instance.hostname = Policy.hostname
                    WHERE Instance.hostname = ?""", (hostname,))
    policy = curs.fetchone()
    conn.close()

    if policy:
        return models.Policy(hostname=policy['hostname'],
                             tool=policy['tool'],
                             freq=policy['freq'],
                             copies=policy['copies'])
    else:
        return {"error": "Instance not found."}

def get_policy_by_name(hostname: str):
    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row
    curs = conn.cursor()

    curs.execute("SELECT * FROM Policy WHERE hostname = ?", (hostname,))
    policy = curs.fetchone()

    conn.close()

    if policy:
        return models.Policy(hostname=policy['hostname'],
                            tool=policy['tool'],
                            freq=policy['freq'],
                            copies=policy['copies'])
    else:
        return {"error": "Policy not found"}
    
def add_instance(hostname):
    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row
    curs = conn.cursor()

    curs.execute("SELECT * FROM Instance WHERE hostname = ?", (hostname,))
    instance_exists = curs.fetchone()

    if instance_exists:
        conn.close()
        return {"error": "Instance already exists."}
    
    curs.execute("""INSERT INTO Instance (hostname) 
                    VALUES (?)""", (hostname,)) 
    conn.commit()
    conn.close()

    return {"message": f"Instance with hostname {hostname} created."}

def add_policy(policy):
    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row
    curs = conn.cursor()

    curs.execute("SELECT * FROM Policy WHERE hostname = ?", (policy.hostname,))
    policy_exists = curs.fetchone()

    if policy_exists:
        conn.close()
        return {"error": "Instance already exists."}
    
    curs.execute("""INSERT INTO Policy (hostname, tool, freq, copies) 
                    VALUES (?, ?, ?, ?)""", (policy.hostname, 
                                             policy.tool,
                                             policy.freq,
                                             policy.copies)) 
    conn.commit()
    conn.close()

    return {"message": f"Instance with hostname {policy.hostname} created."}
    

def init_db():
    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row
    curs = conn.cursor()

    SQL__instance_table = """CREATE TABLE IF NOT EXISTS Instance(
                              hostname TEXT PRIMARY KEY
                              );"""

    SQL__policy_table = """CREATE TABLE IF NOT EXISTS Policy(
                              hostname TEXT PRIMARY KEY,
                              tool TEXT NOT NULL,
                              freq TEXT NOT NULL,
                              copies INT NOT NULL
                              );"""

    curs.execute(SQL__instance_table)
    curs.execute(SQL__policy_table)

    conn.commit()
    conn.close()