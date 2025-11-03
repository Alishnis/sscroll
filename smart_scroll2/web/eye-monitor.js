/**
 * Универсальный мониторинг глаз для всех страниц сайта
 * Использует MediaPipe Face Landmarker для точного измерения расстояния
 */

class EyeMonitor {
    constructor() {
        this.isActive = false;
        this.video = null;
        this.canvas = null;
        this.ctx = null;
        this.landmarker = null;
        this.intervalId = null;
        this.notification = null;
        this.raf = null;
        this.lastTs = 0;
        
        // Настройки по умолчанию с калибровочными параметрами
        this.settings = {
            checkInterval: 60000, // 60 секунд (нормальный режим)
            warningDistance: 50,   // см
            dangerDistance: 35,   // см
            soundEnabled: true,
            autoStart: true,
            minCm: 35,  // Минимальное безопасное расстояние
            maxCm: 80,  // Максимальное расстояние
            // Калибровочные параметры яркости
            calibration: {
                minBrightness: 150,   // Минимальная яркость (близко)
                maxBrightness: 163,   // Максимальная яркость (далеко)
                currentBrightness: 159, // Текущая яркость
                isCalibrated: true    // Система настроена
            }
        };
        
        // Статистика
        this.stats = {
            measurements: 0,
            warnings: 0,
            averageDistance: 0,
            sessionStart: null,
            lastDistance: 0
        };
        
        // Счетчики для адаптивной системы
        this.okCounter = 0;
        this.currentInterval = 60000;
        
        this.init();
    }
    
    async init() {
        console.log('👁️ Инициализация мониторинга глаз с MediaPipe...');
        
        // Загружаем настройки из localStorage
        this.loadSettings();
        
        // Создаем уведомление
        this.createNotification();
        
        // Инициализируем MediaPipe с fallback
        try {
            await this.initMediaPipe();
        } catch (error) {
            console.error('Ошибка инициализации MediaPipe:', error);
            console.log('Пробуем fallback на Face Detection API...');
            
            try {
                await this.initFaceDetectionAPI();
            } catch (fallbackError) {
                console.error('Face Detection API тоже не работает:', fallbackError);
                this.showNotification('Мониторинг глаз не поддерживается в этом браузере', 'error');
                return;
            }
        }
        
        // Автозапуск если включен
        if (this.settings.autoStart) {
            await this.start();
        }
    }
    
    async initMediaPipe() {
        // Ждем загрузки MediaPipe скриптов
        await this.waitForMediaPipe();
        
        // Проверяем поддержку MediaPipe
        if (typeof window !== 'undefined' && window.vision) {
            const { FaceLandmarker } = window.vision;
            
            this.landmarker = await FaceLandmarker.createFromOptions(window.vision, {
                baseOptions: {
                    modelAssetPath: 'https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task',
                },
                runningMode: 'VIDEO',
                numFaces: 1,
            });
            
            console.log('✅ MediaPipe Face Landmarker инициализирован');
        } else {
            throw new Error('MediaPipe не доступен');
        }
    }
    
    async waitForMediaPipe() {
        return new Promise((resolve, reject) => {
            let attempts = 0;
            const maxAttempts = 50; // 5 секунд максимум
            
            const checkMediaPipe = () => {
                attempts++;
                
                if (typeof window !== 'undefined' && window.vision) {
                    console.log('✅ MediaPipe загружен');
                    resolve();
                } else if (attempts >= maxAttempts) {
                    reject(new Error('MediaPipe не загрузился за отведенное время'));
                } else {
                    setTimeout(checkMediaPipe, 100);
                }
            };
            
            checkMediaPipe();
        });
    }
    
    async initFaceDetectionAPI() {
        // Fallback на Face Detection API
        if ('FaceDetector' in window) {
            this.faceDetector = new FaceDetector({
                maxDetectedFaces: 1,
                fastMode: true
            });
            console.log('✅ Face Detection API инициализирован как fallback');
        } else {
            throw new Error('Face Detection API не поддерживается');
        }
    }
    
    createNotification() {
        // Создаем контейнер для уведомлений
        this.notification = document.createElement('div');
        this.notification.id = 'eye-monitor-notification';
        this.notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            background: #ff4757;
            color: white;
            padding: 15px 20px;
            border-radius: 10px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.3);
            z-index: 10000;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            font-size: 14px;
            font-weight: bold;
            max-width: 300px;
            display: none;
            transition: all 0.3s ease;
            border-left: 4px solid #ff3742;
        `;
        
        document.body.appendChild(this.notification);
    }
    
    async start() {
        if (this.isActive) return;
        
        console.log('👁️ Запуск мониторинга глаз...');
        
        try {
            // Получаем доступ к камере
            this.video = document.createElement('video');
            this.video.style.display = 'none';
            document.body.appendChild(this.video);
            
            const stream = await navigator.mediaDevices.getUserMedia({
                video: { 
                    width: 640, 
                    height: 480,
                    facingMode: 'user'
                }
            });
            
            this.video.srcObject = stream;
            this.video.play();
            
            // Создаем canvas для обработки
            this.canvas = document.createElement('canvas');
            this.ctx = this.canvas.getContext('2d');
            
            this.isActive = true;
            this.stats.sessionStart = new Date();
            
            // Запускаем мониторинг
            this.startMonitoring();
            
            console.log('✅ Мониторинг глаз запущен');
            
        } catch (error) {
            console.error('❌ Ошибка запуска мониторинга:', error);
            this.showNotification('Ошибка доступа к камере', 'error');
        }
    }
    
    stop() {
        if (!this.isActive) return;
        
        console.log('👁️ Остановка мониторинга глаз...');
        
        this.isActive = false;
        
        // Очищаем таймеры
        if (this.intervalId) {
            clearTimeout(this.intervalId);
            this.intervalId = null;
        }
        
        if (this.raf) {
            cancelAnimationFrame(this.raf);
            this.raf = null;
        }
        
        // Останавливаем камеру
        if (this.video && this.video.srcObject) {
            this.video.srcObject.getTracks().forEach(track => track.stop());
            this.video.srcObject = null;
        }
        
        // Удаляем элементы
        if (this.video && this.video.parentNode) {
            this.video.parentNode.removeChild(this.video);
        }
        
        if (this.canvas && this.canvas.parentNode) {
            this.canvas.parentNode.removeChild(this.canvas);
        }
        
        // Очищаем MediaPipe ресурсы
        try {
            if (this.landmarker) {
                this.landmarker.close();
                this.landmarker = null;
            }
        } catch (error) {
            console.error('Ошибка при закрытии MediaPipe:', error);
        }
        
        this.hideNotification();
        console.log('✅ Мониторинг глаз остановлен');
    }
    
    startMonitoring() {
        // Адаптивная система мониторинга
        this.scheduleNextCheck();
    }
    
    scheduleNextCheck() {
        if (!this.isActive) return;
        
        this.intervalId = setTimeout(async () => {
            if (!this.isActive) return;
            
            try {
                const distance = await this.sampleForOneSecond();
                if (distance > 0) {
                    this.processDistance(distance);
                }
                this.scheduleNextCheck();
            } catch (error) {
                console.error('Ошибка измерения расстояния:', error);
                this.scheduleNextCheck();
            }
        }, this.currentInterval);
    }
    
    async sampleForOneSecond() {
        if (!this.landmarker || !this.video || this.video.readyState !== 4) {
            return 0;
        }
        
        const start = performance.now();
        let minDist = Number.POSITIVE_INFINITY;
        let validSamples = 0;
        
        // Собираем данные в течение 1 секунды
        while (performance.now() - start < 1000) {
            try {
                const distance = await this.measureDistance();
                if (distance > 0) {
                    minDist = Math.min(minDist, distance);
                    validSamples++;
                }
            } catch (error) {
                console.error('Ошибка измерения:', error);
            }
            
            // Небольшая задержка для оптимизации
            await new Promise(resolve => setTimeout(resolve, 50));
        }
        
        if (validSamples > 0) {
            this.stats.measurements++;
            this.stats.lastDistance = minDist;
            this.updateAverageDistance(minDist);
            return minDist;
        }
        
        return 0;
    }
    
    async measureDistance() {
        if (!this.video || this.video.readyState !== 4) {
            return 0;
        }
        
        try {
            // Устанавливаем размеры canvas
            this.canvas.width = this.video.videoWidth;
            this.canvas.height = this.video.videoHeight;
            
            // Рисуем текущий кадр
            this.ctx.drawImage(this.video, 0, 0);
            
            // Пробуем MediaPipe сначала
            if (this.landmarker) {
                return await this.measureDistanceMediaPipe();
            }
            
            // Fallback на Face Detection API
            if (this.faceDetector) {
                return await this.measureDistanceFaceDetection();
            }
            
            return 0;
            
        } catch (error) {
            console.error('Ошибка детекции лица:', error);
            return 0;
        }
    }
    
    async measureDistanceMediaPipe() {
        try {
            // Создаем ImageData для MediaPipe
            const imageData = this.ctx.getImageData(0, 0, this.canvas.width, this.canvas.height);
            
            // Детектируем ключевые точки лица
            const results = this.landmarker.detectForVideo(imageData, performance.now());
            
            if (!results.faceLandmarks || results.faceLandmarks.length === 0) {
                return 0;
            }
            
            const landmarks = results.faceLandmarks[0];
            
            // Получаем координаты глаз (индексы из MediaPipe)
            const leftEye = landmarks[33];   // Левый глаз
            const rightEye = landmarks[263]; // Правый глаз
            
            if (!leftEye || !rightEye) {
                return 0;
            }
            
            // Вычисляем расстояние между глазами в пикселях
            const w = this.canvas.width;
            const h = this.canvas.height;
            
            const dx = (rightEye.x - leftEye.x) * w;
            const dy = (rightEye.y - leftEye.y) * h;
            const px = Math.sqrt(dx * dx + dy * dy);
            
            // Формула для расчета расстояния
            const f_px = 0.5 * w / Math.tan((65 * Math.PI / 180) / 2); // Фокусное расстояние
            const IPD_MM = 63; // Межзрачковое расстояние (мм)
            const dist_cm = (f_px * IPD_MM) / px / 10; // Расстояние в см
            
            return Math.round(dist_cm);
            
        } catch (error) {
            console.error('Ошибка MediaPipe:', error);
            return 0;
        }
    }
    
    async measureDistanceFaceDetection() {
        try {
            // Детектируем лица
            const faces = await this.faceDetector.detect(this.canvas);
            
            if (faces.length === 0) {
                return 0;
            }
            
            const face = faces[0];
            const faceWidth = face.boundingBox.width;
            
            // Примерная формула для расчета расстояния
            // Основана на том, что средняя ширина лица взрослого человека ~14см
            const realFaceWidth = 14; // см
            const focalLength = 640; // примерная фокусная длина камеры
            const distance = (realFaceWidth * focalLength) / faceWidth;
            
            return Math.round(distance);
            
        } catch (error) {
            console.error('Ошибка Face Detection API:', error);
            return 0;
        }
    }
    
    processDistance(distance) {
        console.log(`📏 Расстояние до экрана: ${distance}см`);
        
        // Адаптивная система мониторинга
        if (distance < this.settings.minCm) {
            // Слишком близко - переходим в режим частых проверок
            this.currentInterval = 5000; // 5 секунд
            this.okCounter = 0;
            
            this.showDangerNotification(distance);
            this.stats.warnings++;
            
            if (this.settings.soundEnabled) {
                this.playWarningSound();
            }
            
            // Отправляем событие для других компонентов
            window.dispatchEvent(new CustomEvent('distance-guard', { 
                detail: { status: 'too_close', distance: distance } 
            }));
            
        } else if (distance > this.settings.maxCm) {
            // Слишком далеко - тоже предупреждаем
            this.currentInterval = 5000; // 5 секунд
            this.okCounter = 0;
            
            this.showWarningNotification(distance, 'Слишком далеко');
            this.stats.warnings++;
            
            // Отправляем событие для других компонентов
            window.dispatchEvent(new CustomEvent('distance-guard', { 
                detail: { status: 'too_far', distance: distance } 
            }));
            
        } else {
            // Нормальное расстояние
            this.okCounter++;
            this.hideNotification();
            
            // Возвращаемся к нормальному режиму после 2 успешных проверок
            if (this.okCounter >= 2) {
                this.currentInterval = 60000; // 60 секунд
            }
            
            // Отправляем событие для других компонентов
            window.dispatchEvent(new CustomEvent('distance-guard', { 
                detail: { status: 'ok', distance: distance } 
            }));
        }
    }
    
    showDangerNotification(distance) {
        this.notification.innerHTML = `
            <div style="display: flex; align-items: center; gap: 10px;">
                <div style="font-size: 24px;">⚠️</div>
                <div>
                    <div style="font-size: 16px; margin-bottom: 5px;">ОПАСНОСТЬ!</div>
                    <div style="font-size: 12px; opacity: 0.9;">Расстояние: ${distance}см</div>
                    <div style="font-size: 12px; opacity: 0.9;">Критически близко к экрану!</div>
                </div>
            </div>
        `;
        this.notification.style.background = '#ff4757';
        this.notification.style.borderLeftColor = '#ff3742';
        this.notification.style.display = 'block';
    }
    
    showWarningNotification(distance) {
        this.notification.innerHTML = `
            <div style="display: flex; align-items: center; gap: 10px;">
                <div style="font-size: 24px;">👁️</div>
                <div>
                    <div style="font-size: 16px; margin-bottom: 5px;">Предупреждение</div>
                    <div style="font-size: 12px; opacity: 0.9;">Расстояние: ${distance}см</div>
                    <div style="font-size: 12px; opacity: 0.9;">Отодвиньтесь от экрана</div>
                </div>
            </div>
        `;
        this.notification.style.background = '#ffa502';
        this.notification.style.borderLeftColor = '#ff9500';
        this.notification.style.display = 'block';
    }
    
    hideNotification() {
        this.notification.style.display = 'none';
    }
    
    showNotification(message, type = 'info') {
        const colors = {
            info: '#667eea',
            warning: '#ffa502',
            error: '#ff4757',
            success: '#2ed573'
        };
        
        this.notification.innerHTML = `
            <div style="display: flex; align-items: center; gap: 10px;">
                <div style="font-size: 20px;">${type === 'error' ? '❌' : type === 'success' ? '✅' : 'ℹ️'}</div>
                <div>${message}</div>
            </div>
        `;
        this.notification.style.background = colors[type] || colors.info;
        this.notification.style.display = 'block';
        
        setTimeout(() => {
            this.hideNotification();
        }, 3000);
    }
    
    playWarningSound() {
        // Создаем простой звуковой сигнал
        const audioContext = new (window.AudioContext || window.webkitAudioContext)();
        const oscillator = audioContext.createOscillator();
        const gainNode = audioContext.createGain();
        
        oscillator.connect(gainNode);
        gainNode.connect(audioContext.destination);
        
        oscillator.frequency.setValueAtTime(800, audioContext.currentTime);
        gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
        gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.5);
        
        oscillator.start(audioContext.currentTime);
        oscillator.stop(audioContext.currentTime + 0.5);
    }
    
    updateAverageDistance(distance) {
        if (this.stats.measurements === 1) {
            this.stats.averageDistance = distance;
        } else {
            this.stats.averageDistance = 
                (this.stats.averageDistance * (this.stats.measurements - 1) + distance) / this.stats.measurements;
        }
    }
    
    loadSettings() {
        const saved = localStorage.getItem('eyeMonitorSettings');
        if (saved) {
            this.settings = { ...this.settings, ...JSON.parse(saved) };
        }
    }
    
    saveSettings() {
        localStorage.setItem('eyeMonitorSettings', JSON.stringify(this.settings));
    }
    
    updateSettings(newSettings) {
        this.settings = { ...this.settings, ...newSettings };
        this.saveSettings();
        
        // Перезапускаем мониторинг с новыми настройками
        if (this.isActive) {
            this.stop();
            setTimeout(() => this.start(), 100);
        }
    }
    
    getStats() {
        return {
            ...this.stats,
            isActive: this.isActive,
            sessionDuration: this.stats.sessionStart ? 
                Math.floor((new Date() - this.stats.sessionStart) / 1000) : 0
        };
    }
}

// Глобальная инициализация
let eyeMonitor = null;

// Инициализируем мониторинг при загрузке страницы
document.addEventListener('DOMContentLoaded', () => {
    console.log('🚀 Загрузка системы мониторинга глаз...');
    eyeMonitor = new EyeMonitor();
});

// Экспортируем для использования в других скриптах
window.EyeMonitor = EyeMonitor;
window.eyeMonitor = eyeMonitor;

// API для управления мониторингом
window.startEyeMonitoring = () => eyeMonitor?.start();
window.stopEyeMonitoring = () => eyeMonitor?.stop();
window.getEyeMonitoringStats = () => eyeMonitor?.getStats();
window.updateEyeMonitoringSettings = (settings) => eyeMonitor?.updateSettings(settings);
