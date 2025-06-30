from sqlmodel import Session, SQLModel, create_engine

sqlite_url = f"sqlite:///database.db"
connection_args = {"check_same_thread": False}
engine = create_engine(sqlite_url, connect_args=connection_args)

def setup():
    SQLModel.metadata.create_all(engine)

def getSession():
    with Session(engine) as session:
        yield session