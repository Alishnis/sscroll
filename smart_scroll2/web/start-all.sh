#!/bin/bash

echo "🚀 Запуск всех серверов Smart Scroll..."

# Запуск основного сервера на порту 3000
echo "📡 Запуск HTTP сервера на порту 3000..."
python3 -m http.server 3000 &
HTTP_PID=$!

# Запуск Twilio сервера на порту 3001
echo "📹 Запуск Twilio сервера на порту 3001..."
TWILIO_ACCOUNT_SID=demo TWILIO_API_KEY=demo TWILIO_API_SECRET=demo node twilio-token-server.js &
TWILIO_PID=$!

# Запуск CORS прокси на порту 3002
echo "🌐 Запуск CORS прокси на порту 3002..."
node cors-proxy.js &
PROXY_PID=$!

echo "✅ Все серверы запущены!"
echo "📋 Доступные серверы:"
echo "   - HTTP Server: http://localhost:3000"
echo "   - Twilio Server: http://localhost:3001"
echo "   - CORS Proxy: http://localhost:3002"
echo ""
echo "🛑 Для остановки всех серверов нажмите Ctrl+C"

# Обработка сигнала завершения
trap 'echo "🛑 Остановка серверов..."; kill $HTTP_PID $TWILIO_PID $PROXY_PID; exit' INT

# Ожидание
wait
