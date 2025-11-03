# 🔧 CORS Quick Fix - Решение проблемы CORS

## Проблема
```
Access to fetch at 'http://localhost:3002/reddit/search?...' from origin 'http://localhost:8000' has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

## ✅ Решение

### 1. Быстрый запуск (рекомендуется)
```bash
cd web/
./start-all-services.sh
```

### 2. Ручной запуск
```bash
# Терминал 1: CORS Proxy Server
cd web/
node cors-proxy-server.js

# Терминал 2: Веб-сервер
cd web/
python3 -m http.server 8000
```

### 3. Проверка работы
- **Health Check**: http://localhost:3003/health
- **Тест CORS**: http://localhost:8000/test-cors-solution.html
- **Посты**: http://localhost:8000/posts.html

## 🎯 Что изменилось

### Reddit Service
- ✅ Обновлен для использования CORS Proxy (порт 3003)
- ✅ Автоматический fallback на демо-данные
- ✅ Подробное логирование

### CORS Proxy Server
- ✅ Проксирует запросы к Reddit API
- ✅ Добавляет CORS заголовки
- ✅ Поддерживает все HTTP методы
- ✅ Логирование всех запросов

## 🔍 Архитектура

```
SmartScroll (localhost:8000) 
    ↓
CORS Proxy Server (localhost:3003)
    ↓
Reddit API (reddit.com)
```

## 📊 Результат

**До**: ❌ CORS ошибки, демо-данные
**После**: ✅ Реальные данные Reddit API

## 🛠️ Устранение неполадок

### Порт 3003 занят
```bash
lsof -i :3003
kill <PID>
```

### Зависимости не установлены
```bash
npm install
```

### CORS Proxy не запускается
```bash
node cors-proxy-server.js
```

## 📝 Логи

CORS Proxy Server выводит подробные логи:
```
[CORS Proxy] GET /reddit/search.json - Origin: http://localhost:8000
[Reddit Proxy] Proxying to: https://www.reddit.com/search.json
[Reddit Proxy] Response: 200
```

---
**Статус**: ✅ Решено  
**Время**: $(date)  
**Версия**: 1.0

