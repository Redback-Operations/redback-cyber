from fastapi import FastAPI
import database
from endpoints import register, policy, version

def lifespan(app: FastAPI):
    database.setup()

app = FastAPI(lifespan=lifespan)
app.include_router(register.router)
app.include_router(policy.router)
app.include_router(version.router)