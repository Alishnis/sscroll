/**
 * TTS (Text-to-Speech) Service для Smart Scroll
 * Интеграция с Festival TTS сервером
 */

class TTSService {
    constructor() {
        this.isEnabled = false;
        this.serverUrl = 'http://localhost:5001';
        this.audioCache = new Map();
        this.currentAudio = null;
        this.isInitialized = false;
        
        // Инициализация при загрузке
        this.init();
    }

    /**
     * Инициализация TTS сервиса
     */
    async init() {
        try {
            // Загружаем настройки из localStorage
            this.loadSettings();
            
            // Проверяем доступность TTS сервера
            await this.checkServerStatus();
            
            this.isInitialized = true;
            console.log('✅ TTS Service инициализирован');
            
            // Если озвучка включена, активируем её
            if (this.isEnabled) {
                this.enableTTS();
            }
            
        } catch (error) {
            console.warn('⚠️ TTS Service: Сервер недоступен, озвучка отключена', error);
            this.isInitialized = false;
        }
    }

    /**
     * Загрузка настроек из localStorage
     */
    loadSettings() {
        const settings = localStorage.getItem('ttsSettings');
        if (settings) {
            const parsed = JSON.parse(settings);
            this.isEnabled = parsed.enabled || false;
        }
    }

    /**
     * Сохранение настроек в localStorage
     */
    saveSettings() {
        const settings = {
            enabled: this.isEnabled,
            timestamp: Date.now()
        };
        localStorage.setItem('ttsSettings', JSON.stringify(settings));
    }

    /**
     * Проверка статуса TTS сервера
     */
    async checkServerStatus() {
        try {
            const response = await fetch(`${this.serverUrl}/api/status`);
            const data = await response.json();
            return data.server_running;
        } catch (error) {
            console.warn('TTS сервер недоступен, используем встроенный TTS:', error);
            // Возвращаем true для встроенного TTS
            return true;
        }
    }

    /**
     * Включение озвучки
     */
    enableTTS() {
        if (!this.isInitialized) {
            console.warn('TTS Service не инициализирован');
            return false;
        }

        this.isEnabled = true;
        this.saveSettings();
        
        // Добавляем обработчики для кнопок
        this.addButtonListeners();
        
        console.log('🔊 Озвучка включена');
        this.showNotification('Озвучка включена', 'success');
        
        return true;
    }

    /**
     * Отключение озвучки
     */
    disableTTS() {
        this.isEnabled = false;
        this.saveSettings();
        
        // Останавливаем текущее воспроизведение
        this.stopCurrentAudio();
        
        // Удаляем обработчики
        this.removeButtonListeners();
        
        console.log('🔇 Озвучка отключена');
        this.showNotification('Озвучка отключена', 'info');
        
        return true;
    }

    /**
     * Переключение состояния озвучки
     */
    toggleTTS() {
        if (this.isEnabled) {
            this.disableTTS();
        } else {
            this.enableTTS();
        }
        return this.isEnabled;
    }

    /**
     * Добавление обработчиков для кнопок
     */
    addButtonListeners() {
        // Обработчик для всех кнопок
        document.addEventListener('click', this.handleButtonClick.bind(this));
        
        // Обработчик для навигации
        document.addEventListener('click', this.handleNavigationClick.bind(this));
        
        // Обработчик для текстовых элементов
        document.addEventListener('click', this.handleTextClick.bind(this));
    }

    /**
     * Удаление обработчиков
     */
    removeButtonListeners() {
        // Обработчики будут удалены автоматически при перезагрузке страницы
        // или можно добавить более сложную логику для их удаления
    }

    /**
     * Обработка клика по кнопкам
     */
    handleButtonClick(event) {
        if (!this.isEnabled) return;

        const target = event.target;
        const button = target.closest('button, .btn, .auth-button, .navbar__item, .right-sidebar__item');
        
        if (button) {
            const text = this.extractButtonText(button);
            if (text) {
                this.speakText(text);
            }
        }
    }

    /**
     * Обработка клика по навигации
     */
    handleNavigationClick(event) {
        if (!this.isEnabled) return;

        const target = event.target;
        const navItem = target.closest('.navbar__item, .right-sidebar__item');
        
        if (navItem) {
            const text = navItem.querySelector('.navbar__text, .right-sidebar__text')?.textContent;
            if (text) {
                this.speakText(`Переход к ${text}`);
            }
        }
    }

    /**
     * Обработка клика по тексту
     */
    handleTextClick(event) {
        if (!this.isEnabled) return;

        const target = event.target;
        
        // Озвучиваем заголовки
        if (target.matches('h1, h2, h3, h4, h5, h6')) {
            this.speakText(target.textContent);
        }
        
        // Озвучиваем важные элементы
        if (target.matches('.content-card__title, .section-title, .achievement-name')) {
            this.speakText(target.textContent);
        }
    }

    /**
     * Извлечение текста из кнопки
     */
    extractButtonText(button) {
        // Убираем иконки и оставляем только текст
        const clone = button.cloneNode(true);
        
        // Удаляем SVG иконки
        clone.querySelectorAll('svg').forEach(svg => svg.remove());
        
        // Удаляем эмодзи
        const text = clone.textContent.replace(/[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]/gu, '').trim();
        
        return text || null;
    }

    /**
     * Синтез речи из текста
     */
    async speakText(text) {
        if (!this.isEnabled || !text || !text.trim()) {
            return;
        }

        try {
            // Останавливаем текущее воспроизведение
            this.stopCurrentAudio();
            
            // Сначала пробуем встроенный TTS браузера
            if (this.useBuiltInTTS()) {
                this.speakWithBuiltInTTS(text);
                return;
            }
            
            // Проверяем кэш
            const cacheKey = text.trim().toLowerCase();
            if (this.audioCache.has(cacheKey)) {
                this.playAudio(this.audioCache.get(cacheKey));
                return;
            }

            // Генерируем аудио через сервер
            const response = await fetch(`${this.serverUrl}/api/generate-audio`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ text: text.trim() })
            });

            const data = await response.json();
            
            if (data.success && data.audio_url) {
                // Кэшируем URL
                this.audioCache.set(cacheKey, data.audio_url);
                
                // Воспроизводим аудио
                this.playAudio(data.audio_url);
                
                console.log(`🔊 Озвучено: "${text}"`);
            } else {
                console.warn('Ошибка генерации аудио, пробуем встроенный TTS:', data.error);
                this.speakWithBuiltInTTS(text);
            }
            
        } catch (error) {
            console.error('Ошибка TTS, пробуем встроенный TTS:', error);
            this.speakWithBuiltInTTS(text);
        }
    }

    /**
     * Воспроизведение аудио
     */
    playAudio(audioUrl) {
        try {
            // Останавливаем текущее воспроизведение
            this.stopCurrentAudio();
            
            // Создаем новый аудио элемент
            const audio = new Audio(audioUrl);
            
            // Обработчики событий
            audio.onended = () => {
                this.currentAudio = null;
            };
            
            audio.onerror = (error) => {
                console.error('Ошибка воспроизведения:', error);
                this.currentAudio = null;
            };
            
            // Воспроизводим
            audio.play();
            this.currentAudio = audio;
            
        } catch (error) {
            console.error('Ошибка воспроизведения аудио:', error);
        }
    }

    /**
     * Остановка текущего воспроизведения
     */
    stopCurrentAudio() {
        if (this.currentAudio) {
            this.currentAudio.pause();
            this.currentAudio.currentTime = 0;
            this.currentAudio = null;
        }
        
        // Останавливаем встроенный TTS
        if (window.speechSynthesis) {
            window.speechSynthesis.cancel();
        }
    }

    /**
     * Проверка доступности встроенного TTS
     */
    useBuiltInTTS() {
        return window.speechSynthesis && window.SpeechSynthesisUtterance;
    }

    /**
     * Синтез речи через встроенный TTS браузера
     */
    speakWithBuiltInTTS(text) {
        if (!this.useBuiltInTTS()) {
            console.warn('Встроенный TTS недоступен');
            return;
        }

        try {
            // Останавливаем предыдущее воспроизведение
            window.speechSynthesis.cancel();

            // Создаем объект для синтеза речи
            const utterance = new SpeechSynthesisUtterance(text);
            
            // Настройки голоса
            utterance.lang = 'ru-RU';
            utterance.rate = 1.0;
            utterance.pitch = 1.0;
            utterance.volume = 0.8;

            // Обработчики событий
            utterance.onstart = () => {
                console.log(`🔊 Встроенный TTS: "${text}"`);
            };

            utterance.onend = () => {
                console.log('✅ Встроенный TTS завершен');
            };

            utterance.onerror = (error) => {
                console.error('❌ Ошибка встроенного TTS:', error);
                this.showNotification('Ошибка озвучки', 'error');
            };

            // Запускаем синтез
            window.speechSynthesis.speak(utterance);
            
        } catch (error) {
            console.error('Ошибка встроенного TTS:', error);
            this.showNotification('Ошибка озвучки', 'error');
        }
    }

    /**
     * Показать уведомление
     */
    showNotification(message, type = 'info') {
        // Создаем уведомление
        const notification = document.createElement('div');
        notification.className = `tts-notification tts-notification--${type}`;
        notification.textContent = message;
        
        // Стили для уведомления
        Object.assign(notification.style, {
            position: 'fixed',
            top: '20px',
            right: '20px',
            padding: '12px 20px',
            borderRadius: '8px',
            color: 'white',
            fontSize: '14px',
            fontWeight: '500',
            zIndex: '10000',
            opacity: '0',
            transform: 'translateX(100%)',
            transition: 'all 0.3s ease',
            maxWidth: '300px',
            wordWrap: 'break-word'
        });
        
        // Цвета в зависимости от типа
        const colors = {
            success: '#30CAA1',
            error: '#FF6B6B',
            info: '#4A90E2',
            warning: '#F5A623'
        };
        
        notification.style.backgroundColor = colors[type] || colors.info;
        
        // Добавляем в DOM
        document.body.appendChild(notification);
        
        // Анимация появления
        setTimeout(() => {
            notification.style.opacity = '1';
            notification.style.transform = 'translateX(0)';
        }, 10);
        
        // Автоматическое удаление
        setTimeout(() => {
            notification.style.opacity = '0';
            notification.style.transform = 'translateX(100%)';
            setTimeout(() => {
                if (notification.parentNode) {
                    notification.parentNode.removeChild(notification);
                }
            }, 300);
        }, 3000);
    }

    /**
     * Получение статуса озвучки
     */
    getStatus() {
        return {
            enabled: this.isEnabled,
            initialized: this.isInitialized,
            serverAvailable: this.isInitialized,
            builtInTTSAvailable: this.useBuiltInTTS()
        };
    }

    /**
     * Очистка кэша
     */
    clearCache() {
        this.audioCache.clear();
        console.log('🗑️ TTS кэш очищен');
    }
}

// Инициализация TTS сервиса после загрузки DOM
function initTTSService() {
    if (!window.TTSService) {
        try {
            window.TTSService = new TTSService();
            console.log('✅ TTS Service создан');
            return true;
        } catch (error) {
            console.error('❌ Ошибка создания TTS Service:', error);
            return false;
        }
    }
    return true;
}

// Инициализируем при загрузке DOM
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        console.log('🔄 DOM загружен, инициализируем TTS Service...');
        initTTSService();
    });
} else {
    console.log('🔄 DOM уже загружен, инициализируем TTS Service...');
    initTTSService();
}

// Дополнительная инициализация через небольшую задержку
setTimeout(() => {
    if (!window.TTSService) {
        console.log('🔄 Повторная инициализация TTS Service...');
        initTTSService();
    }
}, 1000);

// Экспортируем для использования в других модулях
if (typeof module !== 'undefined' && module.exports) {
    module.exports = TTSService;
}
