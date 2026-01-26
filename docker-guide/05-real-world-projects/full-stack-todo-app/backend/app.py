from flask import Flask, jsonify, request
import os
import psycopg2

app = Flask(__name__)

def get_db_connection():
    conn = psycopg2.connect(os.environ.get("DATABASE_URL"))
    return conn

@app.route('/')
def hello():
    return "Hello from Flask Backend!"

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
    # Initialize database table (for simplicity, run once on start)
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

    app.run(host='0.0.0.0', port=5000)
