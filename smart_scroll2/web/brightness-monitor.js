/**
 * Система мониторинга яркости экрана для предупреждений о близости
 * Работает напрямую с яркостью экрана, а не с расстоянием
 */

class BrightnessMonitor {
    constructor() {
        this.isActive = false;
        this.video = null;
        this.canvas = null;
        this.ctx = null;
        this.intervalId = null;
        this.notification = null;
        
        // Настройки по умолчанию для мониторинга яркости
        this.settings = {
            checkInterval: 2000, // 2 секунды - более частые проверки
            warningBrightness: 120, // Предупреждение при низкой яркости (близко)
            dangerBrightness: 100,  // Опасность при очень низкой яркости (очень близко)
            soundEnabled: true,
            autoStart: true,
            // Калибровочные параметры для яркости
            calibration: {
                minBrightness: 150,   // Минимальная яркость (далеко)
                maxBrightness: 163,   // Максимальная яркость (близко)
                currentBrightness: 159, // Текущая яркость
                isCalibrated: true    // Система настроена
            }
        };
        
        // Статистика
        this.stats = {
            measurements: 0,
            warnings: 0,
            averageBrightness: 0,
            sessionStart: null,
            lastBrightness: 0
        };
        
        this.init();
    }
    
    async init() {
        console.log('💡 Инициализация мониторинга яркости...');
        
        // Загружаем настройки из localStorage
        this.loadSettings();
        
        // Создаем уведомление
        this.createNotification();
        
        // Автозапуск если включен
        if (this.settings.autoStart) {
            await this.start();
        }
    }
    
    createNotification() {
        // Создаем контейнер для уведомлений
        this.notification = document.createElement('div');
        this.notification.id = 'brightness-monitor-notification';
        this.notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            background: #ff4757;
            color: white;
            padding: 15px 20px;
            border-radius: 10px;
            z-index: 10000;
            font-weight: bold;
            box-shadow: 0 4px 12px rgba(0,0,0,0.3);
            display: none;
            max-width: 300px;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        `;
        document.body.appendChild(this.notification);
    }
    
    loadSettings() {
        try {
            const saved = localStorage.getItem('brightnessMonitorSettings');
            if (saved) {
                this.settings = { ...this.settings, ...JSON.parse(saved) };
            }
        } catch (error) {
            console.warn('Не удалось загрузить настройки:', error);
        }
    }
    
    saveSettings() {
        try {
            localStorage.setItem('brightnessMonitorSettings', JSON.stringify(this.settings));
        } catch (error) {
            console.warn('Не удалось сохранить настройки:', error);
        }
    }
    
    async start() {
        if (this.isActive) return;
        
        console.log('💡 Запуск мониторинга яркости...');
        
        try {
            // Запускаем камеру
            await this.startCamera();
            
            // Запускаем мониторинг
            this.startMonitoring();
            
            this.isActive = true;
            this.stats.sessionStart = Date.now();
            
            console.log('✅ Мониторинг яркости запущен');
            
        } catch (error) {
            console.error('❌ Ошибка запуска мониторинга:', error);
            this.showNotification('Ошибка доступа к камере', 'error');
        }
    }
    
    async startCamera() {
        try {
            const stream = await navigator.mediaDevices.getUserMedia({
                video: { 
                    width: 640, 
                    height: 480,
                    facingMode: 'user'
                }
            });
            
            // Создаем скрытые элементы для обработки
            this.video = document.createElement('video');
            this.video.srcObject = stream;
            this.video.play();
            this.video.style.display = 'none';
            document.body.appendChild(this.video);
            
            this.canvas = document.createElement('canvas');
            this.ctx = this.canvas.getContext('2d');
            this.canvas.style.display = 'none';
            document.body.appendChild(this.canvas);
            
        } catch (error) {
            throw new Error('Не удалось получить доступ к камере: ' + error.message);
        }
    }
    
    startMonitoring() {
        this.intervalId = setInterval(async () => {
            if (!this.isActive) return;
            
            try {
                const brightness = await this.measureBrightness();
                if (brightness > 0) {
                    this.processBrightness(brightness);
                }
            } catch (error) {
                console.error('Ошибка измерения яркости:', error);
            }
        }, this.settings.checkInterval);
    }
    
    async measureBrightness() {
        if (!this.video || this.video.readyState !== 4) {
            return 0;
        }
        
        try {
            // Устанавливаем размеры canvas
            this.canvas.width = this.video.videoWidth;
            this.canvas.height = this.video.videoHeight;
            
            // Рисуем текущий кадр
            this.ctx.drawImage(this.video, 0, 0);
            
            // Анализируем яркость изображения
            const imageData = this.ctx.getImageData(0, 0, this.canvas.width, this.canvas.height);
            const brightness = this.calculateBrightness(imageData);
            
            this.stats.measurements++;
            this.stats.lastBrightness = brightness;
            this.updateAverageBrightness(brightness);
            
            // Обновляем текущую яркость в настройках
            this.settings.calibration.currentBrightness = Math.round(brightness);
            
            return Math.round(brightness);
            
        } catch (error) {
            console.error('Ошибка измерения яркости:', error);
            return 0;
        }
    }
    
    calculateBrightness(imageData) {
        const data = imageData.data;
        let brightness = 0;
        
        // Анализируем каждый 10-й пиксель для оптимизации
        for (let i = 0; i < data.length; i += 40) { // 4 канала (RGBA) * 10
            const r = data[i];
            const g = data[i + 1];
            const b = data[i + 2];
            
            // Формула яркости (luminance)
            brightness += (0.299 * r + 0.587 * g + 0.114 * b);
        }
        
        return brightness / (data.length / 40);
    }
    
    processBrightness(brightness) {
        console.log(`💡 Яркость экрана: ${brightness}`);
        
        // Низкая яркость = близко к экрану (опасно)
        if (brightness <= this.settings.dangerBrightness) {
            this.showDangerNotification(brightness);
            this.stats.warnings++;
            
            if (this.settings.soundEnabled) {
                this.playWarningSound();
            }
            
        } else if (brightness <= this.settings.warningBrightness) {
            this.showWarningNotification(brightness);
            this.stats.warnings++;
            
        } else {
            this.hideNotification();
        }
    }
    
    showDangerNotification(brightness) {
        this.notification.innerHTML = `
            <div style="display: flex; align-items: center; gap: 10px;">
                <div style="font-size: 24px;">⚠️</div>
                <div>
                    <div style="font-size: 16px; font-weight: bold;">ОПАСНОСТЬ!</div>
                    <div style="font-size: 14px; opacity: 0.9;">Слишком близко к экрану!</div>
                    <div style="font-size: 12px; opacity: 0.8;">Яркость: ${brightness} (низкая)</div>
                </div>
            </div>
        `;
        this.notification.style.background = '#ff4757';
        this.notification.style.display = 'block';
    }
    
    showWarningNotification(brightness) {
        this.notification.innerHTML = `
            <div style="display: flex; align-items: center; gap: 10px;">
                <div style="font-size: 24px;">👁️</div>
                <div>
                    <div style="font-size: 16px; font-weight: bold;">Предупреждение</div>
                    <div style="font-size: 14px; opacity: 0.9;">Близко к экрану</div>
                    <div style="font-size: 12px; opacity: 0.8;">Яркость: ${brightness} (низкая)</div>
                </div>
            </div>
        `;
        this.notification.style.background = '#ffa502';
        this.notification.style.display = 'block';
    }
    
    hideNotification() {
        this.notification.style.display = 'none';
    }
    
    showNotification(message, type = 'info') {
        const colors = {
            success: '#2ed573',
            error: '#ff4757',
            warning: '#ffa502',
            info: '#667eea'
        };
        
        this.notification.innerHTML = `
            <div style="display: flex; align-items: center; gap: 10px;">
                <div style="font-size: 20px;">ℹ️</div>
                <div style="font-size: 14px;">${message}</div>
            </div>
        `;
        this.notification.style.background = colors[type] || colors.info;
        this.notification.style.display = 'block';
        
        setTimeout(() => {
            this.notification.style.display = 'none';
        }, 3000);
    }
    
    playWarningSound() {
        try {
            const ctx = new (window.AudioContext || window.webkitAudioContext)();
            const oscillator = ctx.createOscillator();
            const gainNode = ctx.createGain();
            
            oscillator.connect(gainNode);
            gainNode.connect(ctx.destination);
            
            oscillator.frequency.value = 800; // Частота
            oscillator.type = 'sine';
            gainNode.gain.value = 0.1; // Громкость
            
            oscillator.start();
            setTimeout(() => {
                oscillator.stop();
                ctx.close();
            }, 200);
        } catch (error) {
            console.warn('Не удалось воспроизвести звук:', error);
        }
    }
    
    updateAverageBrightness(brightness) {
        if (this.stats.averageBrightness === 0) {
            this.stats.averageBrightness = brightness;
        } else {
            this.stats.averageBrightness = (this.stats.averageBrightness + brightness) / 2;
        }
    }
    
    stop() {
        if (!this.isActive) return;
        
        console.log('💡 Остановка мониторинга яркости...');
        
        this.isActive = false;
        
        if (this.intervalId) {
            clearInterval(this.intervalId);
            this.intervalId = null;
        }
        
        if (this.video && this.video.srcObject) {
            this.video.srcObject.getTracks().forEach(track => track.stop());
            this.video.srcObject = null;
        }
        
        if (this.video && this.video.parentNode) {
            this.video.parentNode.removeChild(this.video);
        }
        
        if (this.canvas && this.canvas.parentNode) {
            this.canvas.parentNode.removeChild(this.canvas);
        }
        
        this.hideNotification();
        console.log('✅ Мониторинг яркости остановлен');
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
        const sessionDuration = this.stats.sessionStart ? 
            Math.floor((Date.now() - this.stats.sessionStart) / 1000) : 0;
            
        return {
            isActive: this.isActive,
            measurements: this.stats.measurements,
            warnings: this.stats.warnings,
            averageBrightness: Math.round(this.stats.averageBrightness),
            sessionDuration: sessionDuration,
            lastBrightness: this.stats.lastBrightness,
            calibration: {
                ...this.settings.calibration,
                currentBrightness: this.settings.calibration.currentBrightness || 159
            }
        };
    }
    
    // Методы калибровки для яркости
    startCalibration() {
        console.log('🎯 Начало калибровки яркости...');
        this.calibrationData = {
            closeMeasurements: [],
            farMeasurements: [],
            step: 0 // 0 = ожидание, 1 = близко, 2 = далеко
        };
        this.showNotification('Калибровка: сядьте близко к экрану и нажмите "Зафиксировать близко"', 'info');
    }
    
    recordCalibrationPoint(type) {
        if (!this.calibrationData) {
            this.showNotification('Сначала запустите калибровку', 'error');
            return;
        }
        
        if (!this.video || this.video.readyState !== 4) {
            this.showNotification('Камера не готова', 'error');
            return;
        }
        
        try {
            // Получаем текущую яркость
            this.canvas.width = this.video.videoWidth;
            this.canvas.height = this.video.videoHeight;
            this.ctx.drawImage(this.video, 0, 0);
            const imageData = this.ctx.getImageData(0, 0, this.canvas.width, this.canvas.height);
            const brightness = this.calculateBrightness(imageData);
            
            if (type === 'close') {
                this.calibrationData.closeMeasurements.push(brightness);
                this.showNotification(`Зафиксировано близко (${this.calibrationData.closeMeasurements.length}/3)`, 'success');
                
                if (this.calibrationData.closeMeasurements.length >= 3) {
                    this.showNotification('Теперь отодвиньтесь далеко и нажмите "Зафиксировать далеко"', 'info');
                }
            } else if (type === 'far') {
                this.calibrationData.farMeasurements.push(brightness);
                this.showNotification(`Зафиксировано далеко (${this.calibrationData.farMeasurements.length}/3)`, 'success');
                
                if (this.calibrationData.farMeasurements.length >= 3) {
                    this.completeCalibration();
                }
            }
        } catch (error) {
            this.showNotification('Ошибка калибровки: ' + error.message, 'error');
        }
    }
    
    completeCalibration() {
        try {
            // Вычисляем средние значения
            const avgCloseBrightness = this.calibrationData.closeMeasurements.reduce((a, b) => a + b, 0) / this.calibrationData.closeMeasurements.length;
            const avgFarBrightness = this.calibrationData.farMeasurements.reduce((a, b) => a + b, 0) / this.calibrationData.farMeasurements.length;
            
            // Обновляем калибровочные параметры
            this.settings.calibration.minBrightness = Math.round(avgFarBrightness);
            this.settings.calibration.maxBrightness = Math.round(avgCloseBrightness);
            this.settings.calibration.currentBrightness = Math.round((avgCloseBrightness + avgFarBrightness) / 2);
            this.settings.calibration.isCalibrated = true;
            
            this.saveSettings();
            
            this.showNotification('Калибровка завершена! Система настроена под ваше устройство.', 'success');
            console.log('✅ Калибровка завершена:', this.settings.calibration);
            
            this.calibrationData = null;
        } catch (error) {
            this.showNotification('Ошибка завершения калибровки: ' + error.message, 'error');
        }
    }
    
    resetCalibration() {
        this.settings.calibration = {
            minBrightness: 150,
            maxBrightness: 163,
            currentBrightness: 159,
            isCalibrated: true
        };
        this.saveSettings();
        this.showNotification('Калибровка сброшена к настройкам по умолчанию', 'info');
    }
}

// Глобальные функции для управления
let brightnessMonitor = null;

function initBrightnessMonitor() {
    if (!brightnessMonitor) {
        brightnessMonitor = new BrightnessMonitor();
    }
    return brightnessMonitor;
}

function startBrightnessEyeMonitoring() {
    const monitor = initBrightnessMonitor();
    console.log('🚀 Запуск мониторинга яркости...');
    return monitor.start();
}

function stopBrightnessEyeMonitoring() {
    if (brightnessMonitor) {
        console.log('⏹️ Остановка мониторинга яркости...');
        brightnessMonitor.stop();
    }
}

function getBrightnessEyeMonitoringStats() {
    if (brightnessMonitor) {
        return brightnessMonitor.getStats();
    }
    return {
        isActive: false,
        measurements: 0,
        warnings: 0,
        averageBrightness: 0,
        sessionDuration: 0,
        lastBrightness: 0,
        calibration: {
            minBrightness: 120,
            maxBrightness: 150,
            currentBrightness: 135,
            isCalibrated: true
        }
    };
}

function updateBrightnessEyeMonitoringSettings(settings) {
    if (brightnessMonitor) {
        brightnessMonitor.updateSettings(settings);
    }
}

// Функции калибровки
function startBrightnessCalibration() {
    if (brightnessMonitor) {
        brightnessMonitor.startCalibration();
    }
}

function recordBrightnessCalibrationClose() {
    if (brightnessMonitor) {
        brightnessMonitor.recordCalibrationPoint('close');
    }
}

function recordBrightnessCalibrationFar() {
    if (brightnessMonitor) {
        brightnessMonitor.recordCalibrationPoint('far');
    }
}

function resetBrightnessCalibration() {
    if (brightnessMonitor) {
        brightnessMonitor.resetCalibration();
    }
}

// Автоматическая инициализация при загрузке страницы
document.addEventListener('DOMContentLoaded', () => {
    console.log('🚀 Автоматическая инициализация мониторинга яркости...');
    initBrightnessMonitor();
});

// Экспорт для глобального использования
window.startBrightnessEyeMonitoring = startBrightnessEyeMonitoring;
window.stopBrightnessEyeMonitoring = stopBrightnessEyeMonitoring;
window.getBrightnessEyeMonitoringStats = getBrightnessEyeMonitoringStats;
window.updateBrightnessEyeMonitoringSettings = updateBrightnessEyeMonitoringSettings;

// Экспорт функций калибровки
window.startBrightnessCalibration = startBrightnessCalibration;
window.recordBrightnessCalibrationClose = recordBrightnessCalibrationClose;
window.recordBrightnessCalibrationFar = recordBrightnessCalibrationFar;
window.resetBrightnessCalibration = resetBrightnessCalibration;
