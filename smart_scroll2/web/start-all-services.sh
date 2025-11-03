#!/bin/bash

# Скрипт для запуска всех сервисов SmartScroll
# Включает CORS Proxy Server и основной веб-сервер

echo "🚀 Запуск всех сервисов SmartScroll..."
echo "========================================"

# Проверяем, что мы в правильной директории
if [ ! -f "posts.html" ]; then
    echo "❌ Ошибка: Запустите скрипт из директории web/"
    echo "   cd web/"
    echo "   ./start-all-services.sh"
    exit 1
fi

# Функция для проверки, запущен ли процесс на порту
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0  # Порт занят
    else
        return 1  # Порт свободен
    fi
}

# Проверяем порт 3003 (CORS Proxy)
if check_port 3003; then
    echo "✅ CORS Proxy Server уже запущен на порту 3003"
else
    echo "🔄 Запускаем CORS Proxy Server..."
    node cors-proxy-server.js &
    CORS_PID=$!
    echo "✅ CORS Proxy Server запущен (PID: $CORS_PID)"
    
    # Ждем запуска CORS Proxy
    sleep 3
    
    # Проверяем, что CORS Proxy работает
    if curl -s http://localhost:3003/health >/dev/null 2>&1; then
        echo "✅ CORS Proxy Server работает корректно"
    else
        echo "❌ CORS Proxy Server не отвечает"
        exit 1
    fi
fi

# Проверяем порт 8000 (основной веб-сервер)
if check_port 8000; then
    echo "✅ Веб-сервер уже запущен на порту 8000"
else
    echo "🔄 Запускаем веб-сервер..."
    # Используем Python HTTP сервер
    python3 -m http.server 8000 &
    WEB_PID=$!
    echo "✅ Веб-сервер запущен (PID: $WEB_PID)"
fi

echo ""
echo "🎉 Все сервисы запущены!"
echo ""
echo "📡 Доступные сервисы:"
echo "   • CORS Proxy Server: http://localhost:3003"
echo "   • Веб-сервер: http://localhost:8000"
echo "   • Health Check: http://localhost:3003/health"
echo ""
echo "🌐 Откройте в браузере:"
echo "   • Главная страница: http://localhost:8000"
echo "   • Посты: http://localhost:8000/posts.html"
echo "   • Тест CORS: http://localhost:8000/test-cors-solution.html"
echo ""
echo "🔧 Для остановки сервисов нажмите Ctrl+C"
echo ""

# Функция для корректного завершения
cleanup() {
    echo ""
    echo "🛑 Останавливаем сервисы..."
    if [ ! -z "$CORS_PID" ]; then
        kill $CORS_PID 2>/dev/null
        echo "✅ CORS Proxy Server остановлен"
    fi
    if [ ! -z "$WEB_PID" ]; then
        kill $WEB_PID 2>/dev/null
        echo "✅ Веб-сервер остановлен"
    fi
    echo "👋 Все сервисы остановлены"
    exit 0
}

# Перехватываем сигналы для корректного завершения
trap cleanup SIGINT SIGTERM

# Ждем завершения
wait

