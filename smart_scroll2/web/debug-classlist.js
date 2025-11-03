/**
 * Отладочный скрипт для поиска проблем с classList
 * Помогает найти все места, где может возникнуть ошибка "Cannot read properties of null (reading 'classList')"
 */

console.log('🔍 Запуск отладочного скрипта для classList');

// Перехватываем все ошибки JavaScript
window.addEventListener('error', function(event) {
    if (event.message.includes('classList')) {
        console.error('❌ ОШИБКА classList:', {
            message: event.message,
            filename: event.filename,
            lineno: event.lineno,
            colno: event.colno,
            stack: event.error ? event.error.stack : 'Stack недоступен'
        });
        
        // Показываем уведомление пользователю
        showDebugNotification('Ошибка classList обнаружена! Проверьте консоль.');
    }
});

// Функция для безопасного обращения к classList
function safeClassList(element, action, className) {
    if (!element) {
        console.warn('⚠️ Попытка обращения к classList null элемента:', {
            action: action,
            className: className,
            stack: new Error().stack
        });
        return false;
    }
    
    if (!element.classList) {
        console.warn('⚠️ У элемента нет classList:', element);
        return false;
    }
    
    try {
        switch(action) {
            case 'add':
                element.classList.add(className);
                break;
            case 'remove':
                element.classList.remove(className);
                break;
            case 'toggle':
                element.classList.toggle(className);
                break;
            case 'contains':
                return element.classList.contains(className);
            default:
                console.warn('⚠️ Неизвестное действие classList:', action);
                return false;
        }
        return true;
    } catch (error) {
        console.error('❌ Ошибка при работе с classList:', error);
        return false;
    }
}

// Перехватываем все обращения к classList
const originalQuerySelector = document.querySelector;
const originalQuerySelectorAll = document.querySelectorAll;

document.querySelector = function(selector) {
    const element = originalQuerySelector.call(this, selector);
    
    if (element && element.classList) {
        // Создаем прокси для отслеживания обращений к classList
        return new Proxy(element, {
            get(target, prop) {
                if (prop === 'classList') {
                    console.log('🔍 Обращение к classList элемента:', {
                        selector: selector,
                        element: target,
                        stack: new Error().stack.split('\n').slice(1, 4).join('\n')
                    });
                }
                return target[prop];
            }
        });
    }
    
    return element;
};

document.querySelectorAll = function(selector) {
    const elements = originalQuerySelectorAll.call(this, selector);
    
    return Array.from(elements).map(element => {
        if (element && element.classList) {
            return new Proxy(element, {
                get(target, prop) {
                    if (prop === 'classList') {
                        console.log('🔍 Обращение к classList элемента в коллекции:', {
                            selector: selector,
                            element: target,
                            stack: new Error().stack.split('\n').slice(1, 4).join('\n')
                        });
                    }
                    return target[prop];
                }
            });
        }
        return element;
    });
};

// Функция для проверки всех потенциально проблемных элементов
function checkProblematicElements() {
    console.log('🔍 Проверка потенциально проблемных элементов...');
    
    const selectors = [
        '.sidebar-content',
        '.right-sidebar', 
        '.content',
        '.navbar__item',
        '.navbar__dropdown-menu',
        '.modal',
        '.video-card',
        '.quiz-card',
        '.notes-card',
        '.summary-card'
    ];
    
    selectors.forEach(selector => {
        const elements = document.querySelectorAll(selector);
        console.log(`📋 Селектор "${selector}": найдено ${elements.length} элементов`);
        
        elements.forEach((element, index) => {
            if (!element) {
                console.warn(`⚠️ Элемент ${index} для селектора "${selector}" равен null`);
            } else if (!element.classList) {
                console.warn(`⚠️ У элемента ${index} для селектора "${selector}" нет classList`);
            }
        });
    });
}

// Функция для мониторинга событий
function monitorEvents() {
    console.log('👂 Мониторинг событий...');
    
    // Отслеживаем клики
    document.addEventListener('click', function(event) {
        const target = event.target;
        if (target && target.classList) {
            console.log('🖱️ Клик по элементу с classList:', {
                element: target,
                classes: Array.from(target.classList),
                tagName: target.tagName
            });
        }
    });
    
    // Отслеживаем наведение мыши
    document.addEventListener('mouseenter', function(event) {
        const target = event.target;
        if (target && target.classList) {
            console.log('🖱️ Наведение на элемент с classList:', {
                element: target,
                classes: Array.from(target.classList),
                tagName: target.tagName
            });
        }
    });
}

// Функция для показа уведомлений
function showDebugNotification(message) {
    // Создаем уведомление
    const notification = document.createElement('div');
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: #ff4444;
        color: white;
        padding: 15px 20px;
        border-radius: 8px;
        z-index: 10000;
        font-family: Arial, sans-serif;
        font-size: 14px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.3);
        max-width: 300px;
    `;
    notification.textContent = message;
    
    document.body.appendChild(notification);
    
    // Убираем уведомление через 5 секунд
    setTimeout(() => {
        if (notification.parentNode) {
            notification.parentNode.removeChild(notification);
        }
    }, 5000);
}

// Функция для создания отчета
function generateDebugReport() {
    console.log('📊 Генерация отчета об отладке...');
    
    const report = {
        timestamp: new Date().toISOString(),
        url: window.location.href,
        userAgent: navigator.userAgent,
        problematicElements: [],
        allElements: []
    };
    
    // Проверяем все элементы на странице
    const allElements = document.querySelectorAll('*');
    allElements.forEach((element, index) => {
        if (!element.classList) {
            report.problematicElements.push({
                index: index,
                tagName: element.tagName,
                id: element.id,
                className: element.className,
                reason: 'Нет classList'
            });
        }
        
        report.allElements.push({
            index: index,
            tagName: element.tagName,
            id: element.id,
            className: element.className,
            hasClassList: !!element.classList
        });
    });
    
    console.log('📊 Отчет об отладке:', report);
    return report;
}

// Инициализация отладки
function initDebug() {
    console.log('🚀 Инициализация отладочного скрипта...');
    
    // Проверяем элементы после загрузки DOM
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function() {
            checkProblematicElements();
            monitorEvents();
        });
    } else {
        checkProblematicElements();
        monitorEvents();
    }
    
    // Добавляем глобальные функции для отладки
    window.debugClassList = {
        checkElements: checkProblematicElements,
        generateReport: generateDebugReport,
        safeClassList: safeClassList,
        showNotification: showDebugNotification
    };
    
    console.log('✅ Отладочный скрипт инициализирован');
    console.log('💡 Используйте window.debugClassList для доступа к функциям отладки');
}

// Запускаем отладку
initDebug();

// Экспортируем функции для использования в других скриптах
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        safeClassList,
        checkProblematicElements,
        generateDebugReport,
        initDebug
    };
}
