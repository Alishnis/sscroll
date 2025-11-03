/**
 * Единая навигация для SmartScroll
 * Обеспечивает консистентную навигацию между всеми страницами
 */

// Определение текущей страницы
function getCurrentPage() {
    const path = window.location.pathname;
    const filename = path.split('/').pop();
    
    switch(filename) {
        case 'dashboard.html':
        case 'index.html':
        case '':
            return 'feed'; // Лента как главная страница
        case 'posts.html':
            return 'posts';
        case 'feed.html':
            return 'feed';
        case 'eye-health.html':
            return 'eye-health';
        case 'conference.html':
            return 'conference';
        case 'settings.html':
            return 'settings';
        default:
            return 'feed'; // Лента как главная страница
    }
}

// Инициализация навигации
function initializeNavbar() {
    const currentPage = getCurrentPage();
    
    // Убираем активный класс со всех элементов
    document.querySelectorAll('.nav-item').forEach(item => {
        item.classList.remove('active');
    });
    
    // Добавляем активный класс к текущей странице
    const activeItem = document.querySelector(`[data-page="${currentPage}"]`);
    if (activeItem) {
        activeItem.classList.add('active');
    }
    
    // Добавляем класс для темной темы если нужно
    if (document.body.classList.contains('dark-theme') || 
        document.body.style.background.includes('gradient') ||
        document.body.style.background.includes('#000')) {
        document.body.classList.add('dark-theme');
    }
}

// Навигация между страницами
function navigateTo(page) {
    const pageUrls = {
        'feed': 'feed.html',
        'posts': 'posts.html',
        'eye-health': 'eye-health.html',
        'conference': 'conference.html',
        'settings': 'settings.html'
    };
    
    const url = pageUrls[page];
    if (url && url !== window.location.pathname.split('/').pop()) {
        window.location.href = url;
    }
}

// Обработка кликов по навигации
function handleNavClick(event, page) {
    event.preventDefault();
    navigateTo(page);
}

// Добавление отступа для контента
function addContentPadding() {
    const mainContent = document.querySelector('.container, .feed-container, .posts-container, main');
    if (mainContent && !mainContent.classList.contains('content-with-navbar')) {
        mainContent.classList.add('content-with-navbar');
    }
}

// Инициализация при загрузке страницы
document.addEventListener('DOMContentLoaded', function() {
    initializeNavbar();
    addContentPadding();
});

// Экспорт функций для глобального использования
window.navigateTo = navigateTo;
window.handleNavClick = handleNavClick;
window.getCurrentPage = getCurrentPage;
