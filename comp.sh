#!/bin/bash

SCRIPT_DIR="$(dirname "$0")" # Получаем директорию скрипта
LOG_DIR="$SCRIPT_DIR/log"
BACKUP_DIR="$SCRIPT_DIR/backup"
MAX_SIZE=$((2 * 1024 * 1024 * 1024))  # 2 ГБ в байтах
THRESHOLD_SIZE=$((MAX_SIZE * 70 / 100))  # 70% от 2 ГБ

# Проверка аргументов
if [ $# -ne 1 ]; then
    echo "Использование: $0 <порог_в_%>"
    exit 1
fi

# Создание папок, если они не существуют
mkdir -p "$LOG_DIR" "$BACKUP_DIR"

# Получение текущего размера папки в байтах
CURRENT_SIZE=$(du -sb "$LOG_DIR" | awk '{print $1}')

# Проверка заполнения
if [ "$CURRENT_SIZE" -ge "$THRESHOLD_SIZE" ]; then
    echo "Папка $LOG_DIR заполнена на $(($CURRENT_SIZE / 1024 / 1024)) MB. Начинаю архивирование..."

    # Находим N старейших файлов
    N=5
    OLD_FILES=$(ls -t "$LOG_DIR" | tail -n "$N")
    if [ -z "$OLD_FILES" ]; then
        echo "Нет файлов для архивирования."
        exit 0
    fi

    # Создание архива
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    ARCHIVE_FILE="$BACKUP_DIR/archive_$TIMESTAMP.tar.gz"
    tar -czf "$ARCHIVE_FILE" -C "$LOG_DIR" $OLD_FILES

    # Удаление архивированных файлов
    for file in $OLD_FILES; do
        rm "$LOG_DIR/$file"
    done

    echo "Файлы архивированы в $ARCHIVE_FILE и удалены из $LOG_DIR."
else
    echo "Папка $LOG_DIR заполнена на $(($CURRENT_SIZE / 1024 / 1024)) MB. Архивирование не требуется."
fi
