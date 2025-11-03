#!/usr/bin/env python3
"""
Сервер для озвучки кнопок через Festival TTS из папки #2/
"""

import os
import sys
import json
import subprocess
import tempfile
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import threading
import time

class ButtonAudioHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        """Обработка POST запросов для озвучки кнопок"""
        if self.path == '/api/speak-button':
            self.handle_speak_button()
        else:
            self.send_error(404, "Not Found")
    
    def handle_speak_button(self):
        """Озвучивание текста кнопки через Festival"""
        try:
            # Читаем данные запроса
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data.decode('utf-8'))
            
            text = data.get('text', '')
            if not text:
                self.send_json_response({"success": False, "error": "Текст не указан"})
                return
            
            # Озвучиваем через Festival
            result = self.speak_with_festival(text)
            
            if result['success']:
                self.send_json_response({"success": True, "message": f"Озвучено: {text}"})
            else:
                self.send_json_response({"success": False, "error": result['error']})
                
        except Exception as e:
            self.send_json_response({"success": False, "error": f"Ошибка сервера: {str(e)}"})
    
    def speak_with_festival(self, text):
        """Использует speak.py из папки #2/festival/ для озвучки"""
        try:
            # Сначала пробуем системный TTS (macOS say)
            result = self.speak_with_say(text)
            if result['success']:
                return result
            
            # Если системный TTS не работает, пробуем Festival
            festival_dir = "/Users/aliserromankul/Desktop/smartscrolling/smart_scroll2/#2/festival"
            speak_script = os.path.join(festival_dir, "speak.py")
            
            # Проверяем, что скрипт существует
            if not os.path.exists(speak_script):
                print(f"❌ Скрипт speak.py не найден: {speak_script}")
                return {"success": False, "error": "Скрипт speak.py не найден"}
            
            print(f"🔊 Озвучиваем: '{text}' через {speak_script}")
            
            # Запускаем speak.py
            cmd = ["python3", speak_script, text]
            result = subprocess.run(
                cmd, 
                capture_output=True, 
                text=True, 
                cwd=festival_dir,
                timeout=15
            )
            
            print(f"📤 Результат speak.py: код={result.returncode}")
            print(f"📤 stdout: {result.stdout}")
            print(f"📤 stderr: {result.stderr}")
            
            if result.returncode == 0:
                return {"success": True, "output": result.stdout}
            else:
                return {"success": False, "error": f"Festival ошибка: {result.stderr}"}
                
        except subprocess.TimeoutExpired:
            print("⏰ Таймаут выполнения Festival")
            return {"success": False, "error": "Таймаут выполнения Festival"}
        except Exception as e:
            print(f"❌ Ошибка запуска Festival: {e}")
            return {"success": False, "error": f"Ошибка запуска Festival: {str(e)}"}
    
    def speak_with_say(self, text):
        """Использует системный TTS (macOS say)"""
        try:
            print(f"🔊 Озвучиваем через системный TTS: '{text}'")
            
            # Используем macOS say команду
            cmd = ['say', text]
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=15
            )
            
            print(f"📤 Результат say: код={result.returncode}")
            print(f"📤 stdout: {result.stdout}")
            print(f"📤 stderr: {result.stderr}")
            
            if result.returncode == 0:
                print(f"✅ Системный TTS успешно озвучил: {text}")
                return {"success": True, "output": "Озвучено через системный TTS"}
            else:
                print(f"❌ Ошибка системного TTS: {result.stderr}")
                return {"success": False, "error": f"Ошибка системного TTS: {result.stderr}"}
                
        except subprocess.TimeoutExpired:
            print("⏰ Таймаут системного TTS")
            return {"success": False, "error": "Таймаут системного TTS"}
        except Exception as e:
            print(f"❌ Ошибка системного TTS: {e}")
            return {"success": False, "error": f"Ошибка системного TTS: {str(e)}"}
    
    def send_json_response(self, data):
        """Отправляет JSON ответ"""
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
        
        response = json.dumps(data, ensure_ascii=False)
        self.wfile.write(response.encode('utf-8'))
    
    def do_OPTIONS(self):
        """Обработка CORS preflight запросов"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
    
    def log_message(self, format, *args):
        """Отключаем стандартное логирование"""
        pass

class ButtonAudioServer:
    def __init__(self, port=8001):
        self.port = port
        self.server = None
        self.server_thread = None
    
    def start(self):
        """Запускает сервер"""
        try:
            self.server = HTTPServer(('localhost', self.port), ButtonAudioHandler)
            self.server_thread = threading.Thread(target=self.server.serve_forever)
            self.server_thread.daemon = True
            self.server_thread.start()
            
            print(f"🔊 Сервер озвучки кнопок запущен на порту {self.port}")
            print(f"📍 Адрес: http://localhost:{self.port}")
            print("🎤 Использует Festival TTS из папки #2/")
            return True
            
        except Exception as e:
            print(f"❌ Ошибка запуска сервера: {e}")
            return False
    
    def stop(self):
        """Останавливает сервер"""
        if self.server:
            self.server.shutdown()
            self.server.server_close()
            print("🔇 Сервер озвучки кнопок остановлен")

def main():
    """Главная функция"""
    print("🎤 Запуск сервера озвучки кнопок через Festival TTS...")
    
    # Проверяем наличие Festival
    festival_dir = "/Users/aliserromankul/Desktop/smartscrolling/smart_scroll2/#2/festival"
    speak_script = os.path.join(festival_dir, "speak.py")
    
    if not os.path.exists(speak_script):
        print(f"❌ Скрипт speak.py не найден: {speak_script}")
        print("Убедитесь, что папка #2/festival/ существует")
        sys.exit(1)
    
    print(f"✅ Найден скрипт Festival: {speak_script}")
    
    # Запускаем сервер
    server = ButtonAudioServer(8001)
    
    if not server.start():
        sys.exit(1)
    
    try:
        print("🚀 Сервер готов к работе!")
        print("Для остановки нажмите Ctrl+C")
        
        # Ждем сигнала остановки
        while True:
            time.sleep(1)
            
    except KeyboardInterrupt:
        print("\n🛑 Получен сигнал остановки...")
        server.stop()
        print("✅ Сервер остановлен")

if __name__ == "__main__":
    main()
