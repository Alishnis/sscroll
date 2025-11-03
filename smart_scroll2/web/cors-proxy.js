const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const cors = require('cors');

const app = express();
const PORT = 3002;

// Включаем CORS для всех запросов
app.use(cors({
    origin: ['http://localhost:3000', 'http://127.0.0.1:3000'],
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));

// Логирование запросов
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
    next();
});

// Прокси для Reddit API (публичный API без аутентификации)
app.get('/reddit/search', async (req, res) => {
    const { q, sort = 'relevance', limit = 10, type = 'link' } = req.query;
    
    if (!q) {
        return res.status(400).json({ error: 'Query parameter "q" is required' });
    }
    
    try {
        // Используем публичный Reddit API
        const redditUrl = `https://www.reddit.com/search.json?q=${encodeURIComponent(q)}&sort=${sort}&limit=${limit}&type=${type}&include_over_18=on&restrict_sr=off&t=all`;
        
        console.log('Проксируем запрос к публичному Reddit API:', redditUrl);
        
        const response = await fetch(redditUrl, {
            headers: {
                'User-Agent': 'SmartScroll/1.0 (by /u/smartscroll)',
                'Accept': 'application/json'
            }
        });
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }
        
        const data = await response.json();
        res.json(data);
        
    } catch (error) {
        console.error('Ошибка при запросе к Reddit:', error);
        res.status(500).json({ 
            error: 'Failed to fetch from Reddit', 
            message: error.message 
        });
    }
});

// Прокси для Reddit API (OAuth)
app.use('/reddit', createProxyMiddleware({
    target: 'https://oauth.reddit.com',
    changeOrigin: true,
    pathRewrite: {
        '^/reddit': ''
    },
    onProxyReq: (proxyReq, req, res) => {
        console.log('Проксируем запрос к Reddit OAuth:', proxyReq.path);
    },
    onError: (err, req, res) => {
        console.error('Ошибка прокси:', err);
        res.status(500).json({ error: 'Proxy error' });
    }
}));

// Прокси для общих запросов
app.get('/', (req, res) => {
    const targetUrl = req.query.url;
    
    if (!targetUrl) {
        return res.status(400).json({ error: 'URL parameter is required' });
    }

    console.log('Проксируем запрос к:', targetUrl);
    
    // Прокси с правильными заголовками для Reddit API
    fetch(targetUrl, {
        method: 'GET',
        headers: {
            'User-Agent': 'SmartScroll/1.0 (by /u/smartscroll)',
            'Accept': 'application/json',
            'Accept-Language': 'en-US,en;q=0.9',
            'Cache-Control': 'no-cache'
        }
    })
    .then(response => {
        console.log('Статус ответа:', response.status);
        console.log('Content-Type:', response.headers.get('content-type'));
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }
        
        const contentType = response.headers.get('content-type');
        if (contentType && contentType.includes('application/json')) {
            return response.json();
        } else {
            // Если не JSON, возвращаем как текст
            return response.text().then(text => {
                console.log('Получен не-JSON ответ:', text.substring(0, 200) + '...');
                throw new Error('Reddit API вернул HTML вместо JSON. Возможно, требуется аутентификация.');
            });
        }
    })
    .then(data => {
        res.set('Content-Type', 'application/json');
        res.json(data);
    })
    .catch(error => {
        console.error('Ошибка при проксировании:', error);
        res.status(500).json({ 
            error: 'Failed to fetch', 
            message: error.message,
            details: 'Reddit API может требовать аутентификации'
        });
    });
});

// Обработка POST запросов
app.post('/', (req, res) => {
    const targetUrl = req.query.url;
    
    if (!targetUrl) {
        return res.status(400).json({ error: 'URL parameter is required' });
    }

    console.log('Проксируем POST запрос к:', targetUrl);
    
    fetch(targetUrl, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'User-Agent': 'SmartScroll/1.0'
        },
        body: JSON.stringify(req.body)
    })
    .then(response => {
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }
        return response.text();
    })
    .then(data => {
        res.set('Content-Type', 'application/json');
        res.send(data);
    })
    .catch(error => {
        console.error('Ошибка при проксировании POST:', error);
        res.status(500).json({ 
            error: 'Failed to fetch', 
            message: error.message 
        });
    });
});

// Запуск сервера
app.listen(PORT, () => {
    console.log(`🚀 CORS Proxy Server запущен на порту ${PORT}`);
    console.log(`🌐 URL: http://localhost:${PORT}`);
    console.log(`📋 Доступные эндпоинты:`);
    console.log(`   - GET /?url=<encoded_url> - прокси для GET запросов`);
    console.log(`   - POST /?url=<encoded_url> - прокси для POST запросов`);
    console.log(`   - /reddit/* - прокси для Reddit API`);
});

module.exports = app;