from database import setup, getSession  # Import the setup and getSession from database.py
from models import Container, Database, DbType  # Import the models
from sqlmodel import select  # Import the select function

# Set up the database and create the tables
setup()

# Manage the session
session = next(getSession())  # Get a session

# Create new container
container = Container(container_name="Container1", container_type="Docker")
session.add(container)
session.commit()

# Create new database linked to the container using the DbType enum
database = Database(database_name="TestDB", database_type=DbType.MYSQL, container_id=container.id)
session.add(database)
session.commit()

# Query database
queried_container = session.exec(select(Container).where(Container.container_name == "Container1")).first()
queried_database = session.exec(select(Database).where(Database.database_name == "TestDB")).first()

print(f"Container: {queried_container.container_name}, Database: {queried_database.database_name}")

# Close the session
session.close()
