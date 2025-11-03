#!/usr/bin/env python3
"""
Простой тест speak.py скрипта
"""

import subprocess
import os
import sys

def test_speak_script():
    """Тестирует speak.py скрипт"""
    print("🧪 Тестирование speak.py скрипта...")
    
    festival_dir = "/Users/aliserromankul/Desktop/smartscrolling/smart_scroll2/#2/festival"
    speak_script = os.path.join(festival_dir, "speak.py")
    
    if not os.path.exists(speak_script):
        print(f"❌ Скрипт speak.py не найден: {speak_script}")
        return False
    
    print(f"✅ Найден скрипт: {speak_script}")
    
    # Тестовый текст
    test_text = "Тест озвучки"
    
    try:
        print(f"🔊 Тестируем озвучку: '{test_text}'")
        
        # Запускаем speak.py
        result = subprocess.run(
            ["python3", speak_script, test_text],
            capture_output=True,
            text=True,
            cwd=festival_dir,
            timeout=15
        )
        
        print(f"📤 Код возврата: {result.returncode}")
        print(f"📤 stdout: {result.stdout}")
        print(f"📤 stderr: {result.stderr}")
        
        if result.returncode == 0:
            print("✅ speak.py работает корректно")
            return True
        else:
            print("❌ speak.py не работает")
            return False
            
    except subprocess.TimeoutExpired:
        print("⏰ Таймаут выполнения speak.py")
        return False
    except Exception as e:
        print(f"❌ Ошибка запуска speak.py: {e}")
        return False

def test_festival_server():
    """Проверяет, запущен ли Festival сервер"""
    print("\n🎤 Проверка Festival сервера...")
    
    try:
        import socket
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(1)
        result = sock.connect_ex(('localhost', 1314))
        sock.close()
        
        if result == 0:
            print("✅ Festival сервер запущен на порту 1314")
            return True
        else:
            print("❌ Festival сервер не запущен на порту 1314")
            print("💡 Запустите: ./start_tts_server.sh")
            return False
    except Exception as e:
        print(f"❌ Ошибка проверки сервера: {e}")
        return False

def main():
    """Главная функция"""
    print("🔊 Тестирование системы озвучки")
    print("=" * 40)
    
    # Тест 1: Festival сервер
    server_ok = test_festival_server()
    
    # Тест 2: speak.py скрипт
    speak_ok = test_speak_script()
    
    print("\n📋 Результаты:")
    print(f"Festival сервер: {'✅' if server_ok else '❌'}")
    print(f"speak.py скрипт: {'✅' if speak_ok else '❌'}")
    
    if server_ok and speak_ok:
        print("\n🎉 Все тесты пройдены! Система готова к работе.")
    else:
        print("\n❌ Есть проблемы. Проверьте настройки Festival.")

if __name__ == "__main__":
    main()
