from fastapi import APIRouter
import db
import models

router = APIRouter()

@router.get("/instance/{hostname}", response_model=models.Instance)
def API__get_instance_by_hostname(hostname: str):
    return db.get_instance_by_hostname(hostname)

@router.get("/policy/{policy_name}", response_model=models.Policy)
def API__get_policy_by_name(policy_name: str):
    return db.get_policy_by_name(policy_name)

@router.post("/instance/", response_model=models.ResponseMessage)
def API__add_instance(hostname: str):
    return db.add_instance(hostname)

@router.get("/instance/{hostname}/policy/", response_model=models.Policy)
def API__get_instance_policy_by_hostname(hostname: str):
    return db.get_instance_policy_by_hostname(hostname)

@router.post("/policy/", response_model=models.ResponseMessage)
def API__add_policy(policy: models.Policy):
    return db.add_policy(policy)