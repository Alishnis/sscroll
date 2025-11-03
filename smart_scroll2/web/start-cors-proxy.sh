#!/bin/bash

# CORS Proxy Server Startup Script
# Решает проблемы с CORS для Reddit API

echo "🚀 Запуск CORS Proxy Server для SmartScroll..."

# Проверяем, установлен ли Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js не найден. Пожалуйста, установите Node.js:"
    echo "   https://nodejs.org/"
    exit 1
fi

# Проверяем, установлен ли npm
if ! command -v npm &> /dev/null; then
    echo "❌ npm не найден. Пожалуйста, установите npm"
    exit 1
fi

# Переходим в директорию web
cd "$(dirname "$0")"

# Проверяем, существует ли package.json
if [ ! -f "package.json" ]; then
    echo "❌ package.json не найден в директории web/"
    exit 1
fi

# Устанавливаем зависимости, если node_modules не существует
if [ ! -d "node_modules" ]; then
    echo "📦 Устанавливаем зависимости..."
    npm install
    if [ $? -ne 0 ]; then
        echo "❌ Ошибка установки зависимостей"
        exit 1
    fi
fi

# Проверяем, не запущен ли уже сервер на порту 3003
if lsof -Pi :3003 -sTCP:LISTEN -t >/dev/null ; then
    echo "⚠️  Порт 3003 уже занят. Останавливаем существующий процесс..."
    kill $(lsof -Pi :3003 -sTCP:LISTEN -t)
    sleep 2
fi

# Запускаем CORS Proxy Server
echo "🌐 Запускаем CORS Proxy Server на порту 3003..."
echo "📡 Reddit API будет доступен через: http://localhost:3003/reddit/"
echo "💚 Health check: http://localhost:3003/health"
echo ""
echo "🔧 Для остановки сервера нажмите Ctrl+C"
echo ""

node cors-proxy-server.js

