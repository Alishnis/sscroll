// Smart Scroll Application JavaScript

document.addEventListener('DOMContentLoaded', function() {
    // Initialize the application
    initNavbar();
    initRightSidebar();
    initVideoActions();
    initScrollAnimation();
    initModals();
});

// Navbar functionality
function initNavbar() {
    const navbarItems = document.querySelectorAll('.navbar__item');
    
    navbarItems.forEach(item => {
        item.addEventListener('click', function() {
            // Remove active class from all items
            navbarItems.forEach(navItem => {
                navItem.classList.remove('navbar__item--active');
            });
            
            // Add active class to clicked item
            this.classList.add('navbar__item--active');
            
            // Add click animation
            this.style.transform = 'scale(0.95)';
            setTimeout(() => {
                this.style.transform = 'scale(1)';
            }, 150);
        });
    });
}


// Right Sidebar functionality
function initRightSidebar() {
    const rightSidebarItems = document.querySelectorAll('.right-sidebar__item');
    
    rightSidebarItems.forEach(item => {
        item.addEventListener('click', function() {
            const action = this.getAttribute('data-action');
            
            // Remove active class from all items
            rightSidebarItems.forEach(sidebarItem => {
                sidebarItem.classList.remove('right-sidebar__item--active');
            });
            
            // Add active class to clicked item
            this.classList.add('right-sidebar__item--active');
            
            // Add click animation
            this.style.transform = 'scale(0.95)';
            setTimeout(() => {
                this.style.transform = '';
            }, 150);
            
            // Handle different actions
            switch(action) {
                case 'content':
                    showNotification('Открывается содержание...');
                    showSidebarContent('summary');
                    break;
                case 'quiz':
                    showNotification('Открывается квиз...');
                    showSidebarContent('quiz');
                    break;
                case 'notes':
                    showNotification('Открываются заметки...');
                    showSidebarContent('notes');
                    break;
            }
        });
    });
}

// Video card actions
function initVideoActions() {
    const actions = document.querySelectorAll('.video-card__action');
    
    actions.forEach(action => {
        action.addEventListener('click', function() {
            // Add visual feedback
            this.style.transform = 'scale(0.95)';
            setTimeout(() => {
                this.style.transform = 'scale(1)';
            }, 150);
            
            // Handle different actions (excluding summary and quiz which are handled by modals)
            if (this.classList.contains('video-card__action--likes')) {
                handleLike(this);
            } else if (this.classList.contains('video-card__action--share')) {
                handleShare();
            } else if (this.classList.contains('video-card__action--source')) {
                handleSource();
            }
            // Note: summary and quiz actions are handled by initModals()
        });
    });
}

// Handle like button
function handleLike(button) {
    const textElement = button.querySelector('.video-card__action-text');
    const currentValue = textElement.textContent;
    
    // Toggle like state
    if (button.dataset.liked === 'true') {
        button.dataset.liked = 'false';
        button.style.opacity = '1';
    } else {
        button.dataset.liked = 'true';
        button.style.opacity = '0.8';
        
        // Add animation
        const icon = button.querySelector('.video-card__action-icon');
        icon.style.animation = 'pulse 0.3s ease';
        setTimeout(() => {
            icon.style.animation = '';
        }, 300);
    }
}

// Handle share button
function handleShare() {
    if (navigator.share) {
        navigator.share({
            title: 'Smart Scroll',
            text: 'Посмотрите это видео в Smart Scroll!',
            url: window.location.href
        }).catch(err => console.log('Ошибка при попытке поделиться:', err));
    } else {
        // Fallback: copy to clipboard
        const url = window.location.href;
        navigator.clipboard.writeText(url).then(() => {
            showNotification('Ссылка скопирована!');
        });
    }
}

// Handle source button
function handleSource() {
    showNotification('Открывается источник...');
    // Here you would typically open the source link
}

// Modal management functions
function openModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.style.display = 'block';
        document.body.style.overflow = 'hidden'; // Prevent background scrolling
    }
}

function closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.style.display = 'none';
        document.body.style.overflow = 'auto'; // Restore scrolling
    }
}

// Show notification
function showNotification(message) {
    // Create notification element
    const notification = document.createElement('div');
    notification.className = 'notification';
    notification.textContent = message;
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background-color: #30CAA1;
        color: #FFFFFF;
        padding: 16px 24px;
        border-radius: 8px;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
        z-index: 1000;
        animation: slideIn 0.3s ease;
    `;
    
    document.body.appendChild(notification);
    
    // Remove after 3 seconds
    setTimeout(() => {
        notification.style.animation = 'slideOut 0.3s ease';
        setTimeout(() => {
            notification.remove();
        }, 300);
    }, 3000);
}

// Scroll animation for video cards
function initScrollAnimation() {
    const videoCard = document.querySelector('.video-card');
    
    if (videoCard) {
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.style.animation = 'fadeInUp 0.6s ease';
                }
            });
        }, { threshold: 0.1 });
        
        observer.observe(videoCard);
    }
}

// Add CSS animations dynamically
const style = document.createElement('style');
style.textContent = `
    @keyframes pulse {
        0%, 100% { transform: scale(1); }
        50% { transform: scale(1.2); }
    }
    
    @keyframes slideIn {
        from {
            transform: translateX(100%);
            opacity: 0;
        }
        to {
            transform: translateX(0);
            opacity: 1;
        }
    }
    
    @keyframes slideOut {
        from {
            transform: translateX(0);
            opacity: 1;
        }
        to {
            transform: translateX(100%);
            opacity: 0;
        }
    }
    
    @keyframes fadeInUp {
        from {
            transform: translateY(20px);
            opacity: 0;
        }
        to {
            transform: translateY(0);
            opacity: 1;
        }
    }
`;
document.head.appendChild(style);

// Smooth scrolling
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Initialize modal functionality
function initModals() {
    // Close modal when clicking outside
    window.addEventListener('click', function(event) {
        if (event.target.classList.contains('modal')) {
            event.target.style.display = 'none';
            document.body.style.overflow = 'auto';
        }
    });
    
    // Close sidebar when clicking outside
    document.addEventListener('click', function(event) {
        const sidebarContent = document.querySelector('.sidebar-content');
        const rightSidebar = document.querySelector('.right-sidebar');
        
        if (sidebarContent && rightSidebar && 
            sidebarContent.classList.contains('sidebar-content--expanded') && 
            !sidebarContent.contains(event.target) && 
            !rightSidebar.contains(event.target)) {
            hideSidebarContent();
        }
    });
    
    // Close modal with Escape key
    document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape') {
            const openModals = document.querySelectorAll('.modal[style*="block"]');
            openModals.forEach(modal => {
                modal.style.display = 'none';
                document.body.style.overflow = 'auto';
            });
        }
    });
    
    // Add click handlers for sidebar content buttons
    const summaryButtons = document.querySelectorAll('.video-card__action--summary');
    const notesButtons = document.querySelectorAll('.video-card__action--notes');
    const quizButtons = document.querySelectorAll('.video-card__action--quiz');
    
    summaryButtons.forEach(button => {
        button.addEventListener('click', function(e) {
            e.preventDefault();
            showSidebarContent('summary');
        });
    });
    
    notesButtons.forEach(button => {
        button.addEventListener('click', function(e) {
            e.preventDefault();
            showSidebarContent('notes');
        });
    });
    
    quizButtons.forEach(button => {
        button.addEventListener('click', function(e) {
            e.preventDefault();
            showSidebarContent('quiz');
        });
    });
    
    // Add click handler for notes card to focus textarea
    const notesCard = document.getElementById('notesCard');
    if (notesCard) {
        notesCard.addEventListener('click', function(e) {
            const textarea = notesCard.querySelector('.notes-card__textarea');
            if (textarea && e.target !== textarea) {
                textarea.focus();
            }
        });
    }
}

// Show content in sidebar
function showSidebarContent(type) {
    const sidebarContent = document.querySelector('.sidebar-content');
    const summaryCard = document.getElementById('summaryCard');
    const notesCard = document.getElementById('notesCard');
    const quizCard = document.getElementById('quizCard');
    const contentContainer = document.querySelector('.content');
    
    // Hide all cards first
    if (summaryCard) summaryCard.style.display = 'none';
    if (notesCard) notesCard.style.display = 'none';
    if (quizCard) quizCard.style.display = 'none';
    
    // Show the selected card and expand the sidebar
    if (type === 'summary' && summaryCard && sidebarContent && contentContainer) {
        summaryCard.style.display = 'flex';
        sidebarContent.classList.add('sidebar-content--expanded');
        contentContainer.classList.add('content--sidebar-open');
    } else if (type === 'notes' && notesCard && sidebarContent && contentContainer) {
        notesCard.style.display = 'flex';
        sidebarContent.classList.add('sidebar-content--expanded');
        contentContainer.classList.add('content--sidebar-open');
        // Auto-focus the textarea when notes card is shown
        setTimeout(() => {
            const textarea = notesCard.querySelector('.notes-card__textarea');
            if (textarea) {
                textarea.focus();
            }
        }, 100);
    } else if (type === 'quiz' && quizCard && sidebarContent && contentContainer) {
        quizCard.style.display = 'flex';
        sidebarContent.classList.add('sidebar-content--expanded');
        contentContainer.classList.add('content--sidebar-open');
    }
}

// Hide sidebar content
function hideSidebarContent() {
    const sidebarContent = document.querySelector('.sidebar-content');
    const contentContainer = document.querySelector('.content');
    
    if (sidebarContent) {
        sidebarContent.classList.remove('sidebar-content--expanded');
    }
    if (contentContainer) {
        contentContainer.classList.remove('content--sidebar-open');
    }
}
