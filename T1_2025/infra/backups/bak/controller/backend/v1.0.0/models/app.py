from sqlmodel import Field, SQLModel
from pathlib import Path

class App(SQLModel, table=True):
    app_id: int = Field(primary_key=True)
    name: str
    data_location: Path
    config_location: Path
    database_id: int
    runtime: str