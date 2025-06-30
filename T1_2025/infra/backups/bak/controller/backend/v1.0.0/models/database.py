from sqlmodel import Field, SQLModel, create_engine, Session
from models import DbType, Container, Database, Backup, BackupPolicy, Rollback, Policy  # Import all models from models

# SQLite URL and connection arguments
sqlite_url = "sqlite:///database.db"
connection_args = {"check_same_thread": False}

# Create engine to interact with the SQLite database
engine = create_engine(sqlite_url, connect_args=connection_args)

# Function to set up the database and create tables
def setup():
    SQLModel.metadata.create_all(engine)  # Creates all tables from the models

# Function to get a session for interacting with the database
def getSession():
    with Session(engine) as session:
        yield session
        