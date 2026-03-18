# app/tests/test_app.py
import pytest
import json
from app.main import app as flask_app

@pytest.fixture
def app():
    """Фикстура для создания тестового клиента Flask."""
    yield flask_app

@pytest.fixture
def client(app):
    """Фикстура для тестового клиента."""
    return app.test_client()

def test_get_root(client):
    """Тест GET /"""
    response = client.get('/')
    assert response.status_code == 200
    assert response.get_json() == {"message": "Hello, World!"}

def test_get_health(client):
    """Тест GET /health"""
    response = client.get('/health')
    assert response.status_code == 200
    assert response.get_json() == {"status": "ok"}

def test_get_users_empty(client):
    """Тест GET /api/users когда список пуст."""
    response = client.get('/api/users')
    assert response.status_code == 200
    assert response.get_json() == {"users": []}

def test_create_user_success(client):
    """Тест успешного POST /api/users."""
    user_data = {"name": "John Doe", "email": "john@example.com"}
    response = client.post('/api/users',
                           data=json.dumps(user_data),
                           content_type='application/json')
    assert response.status_code == 201
    response_json = response.get_json()
    assert response_json['name'] == "John Doe"
    assert response_json['email'] == "john@example.com"
    assert 'id' in response_json

def test_create_user_missing_field(client):
    """Тест POST /api/users с пропущенным полем."""
    user_data = {"name": "Jane Doe"}  # email пропущен
    response = client.post('/api/users',
                           data=json.dumps(user_data),
                           content_type='application/json')
    assert response.status_code == 400
    # Можно проверить и сообщение об ошибке, но это зависит от реализации abort
    # В Flask abort по умолчанию возвращает HTML, а не JSON. Для простоты оставим так.

# Дополнительный тест для проверки создания и получения
def test_create_and_get_user(client):
    # 1. Создаем пользователя
    user_data = {"name": "Test User", "email": "test@user.com"}
    post_resp = client.post('/api/users', data=json.dumps user_data, content_type='application/json')
    assert post_resp.status_code == 201
    created_user = post_resp.get_json()
    user_id = created_user['id']

    # 2. Получаем его по ID
    get_resp = client.get(f'/api/users/{user_id}')
    assert get_resp.status_code == 200
    assert get_resp.get_json() == created_user
