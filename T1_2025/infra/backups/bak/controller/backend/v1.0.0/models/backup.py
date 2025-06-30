from sqlmodel import Field, SQLModel
from datetime import datetime

class Backup(SQLModel, table=True):
    backup_id: int = Field(primary_key=True)
    name: str
    date: datetime 