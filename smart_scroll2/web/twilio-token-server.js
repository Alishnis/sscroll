'use strict';

/**
 * Twilio Video Token Server
 * Генерирует токены доступа для Twilio Video
 * 
 * Требуемые переменные окружения:
 * - TWILIO_ACCOUNT_SID
 * - TWILIO_API_KEY  
 * - TWILIO_API_SECRET
 */

// Загружаем переменные окружения из .env файла
require('dotenv').config();

const express = require('express');
const { jwt: { AccessToken } } = require('twilio');
const path = require('path');
const cors = require('cors');

const VideoGrant = AccessToken.VideoGrant;

// Максимальное время сессии (4 часа)
const MAX_ALLOWED_SESSION_DURATION = 14400;

// Создание Express приложения
const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname)));

// Проверка переменных окружения
const requiredEnvVars = ['TWILIO_ACCOUNT_SID', 'TWILIO_API_KEY', 'TWILIO_API_SECRET'];
const missingEnvVars = requiredEnvVars.filter(envVar => !process.env[envVar]);

if (missingEnvVars.length > 0) {
    console.error('❌ Отсутствуют обязательные переменные окружения:');
    missingEnvVars.forEach(envVar => console.error(`   - ${envVar}`));
    console.error('\n📝 Создайте файл .env с следующими переменными:');
    console.error('TWILIO_ACCOUNT_SID=your_account_sid');
    console.error('TWILIO_API_KEY=your_api_key');
    console.error('TWILIO_API_SECRET=your_api_secret');
    process.exit(1);
}

/**
 * Генерация токена доступа для Twilio Video
 * GET /token?identity=username
 */
app.get('/token', function(request, response) {
    const { identity } = request.query;

    if (!identity) {
        return response.status(400).json({
            error: 'Параметр identity обязателен'
        });
    }

    try {
        console.log('🔑 Генерация токена для:', identity);
        console.log('📋 Account SID:', process.env.TWILIO_ACCOUNT_SID);
        console.log('📋 API Key:', process.env.TWILIO_API_KEY ? 'установлен' : 'не установлен');
        console.log('📋 API Secret:', process.env.TWILIO_API_SECRET ? 'установлен' : 'не установлен');

        // Создание токена доступа
        const token = new AccessToken(
            process.env.TWILIO_ACCOUNT_SID,
            process.env.TWILIO_API_KEY,
            process.env.TWILIO_API_SECRET,
            { 
                ttl: MAX_ALLOWED_SESSION_DURATION,
                identity: identity
            }
        );

        // Предоставление возможностей Twilio Video
        const grant = new VideoGrant();
        token.addGrant(grant);

        // Сериализация токена в JWT строку
        const jwt = token.toJwt();
        
        console.log(`✅ Токен сгенерирован для пользователя: ${identity}`);
        console.log(`📄 Токен (первые 50 символов): ${jwt.substring(0, 50)}...`);
        response.send(jwt);
        
    } catch (error) {
        console.error('❌ Ошибка генерации токена:', error);
        console.error('❌ Детали ошибки:', error.message);
        console.error('❌ Стек ошибки:', error.stack);
        response.status(500).json({
            error: 'Ошибка генерации токена доступа',
            details: error.message
        });
    }
});

/**
 * Получение информации о комнате
 * GET /room/:roomName
 */
app.get('/room/:roomName', function(request, response) {
    const { roomName } = request.params;
    
    // В реальном приложении здесь можно получить информацию о комнате из базы данных
    // Пока возвращаем базовую информацию
    response.json({
        roomName: roomName,
        participants: [],
        status: 'active'
    });
});

/**
 * Проверка состояния сервера
 * GET /health
 */
app.get('/health', function(request, response) {
    response.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        twilio: {
            accountSid: process.env.TWILIO_ACCOUNT_SID ? 'configured' : 'missing',
            apiKey: process.env.TWILIO_API_KEY ? 'configured' : 'missing',
            apiSecret: process.env.TWILIO_API_SECRET ? 'configured' : 'missing'
        }
    });
});

/**
 * Главная страница - перенаправление на конференцию
 */
app.get('/', function(request, response) {
    response.redirect('/conference-template-new.html');
});

/**
 * Прямой доступ к конференции
 */
app.get('/conference', function(request, response) {
    response.redirect('/conference-template-new.html');
});

// Обработка ошибок
app.use(function(error, request, response, next) {
    console.error('❌ Ошибка сервера:', error);
    response.status(500).json({
        error: 'Внутренняя ошибка сервера'
    });
});

// Запуск сервера
const port = process.env.PORT || 3000;
app.listen(port, function() {
    console.log('🚀 Twilio Video Token Server запущен');
    console.log(`📡 Порт: ${port}`);
    console.log(`🌐 URL: http://localhost:${port}`);
    console.log('📋 Доступные эндпоинты:');
    console.log(`   - GET /token?identity=username - генерация токена`);
    console.log(`   - GET /room/:roomName - информация о комнате`);
    console.log(`   - GET /health - состояние сервера`);
    console.log(`   - GET / - главная страница`);
});

module.exports = app;


