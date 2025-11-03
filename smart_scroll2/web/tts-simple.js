/**
 * Простой TTS сервис для Smart Scroll
 * Использует встроенный Speech API браузера
 */

class SimpleTTSService {
    constructor() {
        this.isEnabled = false;
        this.isInitialized = false;
        this.currentUtterance = null;
        this.lastSpeakTime = 0;
        this.speakDelay = 500; // Минимальная задержка между озвучками (мс)
        
        console.log('🔄 Simple TTS Service создается...');
        this.init();
    }

    /**
     * Инициализация
     */
    init() {
        try {
            // Загружаем настройки
            this.loadSettings();
            
            // Проверяем поддержку Speech API
            if (this.isSpeechSupported()) {
                this.isInitialized = true;
                console.log('✅ Simple TTS Service инициализирован');
                
                // Если озвучка включена, активируем
                if (this.isEnabled) {
                    this.enableTTS();
                }
            } else {
                console.warn('⚠️ Speech API не поддерживается');
                this.isInitialized = false;
            }
        } catch (error) {
            console.error('❌ Ошибка инициализации TTS:', error);
            this.isInitialized = false;
        }
    }

    /**
     * Проверка поддержки Speech API
     */
    isSpeechSupported() {
        return 'speechSynthesis' in window && 'SpeechSynthesisUtterance' in window;
    }

    /**
     * Загрузка настроек
     */
    loadSettings() {
        try {
            const settings = localStorage.getItem('ttsSettings');
            if (settings) {
                const parsed = JSON.parse(settings);
                this.isEnabled = parsed.enabled || false;
            }
        } catch (error) {
            console.warn('Ошибка загрузки настроек TTS:', error);
        }
    }

    /**
     * Сохранение настроек
     */
    saveSettings() {
        try {
            const settings = {
                enabled: this.isEnabled,
                timestamp: Date.now()
            };
            localStorage.setItem('ttsSettings', JSON.stringify(settings));
        } catch (error) {
            console.warn('Ошибка сохранения настроек TTS:', error);
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
        
        // Добавляем обработчики
        this.addEventListeners();
        
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
        
        // Останавливаем воспроизведение
        this.stopCurrentSpeech();
        
        // Удаляем обработчики
        this.removeEventListeners();
        
        console.log('🔇 Озвучка отключена');
        this.showNotification('Озвучка отключена', 'info');
        
        return true;
    }

    /**
     * Переключение состояния
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
     * Добавление обработчиков событий
     */
    addEventListeners() {
        // Обработчик для кнопок
        document.addEventListener('click', this.handleButtonClick.bind(this));
        
        // Обработчик для навигации
        document.addEventListener('click', this.handleNavigationClick.bind(this));
        
        // Обработчик для текста
        document.addEventListener('click', this.handleTextClick.bind(this));
    }

    /**
     * Удаление обработчиков событий
     */
    removeEventListeners() {
        // Обработчики будут удалены автоматически при перезагрузке
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
        const clone = button.cloneNode(true);
        
        // Удаляем SVG иконки
        clone.querySelectorAll('svg').forEach(svg => svg.remove());
        
        // Удаляем эмодзи
        const text = clone.textContent.replace(/[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]/gu, '').trim();
        
        return text || null;
    }

    /**
     * Синтез речи
     */
    speakText(text) {
        if (!this.isEnabled || !text || !text.trim()) {
            return;
        }

        // Проверяем задержку между озвучками
        const now = Date.now();
        if (now - this.lastSpeakTime < this.speakDelay) {
            console.log('⏳ Слишком частая озвучка, пропускаем');
            return;
        }

        try {
            // Останавливаем текущее воспроизведение с задержкой
            this.stopCurrentSpeech();
            
            // Небольшая задержка для корректной остановки
            setTimeout(() => {
                // Создаем объект для синтеза речи
                const utterance = new SpeechSynthesisUtterance(text.trim());
                
                // Настройки
                utterance.lang = 'ru-RU';
                utterance.rate = 1.0;
                utterance.pitch = 1.0;
                utterance.volume = 0.8;

                // Обработчики событий
                utterance.onstart = () => {
                    console.log(`🔊 Озвучка: "${text}"`);
                };

                utterance.onend = () => {
                    console.log('✅ Озвучка завершена');
                    this.currentUtterance = null;
                };

                utterance.onerror = (error) => {
                    // Игнорируем ошибку "interrupted" - это нормально
                    if (error.error !== 'interrupted') {
                        console.error('❌ Ошибка озвучки:', error);
                        this.showNotification('Ошибка озвучки', 'error');
                    }
                    this.currentUtterance = null;
                };

                // Запускаем синтез
                window.speechSynthesis.speak(utterance);
                this.currentUtterance = utterance;
                this.lastSpeakTime = Date.now();
            }, 100); // Задержка 100мс для корректной остановки
            
        } catch (error) {
            console.error('Ошибка синтеза речи:', error);
            this.showNotification('Ошибка озвучки', 'error');
        }
    }

    /**
     * Остановка текущего воспроизведения
     */
    stopCurrentSpeech() {
        if (window.speechSynthesis) {
            // Останавливаем все воспроизведение
            window.speechSynthesis.cancel();
            
            // Дополнительная проверка для полной остановки
            if (window.speechSynthesis.speaking) {
                window.speechSynthesis.cancel();
            }
        }
        this.currentUtterance = null;
    }

    /**
     * Показать уведомление
     */
    showNotification(message, type = 'info') {
        // Создаем уведомление
        const notification = document.createElement('div');
        notification.className = `tts-notification tts-notification--${type}`;
        notification.textContent = message;
        
        // Стили
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
        
        // Цвета
        const colors = {
            success: '#30CAA1',
            error: '#FF6B6B',
            info: '#4A90E2',
            warning: '#F5A623'
        };
        
        notification.style.backgroundColor = colors[type] || colors.info;
        
        // Добавляем в DOM
        document.body.appendChild(notification);
        
        // Анимация
        setTimeout(() => {
            notification.style.opacity = '1';
            notification.style.transform = 'translateX(0)';
        }, 10);
        
        // Автоудаление
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
     * Получение статуса
     */
    getStatus() {
        return {
            enabled: this.isEnabled,
            initialized: this.isInitialized,
            serverAvailable: this.isInitialized,
            builtInTTSAvailable: this.isSpeechSupported()
        };
    }

    /**
     * Очистка кэша
     */
    clearCache() {
        // Для простого TTS кэш не используется
        console.log('🗑️ Кэш TTS очищен');
    }
}

// Создаем глобальный экземпляр сразу
console.log('🔄 Создание Simple TTS Service...');
window.TTSService = new SimpleTTSService();

// Экспортируем
if (typeof module !== 'undefined' && module.exports) {
    module.exports = SimpleTTSService;
}
