#!/bin/bash

# Smart Scroll Video Conference Startup Script
# Скрипт для запуска видеоконференций

echo "🚀 Запуск Smart Scroll Video Conference..."

# Проверка наличия Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js не установлен. Пожалуйста, установите Node.js с https://nodejs.org/"
    exit 1
fi

# Проверка наличия npm
if ! command -v npm &> /dev/null; then
    echo "❌ npm не установлен. Пожалуйста, установите npm"
    exit 1
fi

# Проверка наличия .env файла
if [ ! -f ".env" ]; then
    echo "⚠️  Файл .env не найден. Создаю из примера..."
    if [ -f "env.example" ]; then
        cp env.example .env
        echo "📝 Файл .env создан из env.example"
        echo "🔧 Пожалуйста, отредактируйте .env файл и добавьте ваши Twilio API ключи"
        echo "📖 Инструкции: см. CONFERENCE_SETUP.md"
        exit 1
    else
        echo "❌ Файл env.example не найден"
        exit 1
    fi
fi

# Проверка установки зависимостей
if [ ! -d "node_modules" ]; then
    echo "📦 Установка зависимостей..."
    npm install
    if [ $? -ne 0 ]; then
        echo "❌ Ошибка установки зависимостей"
        exit 1
    fi
    echo "✅ Зависимости установлены"
fi

# Проверка переменных окружения
source .env
if [ -z "$TWILIO_ACCOUNT_SID" ] || [ -z "$TWILIO_API_KEY" ] || [ -z "$TWILIO_API_SECRET" ]; then
    echo "❌ Переменные окружения Twilio не настроены"
    echo "🔧 Пожалуйста, отредактируйте .env файл и добавьте:"
    echo "   TWILIO_ACCOUNT_SID=your_account_sid"
    echo "   TWILIO_API_KEY=your_api_key"
    echo "   TWILIO_API_SECRET=your_api_secret"
    exit 1
fi

echo "✅ Конфигурация проверена"

# Запуск сервера
echo "🌐 Запуск сервера на порту ${PORT:-3000}..."
echo "📱 Откройте браузер и перейдите по адресу: http://localhost:${PORT:-3000}"
echo "🛑 Для остановки нажмите Ctrl+C"

npm start
