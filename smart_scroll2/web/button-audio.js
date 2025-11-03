/**
 * Button Audio System
 * Система озвучки кнопок для SmartScroll
 */

class ButtonAudioSystem {
    constructor() {
        this.enabled = false;
        this.audioContext = null;
        this.festivalTTSEnabled = false;
        this.festivalServerUrl = 'http://localhost:8001';
        this.clickableSelectors = 'button, .btn, .modern-navbar__item, input[type="button"], input[type="submit"], a[href], [role="button"]';
        
        // Инициализация при загрузке
        this.init();
    }

    init() {
        // Загружаем настройки из localStorage
        this.loadSettings();
        
        // Если озвучка включена, активируем её
        if (this.enabled) {
            this.enable();
        }
        
        // Слушаем изменения настроек
        this.listenForSettingsChanges();
        
        // Автоматически проверяем настройки при загрузке страницы
        this.checkSettingsOnLoad();
    }

    loadSettings() {
        try {
            const settings = JSON.parse(localStorage.getItem('accessibilitySettings') || '{}');
            this.enabled = settings.buttonAudio || false;
        } catch (error) {
            console.log('Ошибка загрузки настроек озвучки:', error);
            this.enabled = false;
        }
    }

    listenForSettingsChanges() {
        // Слушаем изменения в localStorage
        window.addEventListener('storage', (e) => {
            if (e.key === 'accessibilitySettings') {
                this.loadSettings();
                if (this.enabled) {
                    this.enable();
                } else {
                    this.disable();
                }
            }
        });
    }

    checkSettingsOnLoad() {
        // Проверяем настройки при загрузке страницы
        setTimeout(() => {
            this.loadSettings();
            if (this.enabled) {
                console.log('🔊 Озвучка кнопок включена на этой странице');
                this.enable();
            } else {
                console.log('🔇 Озвучка кнопок отключена на этой странице');
            }
        }, 1000); // Небольшая задержка для загрузки страницы
        
        // Дополнительная проверка через 3 секунды
        setTimeout(() => {
            this.loadSettings();
            if (this.enabled && !this.isEnabled()) {
                console.log('🔄 Повторная активация озвучки кнопок');
                this.enable();
            }
        }, 3000);
    }

    enable() {
        if (this.enabled) return;
        
        this.enabled = true;
        
        // Проверяем доступность Festival TTS
        this.checkFestivalTTS();
        
        // Добавляем обработчики событий
        this.addEventListeners();
        
        console.log('🔊 Озвучка кнопок включена');
    }

    disable() {
        if (!this.enabled) return;
        
        this.enabled = false;
        
        // Удаляем обработчики событий
        this.removeEventListeners();
        
        console.log('🔇 Озвучка кнопок отключена');
    }

    async checkFestivalTTS() {
        try {
            // Проверяем доступность сервера озвучки кнопок
            const response = await fetch(`${this.festivalServerUrl}/api/speak-button`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    text: 'test'
                })
            });
            
            if (response.ok) {
                this.festivalTTSEnabled = true;
                console.log('🎤 Сервер озвучки кнопок доступен');
            } else {
                this.festivalTTSEnabled = false;
                console.log('🎤 Сервер озвучки кнопок недоступен');
            }
        } catch (error) {
            this.festivalTTSEnabled = false;
            console.log('🎤 Сервер озвучки кнопок недоступен, используется системный звук');
        }
    }

    addEventListeners() {
        // Добавляем обработчики для существующих элементов
        this.addListenersToElements(document.querySelectorAll(this.clickableSelectors));
        
        // Слушаем добавление новых элементов
        this.observeNewElements();
    }

    removeEventListeners() {
        const elements = document.querySelectorAll(this.clickableSelectors);
        elements.forEach(element => {
            element.removeEventListener('click', this.handleClick);
            element.removeEventListener('mouseenter', this.handleHover);
        });
    }

    addListenersToElements(elements) {
        elements.forEach(element => {
            element.addEventListener('click', this.handleClick.bind(this));
            element.addEventListener('mouseenter', this.handleHover.bind(this));
        });
    }

    observeNewElements() {
        // Используем MutationObserver для отслеживания новых элементов
        const observer = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
                mutation.addedNodes.forEach((node) => {
                    if (node.nodeType === Node.ELEMENT_NODE) {
                        // Проверяем сам элемент
                        if (node.matches && node.matches(this.clickableSelectors)) {
                            this.addListenersToElements([node]);
                        }
                        
                        // Проверяем дочерние элементы
                        const childElements = node.querySelectorAll ? node.querySelectorAll(this.clickableSelectors) : [];
                        if (childElements.length > 0) {
                            this.addListenersToElements(childElements);
                        }
                    }
                });
            });
        });

        observer.observe(document.body, {
            childList: true,
            subtree: true
        });
    }

    handleClick(event) {
        if (!this.enabled) return;
        
        const element = event.target;
        const text = this.getElementText(element);
        
        // Воспроизводим системный звук
        this.playSystemSound();
        
        // Если доступен Festival TTS, озвучиваем текст
        if (this.festivalTTSEnabled && text.length < 50) {
            this.speakText(text);
        }
    }

    handleHover(event) {
        if (!this.enabled) return;
        
        // Тихый звук при наведении
        this.playSystemSound(0.1);
    }

    getElementText(element) {
        // Получаем текст элемента с учетом различных случаев
        let text = element.textContent || element.value || element.getAttribute('aria-label');
        
        // Если текст пустой, пробуем получить из title
        if (!text) {
            text = element.getAttribute('title');
        }
        
        // Если всё ещё пустой, пробуем получить из data-атрибутов
        if (!text) {
            text = element.getAttribute('data-text') || element.getAttribute('data-label');
        }
        
        // Если ничего не найдено, используем общее описание
        if (!text) {
            text = 'Кнопка';
        }
        
        // Очищаем текст от лишних пробелов и переносов
        return text.trim().replace(/\s+/g, ' ');
    }

    playSystemSound(volume = 0.3) {
        try {
            // Создаем звуковой контекст если его нет
            if (!this.audioContext) {
                this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
            }
            
            // Если контекст приостановлен, возобновляем
            if (this.audioContext.state === 'suspended') {
                this.audioContext.resume();
            }
            
            const oscillator = this.audioContext.createOscillator();
            const gainNode = this.audioContext.createGain();
            
            oscillator.connect(gainNode);
            gainNode.connect(this.audioContext.destination);
            
            // Создаем приятный звук
            oscillator.frequency.setValueAtTime(800, this.audioContext.currentTime);
            oscillator.frequency.exponentialRampToValueAtTime(400, this.audioContext.currentTime + 0.1);
            
            gainNode.gain.setValueAtTime(0, this.audioContext.currentTime);
            gainNode.gain.linearRampToValueAtTime(volume, this.audioContext.currentTime + 0.01);
            gainNode.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + 0.1);
            
            oscillator.start(this.audioContext.currentTime);
            oscillator.stop(this.audioContext.currentTime + 0.1);
            
        } catch (error) {
            console.log('Ошибка воспроизведения звука:', error);
        }
    }

        async speakText(text) {
            if (!this.festivalTTSEnabled) return;
            
            try {
                console.log(`🔊 Пытаемся озвучить: "${text}"`);
                
                // Используем speak.py скрипт из папки #2/festival/
                const response = await fetch(`${this.festivalServerUrl}/api/speak-button`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        text: text
                    })
                });
                
                if (!response.ok) {
                    console.log(`❌ HTTP ошибка: ${response.status}`);
                    return;
                }
                
                const data = await response.json();
                
                if (data.success) {
                    console.log('✅ Озвучено через Festival:', text);
                } else {
                    console.log('❌ Ошибка озвучки:', data.error);
                }
            } catch (error) {
                console.log('❌ Ошибка озвучки через Festival:', error);
            }
        }

    // Публичные методы для управления
    toggle() {
        if (this.enabled) {
            this.disable();
        } else {
            this.enable();
        }
    }

    isEnabled() {
        return this.enabled;
    }

    // Метод для обновления настроек
    updateSettings() {
        this.loadSettings();
        if (this.enabled) {
            this.enable();
        } else {
            this.disable();
        }
    }
}

// Создаем глобальный экземпляр
window.ButtonAudio = new ButtonAudioSystem();

// Экспортируем для использования в модулях
if (typeof module !== 'undefined' && module.exports) {
    module.exports = ButtonAudioSystem;
}
