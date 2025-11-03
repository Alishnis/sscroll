/**
 * Скрипт для автоматического обновления всех HTML файлов
 * Добавляет единый навбар во все страницы
 */

const fs = require('fs');
const path = require('path');

// Список HTML файлов для обновления
const htmlFiles = [
    'smart-shop.html',
    'quiz-template.html',
    'profile.html',
    'eye-health.html',
    'conference.html',
    'conference-template-new.html',
    'login.html',
    'register.html',
    'home.html',
    'smart-demo.html'
];

// Функция для добавления единого навбара в HTML файл
function updateHtmlFile(filePath) {
    try {
        let content = fs.readFileSync(filePath, 'utf8');
        
        // Проверяем, есть ли уже единый навбар
        if (content.includes('unified-navbar.css') && content.includes('unified-navbar.js')) {
            console.log(`✅ ${filePath} уже обновлен`);
            return;
        }
        
        // Добавляем CSS и JS ссылки в head
        const cssLink = '    <link rel="stylesheet" href="unified-navbar.css">\n    <script src="unified-navbar.js"></script>';
        
        // Ищем место для вставки (после template-styles.css или в head)
        if (content.includes('template-styles.css')) {
            content = content.replace(
                '    <link rel="stylesheet" href="template-styles.css">',
                '    <link rel="stylesheet" href="template-styles.css">\n    \n    <!-- Единая навигация -->\n    <link rel="stylesheet" href="unified-navbar.css">\n    <script src="unified-navbar.js"></script>'
            );
        } else if (content.includes('<head>')) {
            content = content.replace(
                '<head>',
                '<head>\n    <!-- Единая навигация -->\n    <link rel="stylesheet" href="unified-navbar.css">\n    <script src="unified-navbar.js"></script>'
            );
        }
        
        // Заменяем существующие header и navbar на единый навбар
        const headerRegex = /<!-- Header -->[\s\S]*?<\/header>/g;
        const navbarRegex = /<!-- Navigation -->[\s\S]*?<\/nav>/g;
        
        content = content.replace(headerRegex, '        <!-- Единый навбар -->\n        <div id="unified-navbar-container"></div>');
        content = content.replace(navbarRegex, '');
        
        // Добавляем JavaScript для загрузки единого навбара
        const navbarScript = `
    <!-- Загрузка единого навбара -->
    <script>
        // Загружаем единый навбар
        fetch('unified-navbar.html')
            .then(response => response.text())
            .then(html => {
                document.getElementById('unified-navbar-container').innerHTML = html;
                // Инициализируем навбар после загрузки
                if (window.initializeNavbar) {
                    window.initializeNavbar();
                }
            })
            .catch(error => {
                console.error('Ошибка загрузки единого навбара:', error);
            });
    </script>`;
        
        // Добавляем скрипт перед закрывающим </body> или перед последним </script>
        if (content.includes('</body>')) {
            content = content.replace('</body>', navbarScript + '\n</body>');
        } else if (content.includes('</html>')) {
            content = content.replace('</html>', navbarScript + '\n</html>');
        }
        
        // Сохраняем обновленный файл
        fs.writeFileSync(filePath, content, 'utf8');
        console.log(`✅ Обновлен: ${filePath}`);
        
    } catch (error) {
        console.error(`❌ Ошибка при обновлении ${filePath}:`, error.message);
    }
}

// Обновляем все HTML файлы
console.log('🚀 Начинаем обновление HTML файлов...');

htmlFiles.forEach(file => {
    const filePath = path.join(__dirname, file);
    if (fs.existsSync(filePath)) {
        updateHtmlFile(filePath);
    } else {
        console.log(`⚠️  Файл не найден: ${file}`);
    }
});

console.log('✅ Обновление завершено!');
