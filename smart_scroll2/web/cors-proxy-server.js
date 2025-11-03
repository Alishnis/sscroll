/**
 * CORS Proxy Server для решения проблем с CORS
 * Запускает локальный прокси-сервер для обхода CORS ограничений
 * Версия: 1.0
 */

const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = 3003; // Используем другой порт, чтобы не конфликтовать с существующим API

// Включаем CORS для всех запросов
app.use(cors({
    origin: ['http://localhost:8000', 'http://127.0.0.1:8000', 'http://localhost:3000', 'http://127.0.0.1:3000'],
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'User-Agent', 'Accept']
}));

// Логирование запросов
app.use((req, res, next) => {
    console.log(`[CORS Proxy] ${req.method} ${req.url} - Origin: ${req.get('Origin')}`);
    next();
});

// Прокси для Reddit API
app.use('/reddit', createProxyMiddleware({
    target: 'https://www.reddit.com',
    changeOrigin: true,
    pathRewrite: {
        '^/reddit': ''
    },
    onProxyReq: (proxyReq, req, res) => {
        // Добавляем User-Agent для Reddit API
        proxyReq.setHeader('User-Agent', 'SmartScroll/1.0 (by /u/smartscroll)');
        console.log(`[Reddit Proxy] Proxying to: ${proxyReq.protocol}//${proxyReq.host}${proxyReq.path}`);
    },
    onProxyRes: (proxyRes, req, res) => {
        // Добавляем CORS заголовки
        proxyRes.headers['Access-Control-Allow-Origin'] = '*';
        proxyRes.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS';
        proxyRes.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, User-Agent, Accept';
        console.log(`[Reddit Proxy] Response: ${proxyRes.statusCode}`);
    },
    onError: (err, req, res) => {
        console.error('[Reddit Proxy] Error:', err);
        res.status(500).json({ error: 'Proxy error', message: err.message });
    }
}));

// Прокси для других API (если понадобится)
app.use('/api', createProxyMiddleware({
    target: 'http://localhost:3002',
    changeOrigin: true,
    onProxyReq: (proxyReq, req, res) => {
        console.log(`[Local API Proxy] Proxying to: ${proxyReq.protocol}//${proxyReq.host}${proxyReq.path}`);
    },
    onProxyRes: (proxyRes, req, res) => {
        proxyRes.headers['Access-Control-Allow-Origin'] = '*';
        console.log(`[Local API Proxy] Response: ${proxyRes.statusCode}`);
    }
}));

// Статический контент
app.use(express.static(path.join(__dirname)));

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        service: 'CORS Proxy Server',
        timestamp: new Date().toISOString(),
        port: PORT
    });
});

// Обработка ошибок
app.use((err, req, res, next) => {
    console.error('[CORS Proxy] Error:', err);
    res.status(500).json({ 
        error: 'Internal Server Error', 
        message: err.message 
    });
});

// Запуск сервера
app.listen(PORT, () => {
    console.log(`🚀 CORS Proxy Server запущен на порту ${PORT}`);
    console.log(`📡 Reddit API доступен по адресу: http://localhost:${PORT}/reddit/search.json`);
    console.log(`🔧 Локальный API доступен по адресу: http://localhost:${PORT}/api/`);
    console.log(`💚 Health check: http://localhost:${PORT}/health`);
    console.log(`🌐 Разрешенные origins: http://localhost:8000, http://127.0.0.1:8000`);
});

module.exports = app;

