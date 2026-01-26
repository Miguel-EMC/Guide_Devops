from flask import Flask, jsonify, request
import os
import psycopg2

app = Flask(__name__)

# This is a placeholder; in a real app, you'd manage DB connection
# more robustly and use an ORM.
def get_db_connection():
    conn = psycopg2.connect(os.environ.get("DATABASE_URL", "postgresql://user:password@localhost:5432/mydatabase"))
    return conn

@app.route('/')
def hello():
    return "Hello from Full-Stack Backend!"

@app.route('/todos', methods=['GET', 'POST'])
def todos():
    conn = get_db_connection()
    cur = conn.cursor()
    if request.method == 'POST':
        data = request.json
        cur.execute("INSERT INTO todos (title) VALUES (%s)", (data['title'],))
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({"message": "Todo added!"}), 201
    else:
        cur.execute("SELECT * FROM todos")
        todos = cur.fetchall()
        cur.close()
        conn.close()
        return jsonify(todos)

if __name__ == '__main__':
    # For a real app, this should be part of a proper migration system
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS todos (
                id SERIAL PRIMARY KEY,
                title VARCHAR NOT NULL,
                completed BOOLEAN DEFAULT FALSE
            );
        """)
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Could not connect to database or create table: {e}")

    app.run(host='0.0.0.0', port=5000)
