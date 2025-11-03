/**
 * БЕЗОПАСНАЯ ВЕРСИЯ script.js
 * Полностью защищена от ошибок classList
 */

console.log('🛡️ Загрузка безопасной версии script.js');

// Проверяем наличие необходимых элементов при загрузке
function checkRequiredElements() {
    const sidebarContent = document.querySelector('.sidebar-content');
    const rightSidebar = document.querySelector('.right-sidebar');
    const content = document.querySelector('.content');
    
    console.log('🔍 Проверка элементов:', {
        sidebarContent: !!sidebarContent,
        rightSidebar: !!rightSidebar,
        content: !!content
    });
    
    return {
        hasSidebar: !!sidebarContent,
        hasRightSidebar: !!rightSidebar,
        hasContent: !!content
    };
}

// Безопасная функция для работы с classList
function safeClassListOperation(element, operation, className) {
    if (!element) {
        console.warn('⚠️ Элемент не найден для операции classList');
        return false;
    }
    
    if (!element.classList) {
        console.warn('⚠️ У элемента нет classList');
        return false;
    }
    
    try {
        switch(operation) {
            case 'add':
                element.classList.add(className);
                return true;
            case 'remove':
                element.classList.remove(className);
                return true;
            case 'toggle':
                element.classList.toggle(className);
                return true;
            case 'contains':
                return element.classList.contains(className);
            default:
                console.warn('⚠️ Неизвестная операция classList:', operation);
                return false;
        }
    } catch (error) {
        console.error('❌ Ошибка в операции classList:', error);
        return false;
    }
}

// Безопасная версия showSidebarContent
function showSidebarContent(type) {
    console.log('🔍 showSidebarContent (безопасная версия) вызвана с типом:', type);
    
    const elements = checkRequiredElements();
    
    if (!elements.hasSidebar || !elements.hasContent) {
        console.warn('⚠️ Не найдены необходимые элементы для sidebar');
        return;
    }
    
    const sidebarContent = document.querySelector('.sidebar-content');
    const contentContainer = document.querySelector('.content');
    const summaryCard = document.getElementById('summaryCard');
    const notesCard = document.getElementById('notesCard');
    const quizCard = document.getElementById('quizCard');
    
    // Безопасное скрытие всех карточек
    [summaryCard, notesCard, quizCard].forEach(card => {
        if (card && card.style) {
            card.style.display = 'none';
        }
    });
    
    // Показываем выбранную карточку
    let targetCard = null;
    if (type === 'summary' && summaryCard) {
        targetCard = summaryCard;
    } else if (type === 'notes' && notesCard) {
        targetCard = notesCard;
    } else if (type === 'quiz' && quizCard) {
        targetCard = quizCard;
    }
    
    if (targetCard) {
        targetCard.style.display = 'flex';
        safeClassListOperation(sidebarContent, 'add', 'sidebar-content--expanded');
        safeClassListOperation(contentContainer, 'add', 'content--sidebar-open');
        console.log(`✅ ${type} card показан`);
    } else {
        console.warn('⚠️ Не найдена карточка для типа:', type);
    }
}

// Безопасная версия hideSidebarContent
function hideSidebarContent() {
    console.log('🔍 hideSidebarContent (безопасная версия) вызвана');
    
    const elements = checkRequiredElements();
    
    if (!elements.hasSidebar || !elements.hasContent) {
        console.warn('⚠️ Не найдены необходимые элементы для скрытия sidebar');
        return;
    }
    
    const sidebarContent = document.querySelector('.sidebar-content');
    const contentContainer = document.querySelector('.content');
    
    safeClassListOperation(sidebarContent, 'remove', 'sidebar-content--expanded');
    safeClassListOperation(contentContainer, 'remove', 'content--sidebar-open');
    
    console.log('✅ Sidebar скрыт безопасно');
}

// Инициализация только если элементы найдены
function initSafeScript() {
    console.log('🚀 Инициализация безопасного script.js');
    
    const elements = checkRequiredElements();
    
    if (!elements.hasSidebar && !elements.hasRightSidebar) {
        console.log('ℹ️ Sidebar элементы не найдены, пропускаем инициализацию');
        return;
    }
    
    // Безопасный обработчик клика
    document.addEventListener('click', function(event) {
        try {
            const sidebarContent = document.querySelector('.sidebar-content');
            const rightSidebar = document.querySelector('.right-sidebar');
            
            if (!sidebarContent || !rightSidebar) {
                return;
            }
            
            const isExpanded = safeClassListOperation(sidebarContent, 'contains', 'sidebar-content--expanded');
            
            if (isExpanded && 
                !sidebarContent.contains(event.target) && 
                !rightSidebar.contains(event.target)) {
                hideSidebarContent();
            }
        } catch (error) {
            console.error('❌ Ошибка в обработчике клика:', error);
        }
    });
    
    console.log('✅ Безопасный script.js инициализирован');
}

// Инициализация при загрузке DOM
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initSafeScript);
} else {
    initSafeScript();
}

// Экспорт функций для глобального использования
window.showSidebarContent = showSidebarContent;
window.hideSidebarContent = hideSidebarContent;
window.safeClassListOperation = safeClassListOperation;

console.log('✅ Безопасная версия script.js загружена');
