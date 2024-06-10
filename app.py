from flask import Flask
from flask_cors import CORS
import os
import psycopg2
from psycopg2 import OperationalError

app = Flask(__name__)
CORS(app, origins=["*"])

def create_connection():
    try:
        connection_string = f"{os.environ['DB_URI']}"
        connection = psycopg2.connect(connection_string)
        return connection
    except OperationalError as e:
        print(f"Error: {e}")
        return None

@app.route("/flask")
def hello():
    return "flask inside Docker thru github!! postgres"

@app.route("/database")
def check_db_connection():
    connection = create_connection()
    if connection:
        connection.close()
        return "Postgres connection successful"
    else:
        return "Postgres connection unsuccessful", 500

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(debug=True, host='0.0.0.0', port=port)
