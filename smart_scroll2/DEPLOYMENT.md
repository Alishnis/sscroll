# 🚀 Развертывание SmartScroll

## 🌐 Веб-развертывание

### 1. GitHub Pages

```bash
# Клонируйте репозиторий
git clone https://github.com/Alishnis/smart_scrolling.git
cd smart_scrolling

# Перейдите в веб-папку
cd web

# Запустите локально для тестирования
python3 -m http.server 3000
```

### 2. Netlify

1. Подключите GitHub репозиторий к Netlify
2. Установите:
   - **Build command**: `echo "No build needed"`
   - **Publish directory**: `web`
3. Добавьте переменные окружения в Netlify:
   - `REDDIT_CLIENT_ID`
   - `REDDIT_CLIENT_SECRET`
   - `YOUTUBE_API_KEY`

### 3. Vercel

```bash
# Установите Vercel CLI
npm i -g vercel

# Разверните
cd web
vercel
```

## 📱 Мобильное развертывание

### Android

```bash
# Соберите APK
flutter build apk --release

# Установите на устройство
flutter install
```

### iOS

```bash
# Соберите для iOS
flutter build ios --release

# Откройте в Xcode
open ios/Runner.xcworkspace
```

## 🔧 Настройка API ключей

### Для продакшена

1. Создайте `.env` файл:
```env
REDDIT_CLIENT_ID=your_reddit_client_id
REDDIT_CLIENT_SECRET=your_reddit_secret
YOUTUBE_API_KEY=your_youtube_key
OPENAI_API_KEY=your_openai_key
```

2. Обновите `lib/config/secrets.dart`:
```dart
static const String redditClientId = 'your_reddit_client_id';
static const String redditClientSecret = 'your_reddit_secret';
static const String youtubeApiKey = 'your_youtube_key';
```

## 🐳 Docker развертывание

### Dockerfile

```dockerfile
FROM node:18-alpine

WORKDIR /app
COPY web/ .
RUN npm install

EXPOSE 3000
CMD ["node", "cors-proxy.js"]
```

### docker-compose.yml

```yaml
version: '3.8'
services:
  web:
    build: .
    ports:
      - "3000:3000"
    environment:
      - REDDIT_CLIENT_ID=${REDDIT_CLIENT_ID}
      - REDDIT_CLIENT_SECRET=${REDDIT_CLIENT_SECRET}
```

## 🔒 Безопасность

### Важные моменты:

1. **НЕ коммитьте API ключи** в репозиторий
2. Используйте переменные окружения
3. Ограничьте доступ к API ключам
4. Регулярно обновляйте ключи

### .gitignore

```gitignore
.env
*.key
secrets.dart
```

## 📊 Мониторинг

### Логи

```bash
# Просмотр логов веб-сервера
tail -f /var/log/nginx/access.log

# Логи CORS прокси
node cors-proxy.js 2>&1 | tee cors-proxy.log
```

### Метрики

- Количество запросов к API
- Время отклика
- Ошибки CORS
- Использование памяти

## 🚨 Устранение неполадок

### CORS ошибки в продакшене

1. Настройте CORS на сервере
2. Используйте прокси-сервер
3. Обновите заголовки

### API лимиты

1. Мониторьте использование API
2. Реализуйте кэширование
3. Добавьте fallback контент

## 📈 Масштабирование

### Горизонтальное масштабирование

```yaml
# docker-compose.yml
services:
  web:
    scale: 3
  proxy:
    scale: 2
```

### Кэширование

```javascript
// Добавьте Redis для кэширования
const redis = require('redis');
const client = redis.createClient();
```

---

**Удачного развертывания! 🚀**

