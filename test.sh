#!/bin/bash

SCRIPT_DIR="$(dirname "$0")" # Получаем директорию скрипта
LOG_DIR="$SCRIPT_DIR/log"
BACKUP_DIR="$SCRIPT_DIR/backup"

# Создание папок, если они не существуют
mkdir -p "$LOG_DIR" "$BACKUP_DIR"

#Ограничение папки
dd if=/dev/zero of=env.img bs=1M count=2048
mkfs.ext4 env.img
sudo mount -o loop env.img "$LOG_DIR"
sudo chmod 777 "$LOG_DIR"
rm -rf "$LOG_DIR"/lost+found
rm env.img

# Очистка
rm -rf "$LOG_DIR"/* "$BACKUP_DIR"/*

# Генерация тестовых файлов (общий размер = 2 ГБ)
for i in {1..10}; do
    dd if=/dev/zero of="$LOG_DIR/testfile$i.txt" bs=200M count=1 > /dev/null 2>&1
done

# Тест 1: Проверка архивирования при заполнении > 70%
echo "Запуск теста 1..."
initial_count=$(ls -1 "$BACKUP_DIR" | wc -l)
./comp.sh 70
new_count=$(ls -1 "$BACKUP_DIR" | wc -l)

if [ $((new_count - initial_count)) -eq 1 ]; then
    echo -e "\e[42mТест 1 пройден: Архив создан.\e[0m"
else
    echo -e "\e[41mТест 1 не пройден: Архив не создан.\e[0m"
fi

# Очистка
rm -rf "$LOG_DIR"/*

# Генерация новых файлов (общий размер = 1.4 ГБ)
for i in {1..7}; do
    dd if=/dev/zero of="$LOG_DIR/testfile$i.txt" bs=200M count=1 > /dev/null 2>&1
done

# Тест 2: Проверка архивирования при заполнении = 70%
echo "Запуск теста 2..."
initial_count=$(ls -1 "$BACKUP_DIR" | wc -l)
./comp.sh 70
new_count=$(ls -1 "$BACKUP_DIR" | wc -l)

if [ $((new_count - initial_count)) -eq 0 ]; then
    echo -e "\e[42mТест 2 пройден: Архив не создан.\e[0m"
else
    echo -e "\e[41mТест 2 не пройден: Архив не должен был быть создан.\e[0m"
fi

# Тест 3: Проверка, когда заполнение < 70%
echo "Запуск теста 3..."
rm -f "$LOG_DIR"/*  # Удаляем файлы для теста

# Создаем только небольшой файл, чтобы заполнение было < 70% (общий размер = 0.1 ГБ)
dd if=/dev/zero of="$LOG_DIR/smallfile.txt" bs=100M count=1 > /dev/null 2>&1

initial_count=$(ls -1 "$BACKUP_DIR" | wc -l)
./comp.sh 70
new_count=$(ls -1 "$BACKUP_DIR" | wc -l)

if [ $((new_count - initial_count)) -eq 0 ]; then
    echo -e "\e[42mТест 3 пройден: Архив не создан.\e[0m"
else
    echo -e "\e[41mТест 3 не пройден: Архив не должен был быть создан.\e[0m"
fi

# Очистка
rm -rf "$LOG_DIR"/*

# Генерация новых файлов
for i in {1..10}; do
    dd if=/dev/zero of="$LOG_DIR/testfile$i.txt" bs=200M count=1 > /dev/null 2>&1
done

# Тест 4: Проверка архивирования N старейших файлов
echo "Запуск теста 4..."
initial_count=$(ls -1 "$BACKUP_DIR" | wc -l)
./comp.sh 70
new_count=$(ls -1 "$BACKUP_DIR" | wc -l)

if [ $((new_count - initial_count)) -eq 1 ]; then
    echo -e "\e[42mТест 4 пройден: Архив создан.\e[0m"
else
    echo -e "\e[41mТест 4 не пройден: Архив не создан.\e[0m"
fi

#Отключение ограниченной папки
sudo umount "$LOG_DIR"
echo -e "$LOG_DIR folder \e[4munmounted\e[0m."