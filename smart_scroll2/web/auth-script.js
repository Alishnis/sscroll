// Auth System
class AuthSystem {
    constructor() {
        this.users = this.loadUsers();
        this.currentUser = this.getCurrentUser();
        this.init();
    }

    init() {
        this.bindEvents();
        this.checkAuth();
    }

    bindEvents() {
        // Registration form
        const registerForm = document.getElementById('registerForm');
        if (registerForm) {
            registerForm.addEventListener('submit', (e) => this.handleRegister(e));
        }

        // Login form
        const loginForm = document.getElementById('loginForm');
        if (loginForm) {
            loginForm.addEventListener('submit', (e) => this.handleLogin(e));
        }

        // Navigation
        this.bindNavigationEvents();
    }

    handleRegister(e) {
        e.preventDefault();
        
        const formData = new FormData(e.target);
        const userData = {
            username: formData.get('username').trim(),
            email: formData.get('email').trim().toLowerCase(),
            password: formData.get('password'),
            confirmPassword: formData.get('confirmPassword')
        };

        // Validation
        const errors = this.validateRegistration(userData);
        if (errors.length > 0) {
            this.showErrors(errors);
            return;
        }

        // Check if user already exists
        if (this.userExists(userData.email)) {
            this.showError('Пользователь с таким email уже существует');
            return;
        }

        // Create user
        const user = {
            id: Date.now().toString(),
            username: userData.username,
            email: userData.email,
            password: this.hashPassword(userData.password),
            createdAt: new Date().toISOString()
        };

        this.users.push(user);
        this.saveUsers();
        
        // Auto login
        this.currentUser = user;
        this.saveCurrentUser();
        
        this.showSuccess('Регистрация успешна! Перенаправление...');
        setTimeout(() => {
            window.location.href = './feed.html';
        }, 1500);
    }

    handleLogin(e) {
        e.preventDefault();
        
        const formData = new FormData(e.target);
        const email = formData.get('email').trim().toLowerCase();
        const password = formData.get('password');

        // Find user
        const user = this.users.find(u => u.email === email);
        if (!user) {
            this.showError('Пользователь не найден');
            return;
        }

        // Check password
        if (!this.verifyPassword(password, user.password)) {
            this.showError('Неверный пароль');
            return;
        }

        // Login
        this.currentUser = user;
        this.saveCurrentUser();
        
        this.showSuccess('Вход выполнен! Перенаправление...');
        setTimeout(() => {
            window.location.href = './feed.html';
        }, 1500);
    }

    validateRegistration(userData) {
        const errors = [];

        if (!userData.username || userData.username.length < 3) {
            errors.push('Никнейм должен содержать минимум 3 символа');
        }

        if (!this.isValidEmail(userData.email)) {
            errors.push('Введите корректный email');
        }

        if (!userData.password || userData.password.length < 6) {
            errors.push('Пароль должен содержать минимум 6 символов');
        }

        if (userData.password !== userData.confirmPassword) {
            errors.push('Пароли не совпадают');
        }

        return errors;
    }

    isValidEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    }

    userExists(email) {
        return this.users.some(user => user.email === email);
    }

    hashPassword(password) {
        // Simple hash for demo purposes
        let hash = 0;
        for (let i = 0; i < password.length; i++) {
            const char = password.charCodeAt(i);
            hash = ((hash << 5) - hash) + char;
            hash = hash & hash; // Convert to 32bit integer
        }
        return hash.toString();
    }

    verifyPassword(password, hashedPassword) {
        return this.hashPassword(password) === hashedPassword;
    }

    showError(message) {
        this.clearMessages();
        const errorDiv = document.createElement('div');
        errorDiv.className = 'error-message show';
        errorDiv.textContent = message;
        
        const form = document.querySelector('.auth-form');
        form.appendChild(errorDiv);
    }

    showErrors(errors) {
        this.clearMessages();
        errors.forEach(error => {
            this.showError(error);
        });
    }

    showSuccess(message) {
        this.clearMessages();
        const successDiv = document.createElement('div');
        successDiv.className = 'success-message show';
        successDiv.textContent = message;
        
        const form = document.querySelector('.auth-form');
        form.appendChild(successDiv);
    }

    clearMessages() {
        const messages = document.querySelectorAll('.error-message, .success-message');
        messages.forEach(msg => msg.remove());
    }

    loadUsers() {
        const users = localStorage.getItem('smartscroll_users');
        return users ? JSON.parse(users) : [];
    }

    saveUsers() {
        localStorage.setItem('smartscroll_users', JSON.stringify(this.users));
    }

    getCurrentUser() {
        const user = localStorage.getItem('smartscroll_current_user');
        return user ? JSON.parse(user) : null;
    }

    saveCurrentUser() {
        if (this.currentUser) {
            localStorage.setItem('smartscroll_current_user', JSON.stringify(this.currentUser));
        } else {
            localStorage.removeItem('smartscroll_current_user');
        }
    }

    logout() {
        this.currentUser = null;
        this.saveCurrentUser();
        window.location.href = './login.html';
    }

    isLoggedIn() {
        return this.currentUser !== null;
    }

    checkAuth() {
        // If user is logged in and on auth pages, redirect to feed
        if (this.isLoggedIn()) {
            const currentPage = window.location.pathname.split('/').pop();
            if (currentPage === 'login.html' || currentPage === 'register.html') {
                window.location.href = './feed.html';
            }
        }
        
        // Show profile information if on profile page
        if (window.location.pathname.includes('profile.html')) {
            this.showProfileInfo();
        }
    }

    showProfileInfo() {
        const userProfile = document.getElementById('user-profile');
        const loginPrompt = document.getElementById('login-prompt');
        
        if (this.isLoggedIn()) {
            const user = this.currentUser;
            
            // Show user profile
            userProfile.style.display = 'block';
            loginPrompt.style.display = 'none';
            
            // Fill profile information
            document.getElementById('profile-username').textContent = user.username;
            document.getElementById('profile-email').textContent = user.email;
            document.getElementById('profile-id').textContent = user.id;
            
            // Format registration date
            const regDate = new Date(user.createdAt);
            document.getElementById('profile-date').textContent = regDate.toLocaleDateString('ru-RU', {
                year: 'numeric',
                month: 'long',
                day: 'numeric'
            });
            
            // Set avatar initial
            const avatarInitial = document.getElementById('avatar-initial');
            avatarInitial.textContent = user.username.charAt(0).toUpperCase();
            
            // Bind logout button
            const logoutBtn = document.getElementById('logout-btn');
            logoutBtn.addEventListener('click', () => {
                this.logout();
            });
        } else {
            // Show login prompt
            userProfile.style.display = 'none';
            loginPrompt.style.display = 'block';
        }
    }

    bindNavigationEvents() {
        const navbarItems = document.querySelectorAll('.navbar__item[data-page]');
        
        navbarItems.forEach(item => {
            item.addEventListener('click', () => {
                const page = item.getAttribute('data-page');
                this.navigateToPage(page);
            });
        });
    }

    navigateToPage(page) {
        // Check if user is logged in for protected pages
        const protectedPages = ['feed', 'posts', 'quiz', 'settings', 'profile'];
        
        if (protectedPages.includes(page) && !this.isLoggedIn()) {
            window.location.href = './login.html';
            return;
        }

        // Navigate to page
        switch(page) {
            case 'feed':
                window.location.href = './feed.html';
                break;
            case 'posts':
                window.location.href = './posts.html';
                break;
            case 'quiz':
                window.location.href = './quiz-template.html';
                break;
            case 'settings':
                window.location.href = './settings.html';
                break;
            case 'profile':
                window.location.href = './profile.html';
                break;
        }
    }
}

// Initialize auth system when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.authSystem = new AuthSystem();
});

// Export for use in other scripts
window.AuthSystem = AuthSystem;
