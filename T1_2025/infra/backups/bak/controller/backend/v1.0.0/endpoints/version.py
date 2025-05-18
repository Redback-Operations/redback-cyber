from fastapi import APIRouter
import db
import models

router = APIRouter(prefix="/api/register")

@router.get("")
def test():
    return {"hello": "hello"}
