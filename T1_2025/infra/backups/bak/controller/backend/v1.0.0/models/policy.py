from sqlmodel import Field, SQLModel

class Policy(SQLModel, table=True):
    policy_id: int = Field(primary_key=True)
    tool: str
    copies: int
    frequency: str