#!/usr/bin/env python3
"""
Тестовый скрипт для проверки системы озвучки кнопок
"""

import requests
import json
import time
import sys

def test_button_audio_server():
    """Тестирует сервер озвучки кнопок"""
    print("🧪 Тестирование системы озвучки кнопок...")
    
    # URL сервера озвучки кнопок
    server_url = "http://localhost:8001"
    
    # Тестовые тексты для озвучки
    test_texts = [
        "Кнопка",
        "Настройки", 
        "Сохранить",
        "Отмена",
        "Применить"
    ]
    
    print(f"📍 Тестируем сервер: {server_url}")
    print("")
    
    for i, text in enumerate(test_texts, 1):
        print(f"🔊 Тест {i}/{len(test_texts)}: '{text}'")
        
        try:
            # Отправляем запрос на озвучку
            response = requests.post(
                f"{server_url}/api/speak-button",
                json={"text": text},
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success'):
                    print(f"  ✅ Успешно озвучено: {text}")
                else:
                    print(f"  ❌ Ошибка озвучки: {data.get('error', 'Неизвестная ошибка')}")
            else:
                print(f"  ❌ HTTP ошибка: {response.status_code}")
                
        except requests.exceptions.ConnectionError:
            print(f"  ❌ Сервер недоступен: {server_url}")
            print("  💡 Убедитесь, что сервер запущен: python3 button-audio-server.py")
            return False
            
        except requests.exceptions.Timeout:
            print(f"  ⏰ Таймаут запроса для: {text}")
            
        except Exception as e:
            print(f"  ❌ Ошибка: {e}")
        
        # Небольшая пауза между тестами
        time.sleep(0.5)
    
    print("")
    print("🎉 Тестирование завершено!")
    return True

def test_festival_scripts():
    """Тестирует скрипты Festival напрямую"""
    print("🎤 Тестирование скриптов Festival...")
    
    import subprocess
    import os
    
    festival_dir = "/Users/aliserromankul/Desktop/smartscrolling/smart_scroll2/#2/festival"
    speak_script = os.path.join(festival_dir, "speak.py")
    
    if not os.path.exists(speak_script):
        print(f"❌ Скрипт speak.py не найден: {speak_script}")
        return False
    
    print(f"✅ Найден скрипт: {speak_script}")
    
    try:
        # Тестируем speak.py
        result = subprocess.run(
            ["python3", speak_script, "Тест озвучки"],
            capture_output=True,
            text=True,
            cwd=festival_dir,
            timeout=10
        )
        
        if result.returncode == 0:
            print("✅ speak.py работает корректно")
            print(f"  Вывод: {result.stdout.strip()}")
        else:
            print("❌ speak.py не работает")
            print(f"  Ошибка: {result.stderr.strip()}")
            return False
            
    except subprocess.TimeoutExpired:
        print("⏰ Таймаут выполнения speak.py")
        return False
    except Exception as e:
        print(f"❌ Ошибка запуска speak.py: {e}")
        return False
    
    return True

def main():
    """Главная функция тестирования"""
    print("🔊 Тестирование системы озвучки кнопок SmartScroll")
    print("=" * 50)
    
    # Тест 1: Скрипты Festival
    print("\n1️⃣ Тестирование скриптов Festival...")
    festival_ok = test_festival_scripts()
    
    if not festival_ok:
        print("\n❌ Скрипты Festival не работают")
        print("💡 Убедитесь, что Festival установлен и настроен")
        return
    
    # Тест 2: Сервер озвучки кнопок
    print("\n2️⃣ Тестирование сервера озвучки кнопок...")
    server_ok = test_button_audio_server()
    
    if not server_ok:
        print("\n❌ Сервер озвучки кнопок недоступен")
        print("💡 Запустите сервер: python3 button-audio-server.py")
        return
    
    print("\n🎉 Все тесты пройдены успешно!")
    print("✅ Система озвучки кнопок готова к работе")
    print("\n📋 Следующие шаги:")
    print("1. Откройте http://localhost:8000/settings.html")
    print("2. Включите 'Озвучка кнопок' в настройках")
    print("3. Нажмите на кнопки для проверки озвучки")

if __name__ == "__main__":
    main()
