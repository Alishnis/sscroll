#!/bin/bash

# Скрипт для запуска TTS сервера
# Использует Festival TTS из папки #2

echo "🎤 Запуск TTS сервера Smart Scroll..."

# Переходим в папку с Festival
cd "/Users/aliserromankul/Desktop/smartscrolling/smart_scroll2/#2/festival"

# Проверяем, существует ли папка
if [ ! -d "." ]; then
    echo "❌ Папка Festival не найдена!"
    echo "Убедитесь, что папка #2/festival существует"
    exit 1
fi

# Проверяем наличие Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 не найден!"
    echo "Установите Python3 для работы TTS сервера"
    exit 1
fi

# Проверяем наличие Flask
if ! python3 -c "import flask" &> /dev/null; then
    echo "⚠️ Flask не установлен. Устанавливаем..."
    pip3 install flask
fi

echo "🚀 Запуск Festival TTS веб-сервера..."
echo "📍 Адрес: http://localhost:5001"
echo "🔗 Festival сервер: localhost:1314"
echo ""
echo "Для остановки нажмите Ctrl+C"
echo ""

# Запускаем веб-сервер
python3 web_server.py
