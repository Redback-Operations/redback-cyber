from sqlmodel import Field, SQLModel
from models import Policy 

class Container(SQLModel, table=True):
    container_id: int = Field(primary_key=True)
    container_name: str
    image: str
    policy: Policy