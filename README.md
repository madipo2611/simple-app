# Simple-App

Простое REST API приложение для демонстрации навыков DevOps. Проект включает в себя Python (Flask) приложение, Bash-скрипт для диагностики, Docker-контейнеризацию, локальный оркестратор Docker Compose, а также CI/CD через GitHub Actions и автоматизацию развертывания с Ansible.

## Требования

-   **Python 3.12+** (для локального запуска)
-   **Docker** и **Docker Compose** (для запуска в контейнерах)
-   **Ansible** (для удаленного развертывания)
-   **Make** (для использования Makefile)

## Быстрый старт

### Локальный запуск (без Docker)

1.  **Клонируйте репозиторий:**
    `git clone https://github.com/madipo2611/simple-app && cd simple-app`

2.  **Установите зависимости:**
    `pip install -r app/requirements.txt`

3.  **Запустите приложение:**
    `python app/main.py`

4.  **Проверьте:**
    `curl http://localhost:5000/health`

### Запуск через Docker Compose

1.  **Запустите сервис:**
    `docker-compose up -d`

2.  **Проверьте статус:**
    `docker-compose ps`

3.  **Посмотрите логи:**
    `docker-compose logs -f app`

4.  **Остановите сервис:**
    `docker-compose down`

## API Endpoints

| Метод | URL | Описание | Пример успешного ответа |
| :--- | :--- | :--- | :--- |
| `GET` | `/` | Приветственное сообщение | `{"message": "Hello, World!"}` |
| `GET` | `/health` | Проверка здоровья | `{"status": "ok"}` |
| `GET` | `/api/users` | Получить список всех пользователей | `{"users": [{"id": 1, "name": "...", "email": "..."}]}` |
| `POST` | `/api/users` | Создать нового пользователя | `{"id": 1, "name": "...", "email": "..."}` (201 Created) |
| `GET` | `/api/users/<id>` | Получить пользователя по ID | `{"id": 1, "name": "...", "email": "..."}` |
| `DELETE` | `/api/users/<id>` | Удалить пользователя по ID | (204 No Content) |

**Примеры использования curl:**

*   `curl -X GET http://localhost:5000/`
*   `curl -X POST http://localhost:5000/api/users -H "Content-Type: application/json" -d '{"name": "Ivan", "email": "ivan@example.com"}'`

## Bash-скрипт диагностики

Скрипт `scripts/server-info.sh` собирает информацию о системе и проверяет доступность сервисов.

**Использование:**

*   `./scripts/server-info.sh` — только информация о системе.
*   `./scripts/server-info.sh http://localhost:5000/health http://example.com` — информация + проверка URL.
*   `./scripts/server-info.sh --help` — справка.

Скрипт логирует результаты в файл `server-info.log` и возвращает exit code 1, если какой-либо из переданных URL недоступен.

## Тестирование

Для запуска тестов используйте pytest:

```bash
pytest app/tests/ -v
