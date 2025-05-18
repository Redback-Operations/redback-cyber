from sqlmodel import Field, SQLModel
from enum import Enum
from typing import Optional

# Enum for Database Types
class DbType(str, Enum):
    POSTGRES = "postgres"
    MYSQL = "mysql"
    MSSQL = "msql"
    MONGO = "mongo"
    SQLITE = "sqlite"
    MARIA = "maria"

# Policy
class Policy(SQLModel, table=True):
    id: int = Field(default=None, primary_key=True)
    name: str
    description: Optional[str] = None

# Containers
class Container(SQLModel, table=True):
    id: int = Field(default=None, primary_key=True)
    container_name: str
    container_type: str
    network: Optional[str] = None
    bind_mount: Optional[str] = None
    config_files: Optional[str] = None

# Databases
class Database(SQLModel, table=True):
    id: int = Field(default=None, primary_key=True)
    database_name: str
    database_type: DbType  # Using Enum
    version: Optional[str] = None
    primary_replica: Optional[str] = None
    container_id: int = Field(foreign_key="container.id")

    # Ensure proper conversion of Enum values to strings and vice-versa
    @classmethod
    def from_orm(cls, orm_instance):
        instance = super().from_orm(orm_instance)
        # Ensure the enum is stored as a string
        instance.database_type = str(instance.database_type)
        return instance

# Backups
class Backup(SQLModel, table=True):
    id: int = Field(default=None, primary_key=True)
    container_id: int = Field(foreign_key="container.id")
    database_id: int = Field(foreign_key="database.id")
    backup_date: str
    backup_size: int
    backup_type: str

# Backup Policy
class BackupPolicy(SQLModel, table=True):
    id: int = Field(default=None, primary_key=True)
    container_id: int = Field(foreign_key="container.id")
    database_id: int = Field(foreign_key="database.id")
    policy_type: str
    frequency: str
    retention_period: int

# Rollbacks
class Rollback(SQLModel, table=True):
    id: int = Field(default=None, primary_key=True)
    backup_id: int = Field(foreign_key="backup.id")
    rollback_date: str
    rollback_reason: str
