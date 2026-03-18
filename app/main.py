# app/main.py
from flask import Flask, request, jsonify, abort
import logging

app = Flask(__name__)

# Простое "хранилище" данных в памяти
users = {}
next_id = 1

# Настройка базового логирования
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@app.route('/', methods=['GET'])
def hello():
    logger.info("Root endpoint accessed")
    return jsonify({"message": "Hello, World!"})

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok"}), 200

@app.route('/api/users', methods=['GET'])
def get_users():
    logger.info("Fetching all users")
    return jsonify({"users": list(users.values())})

@app.route('/api/users', methods=['POST'])
def create_user():
    global next_id
    data = request.get_json()

    if not data or 'name' not in data or 'email' not in data:
        logger.warning(f"Failed user creation: missing fields. Data: {data}")
        abort(400, description="Missing 'name' or 'email' field")

    user_id = next_id
    users[user_id] = {
        "id": user_id,
        "name": data['name'],
        "email": data['email']
    }
    next_id += 1
    logger.info(f"User created with id: {user_id}")
    return jsonify(users[user_id]), 201

@app.route('/api/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    user = users.get(user_id)
    if not user:
        logger.warning(f"User with id {user_id} not found")
        abort(404, description="User not found")
    return jsonify(user)

@app.route('/api/users/<int:user_id>', methods=['DELETE'])
def delete_user(user_id):
    if user_id not in users:
        logger.warning(f"Attempted to delete non-existent user with id {user_id}")
        abort(404, description="User not found")
    del users[user_id]
    logger.info(f"User with id {user_id} deleted")
    return '', 204

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False) # Отключаем debug для продакшена
