FROM python:3.12-slim-bookworm AS builder

WORKDIR /app

# Копируем только requirements для кеширования зависимостей
COPY app/requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

Финальный образ
FROM python:3.12-slim-bookworm

RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# Копируем установленные пакеты из builder'а
COPY --from=builder /root/.local /home/appuser/.local
# Копируем код приложения
COPY app ./app

# Обновляем PATH, чтобы использовать pip пакеты из домашней папки пользователя
ENV PATH=/home/appuser/.local/bin:$PATH

# Меняем владельца файлов на appuser
RUN chown -R appuser:appuser /app /home/appuser/.local

# Переключаемся на непривилегированного пользователя
USER appuser

# Открываем порт
EXPOSE 5000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:5000/health || exit 1

# Запускаем приложение через gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app.main:app"]
