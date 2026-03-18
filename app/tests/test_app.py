import pytest
import json
from app.main import app as flask_app

@pytest.fixture
def app():
    yield flask_app

@pytest.fixture
def client(app):
    return app.test_client()

def test_get_root(client):
    """Тест GET /"""
    response = client.get('/')
    assert response.status_code == 200
    assert response.get_json() == {"message": "Hello, World!"}

def test_get_health(client):
    response = client.get('/health')
    assert response.status_code == 200
    assert response.get_json() == {"status": "ok"}

def test_get_users_empty(client):
    response = client.get('/api/users')
    assert response.status_code == 200
    assert response.get_json() == {"users": []}

def test_create_user_success(client):
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
    user_data = {"name": "Jane Doe"} 
    response = client.post('/api/users',
                           data=json.dumps(user_data),
                           content_type='application/json')
    assert response.status_code == 400

def test_create_and_get_user(client):
    user_data = {"name": "Test User", "email": "test@user.com"}
    post_resp = client.post('/api/users', data=json.dumps(user_data), content_type='application/json')
    assert post_resp.status_code == 201
    created_user = post_resp.get_json()
    user_id = created_user['id']

    get_resp = client.get(f'/api/users/{user_id}')
    assert get_resp.status_code == 200
    assert get_resp.get_json() == created_user
