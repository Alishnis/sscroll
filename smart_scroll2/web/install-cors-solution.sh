#!/bin/bash

# CORS Solution Installation Script
# Автоматическая установка CORS решения для SmartScroll

echo "🔧 Установка CORS Solution для SmartScroll..."
echo "================================================"

# Проверяем, что мы в правильной директории
if [ ! -f "reddit_advanced_service.js" ]; then
    echo "❌ Ошибка: Запустите скрипт из директории web/"
    echo "   cd web/"
    echo "   ./install-cors-solution.sh"
    exit 1
fi

# Проверяем Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js не найден!"
    echo "   Пожалуйста, установите Node.js: https://nodejs.org/"
    exit 1
fi

echo "✅ Node.js найден: $(node --version)"

# Проверяем npm
if ! command -v npm &> /dev/null; then
    echo "❌ npm не найден!"
    exit 1
fi

echo "✅ npm найден: $(npm --version)"

# Устанавливаем зависимости
echo ""
echo "📦 Устанавливаем зависимости..."
npm install

if [ $? -ne 0 ]; then
    echo "❌ Ошибка установки зависимостей"
    exit 1
fi

echo "✅ Зависимости установлены успешно"

# Проверяем, что все файлы на месте
echo ""
echo "🔍 Проверяем файлы CORS решения..."

required_files=(
    "cors-proxy-server.js"
    "package.json"
    "start-cors-proxy.sh"
    "test-cors-solution.html"
    "CORS_SOLUTION_README.md"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file - файл не найден!"
        exit 1
    fi
done

# Делаем скрипт запуска исполняемым
chmod +x start-cors-proxy.sh

echo ""
echo "🎉 CORS Solution установлен успешно!"
echo ""
echo "📋 Следующие шаги:"
echo "   1. Запустите CORS Proxy Server:"
echo "      ./start-cors-proxy.sh"
echo ""
echo "   2. Откройте тестовую страницу:"
echo "      http://localhost:8000/test-cors-solution.html"
echo ""
echo "   3. Проверьте работу в SmartScroll:"
echo "      http://localhost:8000/posts.html"
echo ""
echo "📚 Документация: CORS_SOLUTION_README.md"
echo ""
echo "🚀 Готово! Теперь CORS ошибки должны быть решены."

