from fastapi import FastAPI
from db import init_db
from api import router as api_router
import sqlite3

app = FastAPI()
init_db()
app.include_router(api_router)