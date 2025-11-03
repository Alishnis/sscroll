/**
 * Conference Service - Сервис для управления видеоконференциями
 * Интеграция с Twilio Video SDK для SmartScroll
 */

class ConferenceService {
    constructor() {
        this.room = null;
        this.localParticipant = null;
        this.participants = new Map();
        this.isMuted = false;
        this.isVideoEnabled = true;
        this.isScreenSharing = false;
        this.currentRoomName = '';
        this.currentUserName = '';
        
        // Twilio Video SDK настройки
        this.connectOptions = {
            // Настройки для групповых комнат
            bandwidthProfile: {
                video: {
                    dominantSpeakerPriority: 'high',
                    mode: 'collaboration',
                    clientTrackSwitchOffControl: 'auto',
                    contentPreferencesMode: 'auto'
                }
            },
            dominantSpeaker: true,
            maxAudioBitrate: 16000,
            preferredVideoCodecs: [{ codec: 'VP8', simulcast: true }],
            video: { height: 720, frameRate: 24, width: 1280 }
        };
        
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.loadDevices();
        this.updateUI();
        console.log('📹 Conference Service инициализирован');
    }

    setupEventListeners() {
        // Обработка закрытия страницы
        window.addEventListener('beforeunload', () => {
            if (this.room) {
                this.leaveRoom();
            }
        });

        // Обработка изменения размера окна
        window.addEventListener('resize', () => {
            this.adjustVideoLayout();
        });
    }

    // Загрузка доступных устройств
    async loadDevices() {
        try {
            const devices = await navigator.mediaDevices.enumerateDevices();
            const cameras = devices.filter(device => device.kind === 'videoinput');
            const microphones = devices.filter(device => device.kind === 'audioinput');

            this.populateDeviceSelect('cameraSelect', cameras);
            this.populateDeviceSelect('microphoneSelect', microphones);
        } catch (error) {
            console.error('Ошибка загрузки устройств:', error);
            this.showError('Не удалось загрузить список устройств');
        }
    }

    populateDeviceSelect(selectId, devices) {
        const select = document.getElementById(selectId);
        if (!select) return;

        // Очищаем существующие опции (кроме первой)
        while (select.children.length > 1) {
            select.removeChild(select.lastChild);
        }

        devices.forEach(device => {
            const option = document.createElement('option');
            option.value = device.deviceId;
            option.textContent = device.label || `${device.kind} ${device.deviceId.substring(0, 8)}`;
            select.appendChild(option);
        });
    }

    // Показать модальное окно присоединения
    showJoinModal() {
        $('#joinRoomModal').modal('show');
    }

    // Показать модальное окно создания
    showCreateModal() {
        $('#createRoomModal').modal('show');
    }

    // Присоединиться к комнате
    async joinRoom() {
        const roomName = document.getElementById('joinRoomName').value.trim();
        const userName = document.getElementById('joinUserName').value.trim();

        if (!roomName || !userName) {
            this.showError('Пожалуйста, заполните все поля');
            return;
        }

        this.currentRoomName = roomName;
        this.currentUserName = userName;

        try {
            $('#joinRoomModal').modal('hide');
            this.updateStatus('Подключение к комнате...', 'connecting');

            // Получаем токен доступа (в реальном приложении это должно быть с сервера)
            const token = await this.getAccessToken(roomName, userName);
            
            // Подключаемся к комнате
            this.room = await Twilio.Video.connect(token, {
                ...this.connectOptions,
                name: roomName
            });

            this.setupRoomEventListeners();
            this.updateUI();
            this.updateStatus('Подключен к комнате', 'connected');
            this.showRoomInfo();

        } catch (error) {
            console.error('Ошибка подключения к комнате:', error);
            this.showError(`Не удалось подключиться к комнате: ${error.message}`);
            this.updateStatus('Ошибка подключения', 'error');
        }
    }

    // Создать комнату
    async createRoom() {
        const roomName = document.getElementById('createRoomName').value.trim();
        const userName = document.getElementById('createUserName').value.trim();

        if (!roomName || !userName) {
            this.showError('Пожалуйста, заполните все поля');
            return;
        }

        // Генерируем уникальное имя комнаты
        const uniqueRoomName = `${roomName}-${Date.now()}`;
        
        document.getElementById('joinRoomName').value = uniqueRoomName;
        document.getElementById('joinUserName').value = userName;
        
        $('#createRoomModal').modal('hide');
        await this.joinRoom();
    }

    // Получить токен доступа
    async getAccessToken(roomName, userName) {
        try {
            const response = await fetch(`http://localhost:3007/token?identity=${encodeURIComponent(userName)}`);

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const token = await response.text();
            return token;
            
        } catch (error) {
            console.error('Ошибка получения токена:', error);
            
            // Если сервер токенов недоступен, показываем инструкции
            if (error.message.includes('fetch')) {
                this.showError(`
                    Сервер токенов недоступен!
                    
                    Для работы видеоконференций:
                    1. Запустите сервер токенов: npm start
                    2. Настройте Twilio API ключи в .env файле
                    3. Обновите страницу
                    
                    Инструкции: см. CONFERENCE_SETUP.md
                `);
            }
            
            throw error;
        }
    }

    // Настройка обработчиков событий комнаты
    setupRoomEventListeners() {
        if (!this.room) return;

        // Участник присоединился
        this.room.on('participantConnected', participant => {
            console.log('Участник присоединился:', participant.identity);
            this.addParticipant(participant);
            this.updateParticipantCount();
        });

        // Участник покинул комнату
        this.room.on('participantDisconnected', participant => {
            console.log('Участник покинул комнату:', participant.identity);
            this.removeParticipant(participant);
            this.updateParticipantCount();
        });

        // Комната отключена
        this.room.on('disconnected', room => {
            console.log('Отключен от комнаты');
            this.cleanup();
            this.updateStatus('Отключен от комнаты', 'disconnected');
        });

        // Доминирующий спикер изменился
        this.room.on('dominantSpeakerChanged', participant => {
            if (participant) {
                this.setActiveParticipant(participant);
            }
        });

        // Добавляем локального участника
        this.localParticipant = this.room.localParticipant;
        this.addParticipant(this.localParticipant);
        this.updateParticipantCount();
    }

    // Добавить участника
    addParticipant(participant) {
        this.participants.set(participant.sid, participant);
        this.createParticipantElement(participant);
        this.setupParticipantEventListeners(participant);
    }

    // Удалить участника
    removeParticipant(participant) {
        this.participants.delete(participant.sid);
        this.removeParticipantElement(participant.sid);
    }

    // Создать элемент участника
    createParticipantElement(participant) {
        const videoGrid = document.getElementById('videoGrid');
        const participantDiv = document.createElement('div');
        participantDiv.className = 'video-participant';
        participantDiv.id = participant.sid;
        
        participantDiv.innerHTML = `
            <video autoplay playsinline muted></video>
            <div class="participant-info">${participant.identity}</div>
            <div class="participant-controls">
                <button class="control-btn" onclick="conferenceService.toggleParticipantMute('${participant.sid}')" title="Включить/выключить звук">
                    🎤
                </button>
                <button class="control-btn" onclick="conferenceService.toggleParticipantVideo('${participant.sid}')" title="Включить/выключить видео">
                    📹
                </button>
            </div>
        `;

        videoGrid.appendChild(participantDiv);
        this.attachParticipantTracks(participant);
    }

    // Удалить элемент участника
    removeParticipantElement(participantSid) {
        const participantElement = document.getElementById(participantSid);
        if (participantElement) {
            participantElement.remove();
        }
    }

    // Настроить обработчики событий участника
    setupParticipantEventListeners(participant) {
        // Видео трек добавлен
        participant.on('trackSubscribed', track => {
            this.attachTrack(track, participant);
        });

        // Видео трек удален
        participant.on('trackUnsubscribed', track => {
            this.detachTrack(track, participant);
        });

        // Трек опубликован
        participant.on('trackPublished', publication => {
            console.log('Трек опубликован:', publication.trackName);
        });

        // Трек отозван
        participant.on('trackUnpublished', publication => {
            console.log('Трек отозван:', publication.trackName);
        });
    }

    // Прикрепить треки участника
    attachParticipantTracks(participant) {
        participant.tracks.forEach(publication => {
            if (publication.track) {
                this.attachTrack(publication.track, participant);
            }
        });
    }

    // Прикрепить трек к элементу
    attachTrack(track, participant) {
        const participantElement = document.getElementById(participant.sid);
        if (!participantElement) return;

        const videoElement = participantElement.querySelector('video');
        if (track.kind === 'video' && videoElement) {
            track.attach(videoElement);
        }
    }

    // Открепить трек от элемента
    detachTrack(track, participant) {
        const participantElement = document.getElementById(participant.sid);
        if (!participantElement) return;

        const videoElement = participantElement.querySelector('video');
        if (track.kind === 'video' && videoElement) {
            track.detach(videoElement);
        }
    }

    // Установить активного участника
    setActiveParticipant(participant) {
        // Убираем активный класс со всех участников
        document.querySelectorAll('.video-participant').forEach(el => {
            el.classList.remove('active');
        });

        // Добавляем активный класс к выбранному участнику
        const participantElement = document.getElementById(participant.sid);
        if (participantElement) {
            participantElement.classList.add('active');
        }
    }

    // Переключить микрофон
    toggleMute() {
        if (!this.localParticipant) return;

        const audioTracks = Array.from(this.localParticipant.audioTracks.values());
        audioTracks.forEach(publication => {
            if (publication.track) {
                publication.track.enable(!this.isMuted);
            }
        });

        this.isMuted = !this.isMuted;
        this.updateMuteButton();
    }

    // Переключить видео
    toggleVideo() {
        if (!this.localParticipant) return;

        const videoTracks = Array.from(this.localParticipant.videoTracks.values());
        videoTracks.forEach(publication => {
            if (publication.track) {
                publication.track.enable(!this.isVideoEnabled);
            }
        });

        this.isVideoEnabled = !this.isVideoEnabled;
        this.updateVideoButton();
    }

    // Переключить демонстрацию экрана
    async toggleScreenShare() {
        if (!this.localParticipant) return;

        try {
            if (this.isScreenSharing) {
                // Останавливаем демонстрацию экрана
                const screenTracks = Array.from(this.localParticipant.videoTracks.values())
                    .filter(publication => publication.trackName === 'screen');
                
                screenTracks.forEach(publication => {
                    publication.track.stop();
                    this.localParticipant.unpublishTrack(publication.track);
                });

                this.isScreenSharing = false;
            } else {
                // Начинаем демонстрацию экрана
                const screenTrack = await Twilio.Video.createScreenTracks({
                    video: { height: 720, frameRate: 24, width: 1280 }
                });

                await this.localParticipant.publishTrack(screenTrack[0]);
                this.isScreenSharing = true;
            }

            this.updateScreenShareButton();
        } catch (error) {
            console.error('Ошибка демонстрации экрана:', error);
            this.showError('Не удалось начать демонстрацию экрана');
        }
    }

    // Обновить кнопку микрофона
    updateMuteButton() {
        const muteBtn = document.getElementById('muteBtn');
        if (muteBtn) {
            muteBtn.textContent = this.isMuted ? '🔇' : '🎤';
            muteBtn.classList.toggle('muted', this.isMuted);
        }
    }

    // Обновить кнопку видео
    updateVideoButton() {
        const videoBtn = document.getElementById('videoBtn');
        if (videoBtn) {
            videoBtn.textContent = this.isVideoEnabled ? '📹' : '📷';
            videoBtn.classList.toggle('video-off', !this.isVideoEnabled);
        }
    }

    // Обновить кнопку демонстрации экрана
    updateScreenShareButton() {
        const screenShareBtn = document.getElementById('screenShareBtn');
        if (screenShareBtn) {
            screenShareBtn.textContent = this.isScreenSharing ? '🖥️' : '🖥️';
            screenShareBtn.classList.toggle('active', this.isScreenSharing);
        }
    }

    // Покинуть комнату
    leaveRoom() {
        if (this.room) {
            this.room.disconnect();
        }
        this.cleanup();
        this.updateStatus('Не подключен', 'disconnected');
    }

    // Очистка ресурсов
    cleanup() {
        this.room = null;
        this.localParticipant = null;
        this.participants.clear();
        this.isMuted = false;
        this.isVideoEnabled = true;
        this.isScreenSharing = false;

        // Очищаем видео контейнер
        const videoGrid = document.getElementById('videoGrid');
        if (videoGrid) {
            videoGrid.innerHTML = '';
        }

        this.updateUI();
        this.hideRoomInfo();
    }

    // Обновить UI
    updateUI() {
        const isConnected = this.room !== null;
        
        document.getElementById('joinRoomBtn').style.display = isConnected ? 'none' : 'inline-block';
        document.getElementById('createRoomBtn').style.display = isConnected ? 'none' : 'inline-block';
        document.getElementById('leaveRoomBtn').style.display = isConnected ? 'inline-block' : 'none';
        document.getElementById('videoContainer').classList.toggle('active', isConnected);
        document.getElementById('deviceSelector').style.display = isConnected ? 'block' : 'none';

        this.updateMuteButton();
        this.updateVideoButton();
        this.updateScreenShareButton();
    }

    // Обновить статус
    updateStatus(message, type) {
        const statusElement = document.getElementById('connectionStatus');
        if (statusElement) {
            statusElement.innerHTML = `<strong>Статус:</strong> ${message}`;
            statusElement.className = `status ${type}`;
        }
    }

    // Показать информацию о комнате
    showRoomInfo() {
        const roomInfo = document.getElementById('roomInfo');
        if (roomInfo) {
            document.getElementById('roomName').textContent = this.currentRoomName;
            document.getElementById('userName').textContent = this.currentUserName;
            roomInfo.style.display = 'block';
        }
    }

    // Скрыть информацию о комнате
    hideRoomInfo() {
        const roomInfo = document.getElementById('roomInfo');
        if (roomInfo) {
            roomInfo.style.display = 'none';
        }
    }

    // Обновить количество участников
    updateParticipantCount() {
        const countElement = document.getElementById('participantCount');
        if (countElement) {
            countElement.textContent = this.participants.size;
        }
    }

    // Обновить устройства
    async updateDevices() {
        await this.loadDevices();
        this.showSuccess('Список устройств обновлен');
    }

    // Настроить макет видео
    adjustVideoLayout() {
        const videoGrid = document.getElementById('videoGrid');
        if (!videoGrid) return;

        const participantCount = this.participants.size;
        if (participantCount <= 1) {
            videoGrid.style.gridTemplateColumns = '1fr';
        } else if (participantCount <= 4) {
            videoGrid.style.gridTemplateColumns = 'repeat(2, 1fr)';
        } else {
            videoGrid.style.gridTemplateColumns = 'repeat(auto-fit, minmax(300px, 1fr))';
        }
    }

    // Показать ошибку
    showError(message) {
        alert(`Ошибка: ${message}`);
        console.error(message);
    }

    // Показать успех
    showSuccess(message) {
        console.log(message);
        // Можно добавить toast уведомления
    }

    // Переключить звук участника (для демо)
    toggleParticipantMute(participantSid) {
        console.log('Переключение звука участника:', participantSid);
        // В реальном приложении здесь должна быть логика управления звуком других участников
    }

    // Переключить видео участника (для демо)
    toggleParticipantVideo(participantSid) {
        console.log('Переключение видео участника:', participantSid);
        // В реальном приложении здесь должна быть логика управления видео других участников
    }
}

// Глобальная инициализация
let conferenceService;

document.addEventListener('DOMContentLoaded', function() {
    // Проверяем поддержку Twilio Video
    if (typeof Twilio === 'undefined') {
        console.error('Twilio Video SDK не загружен');
        alert('Ошибка: Twilio Video SDK не загружен. Проверьте подключение к интернету.');
        return;
    }

    conferenceService = new ConferenceService();
    
    // Экспорт для глобального использования
    window.conferenceService = conferenceService;
    
    // Глобальные функции для HTML
    window.showJoinModal = () => conferenceService.showJoinModal();
    window.showCreateModal = () => conferenceService.showCreateModal();
    window.joinRoom = () => conferenceService.joinRoom();
    window.createRoom = () => conferenceService.createRoom();
    window.leaveRoom = () => conferenceService.leaveRoom();
    window.toggleMute = () => conferenceService.toggleMute();
    window.toggleVideo = () => conferenceService.toggleVideo();
    window.toggleScreenShare = () => conferenceService.toggleScreenShare();
    window.updateDevices = () => conferenceService.updateDevices();
});

// Экспорт для использования в других модулях
if (typeof module !== 'undefined' && module.exports) {
    module.exports = ConferenceService;
}
