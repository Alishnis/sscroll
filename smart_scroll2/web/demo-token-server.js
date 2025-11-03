'use strict';

/**
 * Demo Twilio Video Token Server
 * Демо-сервер для тестирования без реальных Twilio ключей
 */

// Загружаем переменные окружения из .env файла
require('dotenv').config();

const express = require('express');
const path = require('path');
const cors = require('cors');

// Создание Express приложения
const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname)));

// Максимальное время сессии (4 часа)
const MAX_ALLOWED_SESSION_DURATION = 14400;

/**
 * Генерация демо токена доступа для Twilio Video
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
        // Создаем демо JWT токен
        const demoToken = `demo_token_${identity}_${Date.now()}`;
        
        console.log(`✅ Демо токен сгенерирован для пользователя: ${identity}`);
        response.send(demoToken);
        
    } catch (error) {
        console.error('❌ Ошибка генерации демо токена:', error);
        response.status(500).json({
            error: 'Ошибка генерации демо токена доступа'
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
        mode: 'demo',
        message: 'Демо сервер работает'
    });
});

/**
 * Главная страница - перенаправление на демо конференцию
 */
app.get('/', function(request, response) {
    response.redirect('/demo-conference.html');
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
    console.log('🚀 Demo Twilio Video Token Server запущен');
    console.log(`📡 Порт: ${port}`);
    console.log(`🌐 URL: http://localhost:${port}`);
    console.log('📋 Доступные эндпоинты:');
    console.log(`   - GET /token?identity=username - генерация демо токена`);
    console.log(`   - GET /room/:roomName - информация о комнате`);
    console.log(`   - GET /health - состояние сервера`);
    console.log(`   - GET / - главная страница`);
    console.log('⚠️  ВНИМАНИЕ: Это демо-режим без реальных Twilio ключей');
});

module.exports = app;
