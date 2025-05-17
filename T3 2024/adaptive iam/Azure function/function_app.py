import logging
import json
import bcrypt
from datetime import datetime
from azure.cosmos import CosmosClient, PartitionKey
import azure.functions as func

# Cosmos DB Configuration
COSMOS_DB_URL = ""
COSMOS_DB_KEY = ""
DATABASE_NAME = "adaptiveIAM"
USERS_CONTAINER = "Users"
BEHAVIOR_CONTAINER = "Behavior"
ROLES_CONTAINER = "Roles"

# Initialize Cosmos Client
client = CosmosClient(COSMOS_DB_URL, credential=COSMOS_DB_KEY)
database = client.get_database_client(DATABASE_NAME)
users_container = database.get_container_client(USERS_CONTAINER)
behavior_container = database.get_container_client(BEHAVIOR_CONTAINER)
roles_container = database.get_container_client(ROLES_CONTAINER)

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info("Processing login request.")

    try:
        # Parse request body
        req_body = req.get_json()
        email = req_body.get("email")
        password = req_body.get("password")
        ip_address = req.headers.get("X-Forwarded-For", req.remote_addr)
        device_id = req_body.get("device_id", "unknown")

        if not email or not password:
            return func.HttpResponse(
                json.dumps({"success": False, "message": "Email and password are required."}),
                status_code=400,
                mimetype="application/json",
            )

        # Fetch user data from the database
        query = f"SELECT * FROM c WHERE c.email = '{email}'"
        users = list(users_container.query_items(query=query, enable_cross_partition_query=True))

        if not users:
            log_behavior(email, ip_address, device_id, "login", "failure")
            return func.HttpResponse(
                json.dumps({"success": False, "message": "Invalid credentials."}),
                status_code=401,
                mimetype="application/json",
            )

        user = users[0]

        # Verify password
        if not bcrypt.checkpw(password.encode("utf-8"), user["password_hash"].encode("utf-8")):
            log_behavior(email, ip_address, device_id, "login", "failure")
            return func.HttpResponse(
                json.dumps({"success": False, "message": "Invalid credentials."}),
                status_code=401,
                mimetype="application/json",
            )

        # Fetch roles
        roles_query = f"SELECT * FROM c WHERE c.id IN ('{','.join(user['roles'])}')"
        roles = list(roles_container.query_items(query=roles_query, enable_cross_partition_query=True))

        log_behavior(email, ip_address, device_id, "login", "success")

        # Respond with user data and roles
        return func.HttpResponse(
            json.dumps({
                "success": True,
                "email": user["email"],
                "roles": [role["role"] for role in roles],
            }),
            status_code=200,
            mimetype="application/json",
        )

    except Exception as e:
        logging.error(f"Error processing login: {e}")
        return func.HttpResponse(
            json.dumps({"success": False, "message": "An internal error occurred."}),
            status_code=500,
            mimetype="application/json",
        )

def log_behavior(email, ip_address, device_id, action, result):
    """Logs user behavior in the Behavior container."""
    behavior_container.create_item({
        "id": f"b_{datetime.utcnow().timestamp()}",
        "user_id": email,
        "ip_address": ip_address,
        "device_id": device_id,
        "timestamp": datetime.utcnow().isoformat(),
        "action": action,
        "result": result,
    })