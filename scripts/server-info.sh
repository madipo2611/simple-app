#!/usr/bin/env bash
set -euo pipefail # Прерывать выполнение при ошибке, неопределенной переменной, ошибке в пайпе

# --- Конфигурация ---
LOG_FILE="./server-info.log" # Или /var/log/server-info.log, если есть права
SCRIPT_NAME=$(basename "$0")
VERSION="1.0.0"

# --- Функции ---

# Функция для вывода справки
show_help() {
    cat << EOF
Использование: $SCRIPT_NAME [--help] [URL1 URL2 ...]

Скрипт диагностики сервера. Собирает информацию о системе, ресурсах и проверяет
доступность указанных HTTP-сервисов.

Аргументы:
  URL1 URL2 ...   Список URL для проверки здоровья (опционально).
  --help          Показать эту справку.

Примеры:
  $SCRIPT_NAME
  $SCRIPT_NAME http://localhost:5000/health http://example.com/health
EOF
}

# Функция для логирования с временной меткой
log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

# Функция для сбора системной информации
get_system_info() {
    echo "=== Server Diagnostics ==="
    log_message "=== Server Diagnostics ==="

    local hostname=$(hostname)
    local os_info=$(lsb_release -d 2>/dev/null | cut -f2 || grep -m1 '^PRETTY_NAME' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "N/A")
    local kernel=$(uname -r)
    local uptime_info=$(uptime -p | sed 's/up //')

    echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Hostname: $hostname"
    echo "OS: $os_info"
    echo "Kernel: $kernel"
    echo "Uptime: $uptime_info"
}

# Функция для сбора информации о ресурсах
get_resources() {
    echo -e "\n=== Resources ==="
    log_message "=== Resources ==="

    # CPU Load
    local load=$(uptime | awk -F'load average:' '{print $2}' | xargs)
    local cpu_cores=$(nproc 2>/dev/null || echo "N/A")
    echo "CPU: $cpu_cores cores, load average: $load"

    # RAM
    if command -v free &> /dev/null; then
        local ram_total=$(free -h | awk '/^Mem:/ {print $2}')
        local ram_used=$(free -h | awk '/^Mem:/ {print $3}')
        local ram_percent=$(free | awk '/^Mem:/ {printf "%.1f", $3/$2 * 100}')
        echo "RAM: ${ram_used} / ${ram_total} (${ram_percent}%)"
    else
        echo "RAM: N/A (free command not found)"
    fi

    # Disk
    local disk_used=$(df -h / | awk 'NR==2 {print $3}')
    local disk_total=$(df -h / | awk 'NR==2 {print $2}')
    local disk_percent=$(df -h / | awk 'NR==2 {print $5}')
    echo "Disk /: $disk_used / $disk_total ($disk_percent)"
}

# Функция для проверки Docker
check_docker() {
    echo -e "\n=== Docker ==="
    log_message "=== Docker ==="
    if command -v docker &> /dev/null; then
        if docker info &>/dev/null; then
            echo "CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS   PORTS   NAMES" # Заголовок для красоты
            docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}" | tail -n +2 || echo "No running containers"
        else
            echo "Docker daemon is not running or permission denied."
        fi
    else
        echo "Docker is not installed."
    fi
}

# Функция для проверки HTTP сервисов
check_services() {
    local urls=("$@")
    if [ ${#urls[@]} -eq 0 ]; then
        return 0 # Нет URL для проверки
    fi

    echo -e "\n=== Service Health Checks ==="
    log_message "=== Service Health Checks ==="
    local success_count=0
    local total_count=${#urls[@]}

    for url in "${urls[@]}"; do
        local status_code
        local time_total
        local result="FAIL"
        local exit_status=1

        if command -v curl &> /dev/null; then
            # Используем curl для проверки
            local curl_output
            curl_output=$(curl -o /dev/null -s -w "%{http_code} %{time_total}" --connect-timeout 5 --max-time 10 "$url" 2>&1) || exit_status=$?
            if [ $exit_status -eq 0 ]; then
                read -r status_code time_total <<< "$curl_output"
                if [[ "$status_code" -ge 200 && "$status_code" -lt 400 ]]; then
                    result="OK"
                    ((success_count++))
                    echo "[$result] $url ($status_code, ${time_total}ms)"
                else
                    echo "[$result] $url (HTTP $status_code)"
                fi
            else
                 echo "[$result] $url (curl error: connection refused or timeout)"
            fi
        else
            echo "curl is not installed. Cannot check services."
            return 1
        fi
    done

    echo "Result: $success_count/$total_count services healthy"
    if [ $success_count -eq 0 ]; then
        return 1 # Возвращаем ошибку, если ни один сервис не доступен
    elif [ $success_count -lt $total_count ]; then
        return 1 # Возвращаем ошибку, если доступны не все
    else
        return 0
    fi
}

# --- Основная логика ---

# Обработка аргументов
urls=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --help)
            show_help
            exit 0
            ;;
        -*)
            echo "Неизвестная опция: $1"
            show_help
            exit 1
            ;;
        *)
            urls+=("$1")
            shift
            ;;
    esac
done

# Проверка зависимостей
for cmd in curl; do
    if ! command -v $cmd &> /dev/null; then
        echo "Ошибка: '$cmd' не найден. Пожалуйста, установите его." >&2
        exit 1
    fi
done

# Запуск функций
get_system_info
get_resources
check_docker

# Проверка сервисов и сохранение exit code
final_exit_code=0
if ! check_services "${urls[@]}"; then
    final_exit_code=1
fi

log_message "Script finished with exit code $final_exit_code"
exit $final_exit_code
