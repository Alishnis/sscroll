#!/usr/bin/env python3
"""
Скрипт для автоматического добавления button-audio.js на все HTML страницы
"""

import os
import re
import glob

def add_button_audio_to_html(file_path):
    """Добавляет button-audio.js в HTML файл"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Проверяем, есть ли уже button-audio.js
        if 'button-audio.js' in content:
            print(f"✅ {file_path} - уже содержит button-audio.js")
            return True
        
        # Ищем место для вставки (после других скриптов)
        patterns = [
            r'(<script src="[^"]*\.js"[^>]*></script>\s*)(</head>)',
            r'(<script src="[^"]*\.js"[^>]*></script>\s*)(<style>)',
            r'(<script src="[^"]*\.js"[^>]*></script>\s*)(<body>)',
            r'(</head>)',
        ]
        
        button_audio_script = '    <!-- Button Audio System -->\n    <script src="button-audio.js"></script>\n'
        
        for pattern in patterns:
            if re.search(pattern, content):
                # Вставляем перед </head> или после последнего скрипта
                if pattern.endswith('(</head>)'):
                    content = re.sub(pattern, button_audio_script + r'\1', content)
                else:
                    content = re.sub(pattern, r'\1' + button_audio_script + r'\2', content)
                
                # Записываем обновленный файл
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                
                print(f"✅ {file_path} - добавлен button-audio.js")
                return True
        
        print(f"⚠️ {file_path} - не удалось найти подходящее место для вставки")
        return False
        
    except Exception as e:
        print(f"❌ {file_path} - ошибка: {e}")
        return False

def main():
    """Главная функция"""
    print("🔊 Добавление button-audio.js на все HTML страницы...")
    
    # Находим все HTML файлы в папке web
    web_dir = "/Users/aliserromankul/Desktop/smartscrolling/smart_scroll2/web"
    html_files = glob.glob(os.path.join(web_dir, "*.html"))
    
    # Исключаем файлы, которые не нужно обновлять
    exclude_files = [
        'unified-navbar.html',
        'test-audio.html',
        'index.html',  # Flutter приложение
    ]
    
    processed = 0
    success = 0
    
    for html_file in html_files:
        filename = os.path.basename(html_file)
        
        if filename in exclude_files:
            print(f"⏭️ {filename} - пропущен (исключен)")
            continue
        
        processed += 1
        if add_button_audio_to_html(html_file):
            success += 1
    
    print(f"\n📊 Результаты:")
    print(f"Обработано файлов: {processed}")
    print(f"Успешно обновлено: {success}")
    print(f"Ошибок: {processed - success}")
    
    if success > 0:
        print(f"\n🎉 button-audio.js добавлен на {success} страниц!")
        print("Теперь озвучка кнопок будет работать на всех страницах SmartScroll.")
    else:
        print("\n❌ Не удалось добавить button-audio.js ни на одну страницу.")

if __name__ == "__main__":
    main()
