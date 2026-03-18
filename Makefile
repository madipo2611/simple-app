.PHONY: help install lint test run server-info docker-build docker-run compose-up compose-down compose-logs ansible-check ansible-dry ansible-run

# Переменные
APP_DIR = app
SCRIPT_DIR = scripts
ANSIBLE_DIR = ansible
DOCKER_IMAGE_NAME = simple-app
DOCKER_CONTAINER_NAME = simple-app
DOCKER_COMPOSE = docker compose

help: ## Показать все команды
	@echo "Доступные команды:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Установить зависимости Python
	pip install -r $(APP_DIR)/requirements.txt

lint: ## Проверить качество кода (ruff для Python, shellcheck для Bash)
	@echo "Линтинг Python..."
	ruff check $(APP_DIR) || true 
	@echo "\nЛинтинг Bash..."
	shellcheck $(SCRIPT_DIR)/*.sh

test: ## Запустить тесты
	pytest $(APP_DIR)/tests/ -v

run: ## Запустить приложение локально
	python $(APP_DIR)/main.py

server-info: ## Запустить Bash-скрипт диагностики сервера
	./$(SCRIPT_DIR)/server-info.sh

docker-build: ## Собрать Docker образ
	docker build -t $(DOCKER_IMAGE_NAME):latest .

docker-run: ## Запустить Docker контейнер (в фоне)
	docker run -d --name $(DOCKER_CONTAINER_NAME) -p 5000:5000 $(DOCKER_IMAGE_NAME):latest

docker-stop: ## Остановить и удалить контейнер
	docker stop $(DOCKER_CONTAINER_NAME) || true && docker rm $(DOCKER_CONTAINER_NAME) || true

compose-up: ## Запустить Docker Compose (в фоне)
	$(DOCKER_COMPOSE) up -d

compose-down: ## Остановить Docker Compose
	$(DOCKER_COMPOSE) down

compose-logs: ## Просмотреть логи Docker Compose
	$(DOCKER_COMPOSE) logs -f app

compose-ps: ## Показать статус контейнеров
	$(DOCKER_COMPOSE) ps

compose-restart: ## Перезапустить сервисы
	$(DOCKER_COMPOSE) restart

ansible-check: ## Проверить синтаксис Ansible playbook
	ansible-playbook --syntax-check -i $(ANSIBLE_DIR)/inventory.ini $(ANSIBLE_DIR)/playbook.yml

ansible-dry: ## Dry-run Ansible playbook
	ansible-playbook -i $(ANSIBLE_DIR)/inventory.ini $(ANSIBLE_DIR)/playbook.yml --check

ansible-run: ## Запустить Ansible playbook
	ansible-playbook -i $(ANSIBLE_DIR)/inventory.ini $(ANSIBLE_DIR)/playbook.yml
