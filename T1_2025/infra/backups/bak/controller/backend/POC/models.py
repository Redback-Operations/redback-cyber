from pydantic import BaseModel

class Instance(BaseModel):
    hostname: str

class Policy(BaseModel):
    hostname: str
    tool: str
    freq: str
    copies: int

class ResponseMessage(BaseModel):
    message: str