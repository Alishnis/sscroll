const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');

const app = express();
const PORT = 3007;

// Middleware
app.use(cors());
app.use(express.json());

// Ваши учетные данные Twilio
const accountSid = 'ACc5b4990f3c60ef296466da3c84e3408d';
const apiKey = 'SKb2523ecc09bdcdfc86813be6c1a8b7a3';
const apiSecret = '6UB9HVhMOyZ0sonCNSE5NIgOU0bw5Xcn';

// Создание токена
app.get('/token', (req, res) => {
    try {
        const identity = req.query.identity || 'anonymous';
        
        // Создаем JWT токен
        const token = jwt.sign(
            {
                jti: apiKey + '-' + Date.now(),
                iss: apiKey,
                sub: accountSid,
                iat: Math.floor(Date.now() / 1000),
                exp: Math.floor(Date.now() / 1000) + 3600, // 1 час
                grants: {
                    identity: identity,
                    video: {
                        room: '*'
                    }
                }
            },
            apiSecret,
            {
                algorithm: 'HS256',
                header: {
                    typ: 'JWT',
                    alg: 'HS256',
                    cty: 'twilio-fpa;v=1'
                }
            }
        );
        
        console.log(`✅ Токен создан для пользователя: ${identity}`);
        res.send(token);
    } catch (error) {
        console.error('❌ Ошибка создания токена:', error);
        res.status(500).send('Ошибка создания токена');
    }
});

// Информация о сервере
app.get('/info', (req, res) => {
    res.json({
        status: 'running',
        port: PORT,
        accountSid: accountSid,
        message: 'Сервер токенов Twilio работает'
    });
});

// Запуск сервера
app.listen(PORT, () => {
    console.log(`🚀 Сервер токенов запущен на порту ${PORT}`);
    console.log(`📡 URL: http://localhost:${PORT}`);
    console.log(`🔑 Account SID: ${accountSid}`);
    console.log(`🔑 API Key: ${apiKey}`);
});

module.exports = app;
