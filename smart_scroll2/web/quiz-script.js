// Quiz functionality for Smart Scroll template

class QuizApp {
    constructor() {
        this.currentCategory = null;
        this.questions = [];
        this.currentQuestionIndex = 0;
        this.score = 0;
        this.userAnswers = [];
        this.allCategories = [];
        this.filteredCategories = [];
        this.searchQuery = '';
        this.selectedFilter = null;
        this.suggestionIndex = -1;
        
        // Statistics
        this.quizHistory = JSON.parse(localStorage.getItem('quizHistory') || '[]');
        this.categoryStats = JSON.parse(localStorage.getItem('categoryStats') || '{}');
        
        this.initializeElements();
        this.loadCategories();
        this.bindEvents();
        this.initializeSmartCurrency();
    }

    initializeElements() {
        // Main sections
        this.categorySelection = document.getElementById('category-selection');
        this.quizSection = document.getElementById('quiz-section');
        
        // Category selection elements
        this.categoriesGrid = document.getElementById('categories-grid');
        this.searchInput = document.getElementById('search-input');
        this.searchSuggestions = document.getElementById('search-suggestions');
        this.filterTags = document.getElementById('filter-tags');
        this.questionsCountSelect = document.getElementById('questions-count');
        
        
        // Quiz elements
        this.quizTitle = document.getElementById('quiz-title');
        this.currentQuestionSpan = document.getElementById('current-question');
        this.totalQuestionsSpan = document.getElementById('total-questions');
        this.questionText = document.getElementById('question-text');
        this.answersContainer = document.getElementById('answers-container');
        this.nextQuestionBtn = document.getElementById('next-question');
        this.prevQuestionBtn = document.getElementById('prev-question');
        this.finishQuizBtn = document.getElementById('finish-quiz');
        this.questionsGrid = document.getElementById('questions-grid');
        
    }

    loadCategories() {
        try {
            if (typeof getCategories !== 'function') {
                throw new Error('Функция getCategories не найдена');
            }
            
            const categories = getCategories();
            this.allCategories = categories;
            this.filteredCategories = [...categories];
            this.displayCategories(categories);
            this.displayFilterTags();
        } catch (error) {
            console.error('Ошибка загрузки категорий:', error);
            this.displayError('Не удалось загрузить категории: ' + error.message);
        }
    }

    displayCategories(categories) {
        // Скрываем сетку категорий - они не нужны
        this.categoriesGrid.innerHTML = '';
        this.categoriesGrid.style.display = 'none';
    }

    displayFilterTags() {
        // Скрываем фильтры - они не нужны
        this.filterTags.innerHTML = '';
        this.filterTags.style.display = 'none';
    }

    selectFilter(category, element) {
        // Убираем активный класс со всех тегов
        this.filterTags.querySelectorAll('.filter-tag').forEach(tag => {
            tag.classList.remove('active');
        });
        
        // Добавляем активный класс к выбранному тегу
        element.classList.add('active');
        
        this.selectedFilter = category;
        this.searchInput.value = '';
        this.hideSuggestions();
        this.filterCategories();
    }

    clearFilter() {
        this.selectedFilter = null;
        this.searchInput.value = '';
        this.filterTags.querySelectorAll('.filter-tag').forEach(tag => {
            tag.classList.remove('active');
        });
        this.hideSuggestions();
        this.filterCategories();
    }

    filterCategories() {
        let filtered = [...this.allCategories];
        
        // Применяем фильтр по категории
        if (this.selectedFilter) {
            filtered = filtered.filter(category => category === this.selectedFilter);
        }
        
        // Применяем поисковый запрос
        if (this.searchQuery) {
            const query = this.searchQuery.toLowerCase();
            filtered = filtered.filter(category => {
                const translated = this.translateCategory(category).toLowerCase();
                return translated.includes(query) || category.toLowerCase().includes(query);
            });
        }
        
        this.filteredCategories = filtered;
        this.displayCategories(filtered);
    }

    displaySearchResultsInfo(count) {
        // Не показываем информацию о результатах поиска
        return;
    }

    displayNoResults() {
        // Не показываем сообщение "ничего не найдено"
        return;
    }

    showSuggestions() {
        // Показываем все категории при клике на поиск или при вводе
        let suggestions;
        
        if (!this.searchQuery || this.searchQuery.length === 0) {
            // Показываем все категории
            suggestions = this.allCategories.map(category => ({
                category,
                translated: this.translateCategory(category)
            }));
        } else {
            // Фильтруем по поисковому запросу
            suggestions = this.allCategories
                .map(category => ({
                    category,
                    translated: this.translateCategory(category)
                }))
                .filter(item => 
                    item.translated.toLowerCase().includes(this.searchQuery.toLowerCase()) ||
                    item.category.toLowerCase().includes(this.searchQuery.toLowerCase())
                );
        }
        
        if (suggestions.length === 0) {
            this.hideSuggestions();
            return;
        }
        
        this.searchSuggestions.innerHTML = '';
        suggestions.forEach((suggestion, index) => {
            const suggestionElement = document.createElement('div');
            suggestionElement.className = 'suggestion-item';
            
            // Добавляем иконку для категории
            const icon = this.getCategoryIcon(suggestion.category);
            suggestionElement.innerHTML = `${icon} ${suggestion.translated}`;
            
            suggestionElement.onclick = () => this.selectSuggestion(suggestion.category);
            this.searchSuggestions.appendChild(suggestionElement);
        });
        
        this.searchSuggestions.classList.remove('hidden');
    }

    hideSuggestions() {
        this.searchSuggestions.classList.add('hidden');
        this.suggestionIndex = -1;
    }

    selectSuggestion(category) {
        this.searchInput.value = this.translateCategory(category);
        this.searchQuery = this.searchInput.value;
        this.hideSuggestions();
        this.clearFilter();
        this.filterCategories();
        // Запускаем квиз сразу после выбора категории
        this.startQuiz(category);
    }

    translateCategory(category) {
        const translations = {
            'general': 'Общие знания',
            'science-technology': 'Наука и технологии',
            'history': 'История',
            'geography': 'География',
            'literature': 'Литература',
            'music': 'Музыка',
            'movies': 'Кино',
            'sports': 'Спорт',
            'animals': 'Животные',
            'entertainment': 'Развлечения',
            'television': 'Телевидение',
            'video-games': 'Видеоигры',
            'celebrities': 'Знаменитости',
            'people': 'Люди',
            'world': 'Мир',
            'brain-teasers': 'Головоломки',
            'for-kids': 'Для детей',
            'hobbies': 'Хобби',
            'humanities': 'Гуманитарные науки',
            'religion-faith': 'Религия и вера',
            'newest': 'Новейшие',
            'rated': 'Рейтинговые'
        };
        
        return translations[category] || category;
    }

    getCategoryIcon(category) {
        const icons = {
            'general': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" style="width: 16px; height: 16px;"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg>',
            'science-technology': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" style="width: 16px; height: 16px;"><path d="M9.5 3A6.5 6.5 0 0 1 16 9.5c0 1.61-.59 3.09-1.56 4.23l.27.27h.79l5 5-1.5 1.5-5-5v-.79l-.27-.27A6.516 6.516 0 0 1 9.5 16 6.5 6.5 0 0 1 3 9.5 6.5 6.5 0 0 1 9.5 3m0 2C7 5 5 7 5 9.5S7 14 9.5 14 14 12 14 9.5 12 5 9.5 5z"/></svg>',
            'history': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" style="width: 16px; height: 16px;"><path d="M13.5 8H12v5l4.28 2.54.72-1.21-3.5-2.08V8M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2m0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8"/></svg>',
            'geography': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" style="width: 16px; height: 16px;"><path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/></svg>',
            'literature': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" style="width: 16px; height: 16px;"><path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zM9 17H7v-7h2v7zm4 0h-2V7h2v10zm4 0h-2v-4h2v4z"/></svg>',
            'music': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" style="width: 16px; height: 16px;"><path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z"/></svg>',
            'movies': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" style="width: 16px; height: 16px;"><path d="M18 4l2 4h-3l-2-4h-2l2 4h-3l-2-4H8l2 4H7L5 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V4h-4z"/></svg>',
            'sports': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" style="width: 16px; height: 16px;"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg>',
            'animals': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" style="width: 16px; height: 16px;"><path d="M4.5 12.75a6 6 0 0 1 6-6h3a6 6 0 0 1 6 6v5.25a.75.75 0 0 1-.75.75h-13.5a.75.75 0 0 1-.75-.75v-5.25Z"/></svg>',
            'entertainment': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" style="width: 16px; height: 16px;"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg>',
            'television': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" style="width: 16px; height: 16px;"><path d="M21 3H3c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h5l-1 1v1h8v-1l-1-1h5c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 12H3V5h18v10z"/></svg>',
            'video-games': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" style="width: 16px; height: 16px;"><path d="M21 6H3c-1.1 0-2 .9-2 2v8c0 1.1.9 2 2 2h18c1.1 0 2-.9 2-2V8c0-1.1-.9-2-2-2zm0 10H3V8h18v8z"/></svg>',
            'celebrities': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" style="width: 16px; height: 16px;"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>',
            'people': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" style="width: 16px; height: 16px;"><path d="M16 4c0-1.11.89-2 2-2s2 .89 2 2-.89 2-2 2-2-.89-2-2zm4 18v-6h2.5l-2.54-7.63A1.5 1.5 0 0 0 18.54 8H17c-.8 0-1.54.37-2.01.99L14 10.5 11.5 8.99A2.5 2.5 0 0 0 9.5 8H7.46c-.8 0-1.54.37-2.01.99L4 10.5 2.5 8.99A2.5 2.5 0 0 0 .5 8v10h2v6h4v-6h2v6h4v-6h2v6h4z"/></svg>',
            'world': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" style="width: 16px; height: 16px;"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 17.93c-3.94-.49-7-3.85-7-7.93 0-.62.08-1.21.21-1.79L9 15v1c0 1.1.9 2 2 2v1.93zm6.9-2.54c-.26-.81-1-1.39-1.9-1.39h-1v-3c0-.55-.45-1-1-1H8v-2h2c.55 0 1-.45 1-1V7h2c1.1 0 2-.9 2-2v-.41c2.93 1.19 5 4.06 5 7.41 0 2.08-.8 3.97-2.1 5.39z"/></svg>',
            'brain-teasers': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" style="width: 16px; height: 16px;"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg>',
            'for-kids': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" style="width: 16px; height: 16px;"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg>',
            'hobbies': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" style="width: 16px; height: 16px;"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>',
            'humanities': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" style="width: 16px; height: 16px;"><path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-5 14H7v-2h7v2zm3-4H7v-2h10v2zm0-4H7V7h10v2z"/></svg>',
            'religion-faith': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" style="width: 16px; height: 16px;"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>',
            'newest': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" style="width: 16px; height: 16px;"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg>',
            'rated': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" style="width: 16px; height: 16px;"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>'
        };
        
        return icons[category] || '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" style="width: 16px; height: 16px;"><path d="M14,2H6A2,2 0 0,0 4,4V20A2,2 0 0,0 6,22H18A2,2 0 0,0 20,20V8L14,2M18,20H6V4H13V9H18V20Z"/></svg>';
    }

    startQuiz(category) {
        this.currentCategory = category;
        this.showLoading();
        
        try {
            const questionsCount = parseInt(this.questionsCountSelect.value);
            const questions = getRandomQuestions(category, questionsCount);
            
            if (questions.length === 0) {
                this.displayError('В этой категории нет вопросов');
                return;
            }
            
            this.questions = questions;
            this.currentQuestionIndex = 0;
            this.score = 0;
            this.userAnswers = [];
            
            this.showQuiz();
            this.displayQuestion();
        } catch (error) {
            console.error('Ошибка загрузки вопросов:', error);
            this.displayError('Не удалось загрузить вопросы');
        }
    }

    showLoading() {
        this.categoriesGrid.innerHTML = `
            <div class="loading">
                <div class="spinner"></div>
                <p>Загрузка вопросов...</p>
            </div>
        `;
    }

    showQuiz() {
        this.categorySelection.classList.add('hidden');
        this.quizSection.classList.remove('hidden');
        
        this.quizTitle.textContent = this.translateCategory(this.currentCategory);
        this.totalQuestionsSpan.textContent = this.questions.length;
        
        // Создаем навигацию по вопросам
        this.createQuestionNavigation();
    }

    displayQuestion() {
        const question = this.questions[this.currentQuestionIndex];
        this.currentQuestionSpan.textContent = this.currentQuestionIndex + 1;
        this.questionText.textContent = question.question;
        
        this.answersContainer.innerHTML = '';
        
        question.options.forEach((option, index) => {
            const answerElement = document.createElement('div');
            answerElement.className = 'answer-option';
            answerElement.textContent = option;
            answerElement.onclick = () => this.selectAnswer(index);
            
            // Если на этот вопрос уже был дан ответ, выделяем его
            if (this.userAnswers[this.currentQuestionIndex] === index) {
                answerElement.classList.add('selected');
            }
            
            this.answersContainer.appendChild(answerElement);
        });
        
        // Обновляем навигацию
        this.updateQuestionNavigation();
        
        // Обновляем кнопки навигации
        this.updateNavigationButtons();
        
        // Показываем кнопки навигации, если ответ уже дан
        if (this.userAnswers[this.currentQuestionIndex] !== undefined) {
            if (this.currentQuestionIndex < this.questions.length - 1) {
                this.nextQuestionBtn.classList.remove('hidden');
            } else {
                this.finishQuizBtn.classList.remove('hidden');
            }
        } else {
            this.nextQuestionBtn.classList.add('hidden');
            this.finishQuizBtn.classList.add('hidden');
        }
    }

    createQuestionNavigation() {
        this.questionsGrid.innerHTML = '';
        
        this.questions.forEach((_, index) => {
            const btn = document.createElement('button');
            btn.className = 'question-nav-btn';
            btn.textContent = index + 1;
            btn.onclick = () => this.goToQuestion(index);
            this.questionsGrid.appendChild(btn);
        });
        
        this.updateQuestionNavigation();
    }

    updateQuestionNavigation() {
        const buttons = this.questionsGrid.querySelectorAll('.question-nav-btn');
        
        buttons.forEach((btn, index) => {
            // Убираем все классы статуса
            btn.classList.remove('current', 'answered', 'correct', 'incorrect');
            
            // Добавляем класс текущего вопроса
            if (index === this.currentQuestionIndex) {
                btn.classList.add('current');
            }
            
            // Добавляем классы статуса ответа
            if (this.userAnswers[index] !== undefined) {
                btn.classList.add('answered');
                
                const isCorrect = this.userAnswers[index] === this.questions[index].correctAnswer;
                if (isCorrect) {
                    btn.classList.add('correct');
                } else {
                    btn.classList.add('incorrect');
                }
            }
        });
    }

    updateNavigationButtons() {
        // Кнопка "Предыдущий"
        if (this.currentQuestionIndex > 0) {
            this.prevQuestionBtn.classList.remove('hidden');
        } else {
            this.prevQuestionBtn.classList.add('hidden');
        }
        
        // Кнопка "Следующий" / "Завершить"
        if (this.currentQuestionIndex < this.questions.length - 1) {
            this.nextQuestionBtn.classList.remove('hidden');
            this.finishQuizBtn.classList.add('hidden');
        } else {
            this.nextQuestionBtn.classList.add('hidden');
            this.finishQuizBtn.classList.remove('hidden');
        }
    }

    goToQuestion(index) {
        this.currentQuestionIndex = index;
        this.displayQuestion();
    }

    prevQuestion() {
        if (this.currentQuestionIndex > 0) {
            this.currentQuestionIndex--;
            this.displayQuestion();
        }
    }

    selectAnswer(selectedIndex) {
        const answerElements = this.answersContainer.querySelectorAll('.answer-option');
        
        // Убираем предыдущий выбор
        answerElements.forEach(el => el.classList.remove('selected'));
        
        // Выделяем выбранный ответ
        answerElements[selectedIndex].classList.add('selected');
        
        // Сохраняем ответ пользователя
        this.userAnswers[this.currentQuestionIndex] = selectedIndex;
        
        // Проверяем правильность ответа и награждаем Smart очками
        const currentQuestion = this.questions[this.currentQuestionIndex];
        const isCorrect = selectedIndex === currentQuestion.correctAnswer;
        
        if (isCorrect && window.SmartCurrency) {
            // Определяем сложность вопроса
            const difficulty = this.getQuestionDifficulty(currentQuestion);
            window.SmartCurrency.rewardQuizAnswer(true, difficulty);
        }
        
        // Обновляем навигацию
        this.updateQuestionNavigation();
        
        // Показываем кнопку "Следующий вопрос" или "Завершить квиз"
        if (this.currentQuestionIndex < this.questions.length - 1) {
            this.nextQuestionBtn.classList.remove('hidden');
        } else {
            this.finishQuizBtn.classList.remove('hidden');
        }
    }

    nextQuestion() {
        if (this.currentQuestionIndex < this.questions.length - 1) {
            this.currentQuestionIndex++;
            this.displayQuestion();
        }
    }

    finishQuiz() {
        this.calculateScore();
        this.saveQuizResult();
        
        // Награждаем за завершение квиза
        if (window.SmartCurrency) {
            window.SmartCurrency.rewardQuizCompletion(this.score, this.questions.length);
        }
        
        this.showNotification(`Квиз завершен! Правильных ответов: ${this.score} из ${this.questions.length}`);
        
        // Показываем статистику после завершения квиза
        this.showStatistics();
    }

    calculateScore() {
        this.score = 0;
        this.questions.forEach((question, index) => {
            if (this.userAnswers[index] === question.correctAnswer) {
                this.score++;
            }
        });
    }

    getQuestionDifficulty(question) {
        // Определяем сложность на основе длины вопроса и количества вариантов ответа
        const questionLength = question.question.length;
        const optionsCount = question.options.length;
        
        if (questionLength > 100 || optionsCount > 4) {
            return 'hard';
        } else if (questionLength > 50 || optionsCount === 4) {
            return 'medium';
        } else {
            return 'easy';
        }
    }

    restartQuiz() {
        this.currentQuestionIndex = 0;
        this.score = 0;
        this.userAnswers = [];
        this.showQuiz();
        this.displayQuestion();
    }

    chooseCategory() {
        this.categorySelection.classList.remove('hidden');
        this.quizSection.classList.add('hidden');
        this.loadCategories();
    }

    showStatistics() {
        // Скрываем квиз и показываем статистику
        this.quizSection.classList.add('hidden');
        this.categorySelection.classList.add('hidden');
        
        // Показываем секцию статистики
        const statisticsSection = document.getElementById('statistics-section');
        if (statisticsSection) {
            statisticsSection.classList.remove('hidden');
            this.updateStatistics();
        }
    }

    showCategorySelection() {
        // Скрываем статистику и показываем выбор категории
        const statisticsSection = document.getElementById('statistics-section');
        if (statisticsSection) {
            statisticsSection.classList.add('hidden');
        }
        
        this.categorySelection.classList.remove('hidden');
        this.quizSection.classList.add('hidden');
        this.loadCategories();
    }


    displayError(message) {
        this.categoriesGrid.innerHTML = `
            <div class="error-message" style="text-align: center; color: #f56565; padding: 20px;">
                <h3>Ошибка</h3>
                <p>${message}</p>
                <button class="btn btn-primary" onclick="location.reload()">Обновить страницу</button>
            </div>
        `;
    }

    showNotification(message) {
        // Создаем уведомление
        const notification = document.createElement('div');
        notification.className = 'notification';
        notification.textContent = message;
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            background: linear-gradient(135deg, #30CAA1 0%, #20A0FF 100%);
            color: #000000;
            padding: 16px 24px;
            border-radius: 8px;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
            z-index: 1000;
            font-weight: 500;
            animation: slideIn 0.3s ease;
        `;
        
        document.body.appendChild(notification);
        
        // Удаляем через 4 секунды
        setTimeout(() => {
            notification.style.animation = 'slideOut 0.3s ease';
            setTimeout(() => {
                notification.remove();
            }, 300);
        }, 4000);
    }

    saveQuizResult() {
        const quizResult = {
            category: this.currentCategory,
            categoryName: this.translateCategory(this.currentCategory),
            score: this.score,
            totalQuestions: this.questions.length,
            accuracy: Math.round((this.score / this.questions.length) * 100),
            date: new Date().toISOString(),
            timestamp: Date.now()
        };

        // Добавляем в историю
        this.quizHistory.unshift(quizResult);
        
        // Ограничиваем историю до 50 записей
        if (this.quizHistory.length > 50) {
            this.quizHistory = this.quizHistory.slice(0, 50);
        }

        // Обновляем статистику по категориям
        if (!this.categoryStats[this.currentCategory]) {
            this.categoryStats[this.currentCategory] = {
                totalQuizzes: 0,
                totalQuestions: 0,
                correctAnswers: 0,
                bestScore: 0,
                averageAccuracy: 0
            };
        }

        const categoryStat = this.categoryStats[this.currentCategory];
        categoryStat.totalQuizzes++;
        categoryStat.totalQuestions += this.questions.length;
        categoryStat.correctAnswers += this.score;
        categoryStat.bestScore = Math.max(categoryStat.bestScore, this.score);
        categoryStat.averageAccuracy = Math.round((categoryStat.correctAnswers / categoryStat.totalQuestions) * 100);

        // Сохраняем в localStorage
        localStorage.setItem('quizHistory', JSON.stringify(this.quizHistory));
        localStorage.setItem('categoryStats', JSON.stringify(this.categoryStats));
    }

    updateStatistics() {
        // Общая статистика
        const totalQuizzes = this.quizHistory.length;
        const totalQuestions = this.quizHistory.reduce((sum, quiz) => sum + quiz.totalQuestions, 0);
        const correctAnswers = this.quizHistory.reduce((sum, quiz) => sum + quiz.score, 0);
        const incorrectAnswers = totalQuestions - correctAnswers;
        const accuracy = totalQuestions > 0 ? Math.round((correctAnswers / totalQuestions) * 100) : 0;

        // Обновляем элементы
        const totalQuizzesEl = document.getElementById('total-quizzes');
        const totalQuestionsEl = document.getElementById('total-questions');
        const correctAnswersEl = document.getElementById('correct-answers');
        const incorrectAnswersEl = document.getElementById('incorrect-answers');
        const accuracyPercentageEl = document.getElementById('accuracy-percentage');

        if (totalQuizzesEl) totalQuizzesEl.textContent = totalQuizzes;
        if (totalQuestionsEl) totalQuestionsEl.textContent = totalQuestions;
        if (correctAnswersEl) correctAnswersEl.textContent = correctAnswers;
        if (incorrectAnswersEl) incorrectAnswersEl.textContent = incorrectAnswers;
        if (accuracyPercentageEl) {
            accuracyPercentageEl.textContent = `${accuracy}%`;
            // Обновляем круг точности
            const accuracyCircle = document.querySelector('.accuracy-circle');
            if (accuracyCircle) {
                accuracyCircle.style.background = `conic-gradient(from 0deg, #30CAA1 0%, #30CAA1 ${accuracy}%, rgba(255, 255, 255, 0.1) ${accuracy}%)`;
            }
        }

        // История квизов
        this.updateQuizHistory();
        
        // Статистика по категориям
        this.updateCategoryStats();
    }

    updateQuizHistory() {
        const quizHistoryEl = document.getElementById('quiz-history');
        if (!quizHistoryEl) return;

        if (this.quizHistory.length === 0) {
            quizHistoryEl.innerHTML = `
                <div class="no-history">
                    <p>Пока нет пройденных квизов</p>
                    <p>Начните свой первый квиз!</p>
                </div>
            `;
            return;
        }

        const historyHTML = this.quizHistory.slice(0, 10).map(quiz => {
            const date = new Date(quiz.date).toLocaleDateString('ru-RU');
            const icon = this.getCategoryIcon(quiz.category);
            const resultClass = quiz.accuracy >= 70 ? 'correct' : 'incorrect';
            
            return `
                <div class="quiz-history-item">
                    <div class="quiz-history-info">
                        <span class="quiz-category-icon">${icon}</span>
                        <div>
                            <div class="quiz-category-name">${quiz.categoryName}</div>
                            <div class="quiz-date">${date}</div>
                        </div>
                    </div>
                    <div class="quiz-result ${resultClass}">
                        ${quiz.score}/${quiz.totalQuestions} (${quiz.accuracy}%)
                    </div>
                </div>
            `;
        }).join('');

        quizHistoryEl.innerHTML = historyHTML;
    }

    updateCategoryStats() {
        const categoryStatsEl = document.getElementById('category-stats');
        if (!categoryStatsEl) return;

        const categories = Object.keys(this.categoryStats);
        if (categories.length === 0) {
            categoryStatsEl.innerHTML = `
                <div class="no-category-stats">
                    <p>Статистика по категориям появится после прохождения квизов</p>
                </div>
            `;
            return;
        }

        const statsHTML = categories.map(category => {
            const stat = this.categoryStats[category];
            const icon = this.getCategoryIcon(category);
            const categoryName = this.translateCategory(category);
            
            return `
                <div class="category-stat-item">
                    <div class="category-stat-info">
                        <span class="category-stat-icon">${icon}</span>
                        <span class="category-stat-name">${categoryName}</span>
                    </div>
                    <div class="category-stat-score">
                        ${stat.averageAccuracy}% (${stat.totalQuizzes} квизов)
                    </div>
                </div>
            `;
        }).join('');

        categoryStatsEl.innerHTML = statsHTML;
    }

    isStatsSectionVisible() {
        const statsSection = document.getElementById('statistics-section');
        return statsSection && !statsSection.classList.contains('hidden');
    }

    initializeSmartCurrency() {
        // Инициализируем Smart валюту если она доступна
        if (window.SmartCurrency) {
            window.SmartCurrency.updateDisplay();
            console.log('✅ Smart Currency инициализирована в квизе');
        }
    }

    bindEvents() {
        this.nextQuestionBtn.onclick = () => this.nextQuestion();
        this.prevQuestionBtn.onclick = () => this.prevQuestion();
        this.finishQuizBtn.onclick = () => this.finishQuiz();
        
        // События поиска
        this.searchInput.addEventListener('input', (e) => {
            this.searchQuery = e.target.value;
            this.showSuggestions();
            this.filterCategories();
        });
        
        this.searchInput.addEventListener('click', () => {
            this.showSuggestions();
        });
        
        this.searchInput.addEventListener('focus', () => {
            this.showSuggestions();
        });
        
        this.searchInput.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                this.hideSuggestions();
            }
        });
        
        // Навигация по разделам
        this.bindNavigationEvents();
        
        // Snap scroll функциональность
        this.initSnapScroll();
        
        // Скрываем предложения при клике вне поля поиска
        document.addEventListener('click', (e) => {
            if (!this.searchInput.contains(e.target) && !this.searchSuggestions.contains(e.target)) {
                this.hideSuggestions();
            }
        });
    }

    bindNavigationEvents() {
        const navbarItems = document.querySelectorAll('.navbar__item[data-page]');
        
        navbarItems.forEach(item => {
            item.addEventListener('click', () => {
                const page = item.getAttribute('data-page');
                
                // Убираем активный класс со всех элементов
                navbarItems.forEach(navItem => {
                    navItem.classList.remove('navbar__item--active');
                });
                
                // Добавляем активный класс к выбранному элементу
                item.classList.add('navbar__item--active');
                
                // Перенаправляем на соответствующую страницу
                this.navigateToPage(page);
            });
        });
    }

    navigateToPage(page) {
        // Используем относительные пути
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

    switchSection(section) {
        // Скрываем все разделы
        this.categorySelection.classList.add('hidden');
        this.quizSection.classList.add('hidden');
        
        const statisticsSection = document.getElementById('statistics-section');
        if (statisticsSection) {
            statisticsSection.classList.add('hidden');
        }
        
        // Показываем нужный раздел
        switch(section) {
            case 'quiz':
                this.categorySelection.classList.remove('hidden');
                this.loadCategories();
                break;
            case 'statistics':
                if (statisticsSection) {
                    statisticsSection.classList.remove('hidden');
                    this.updateStatistics();
                }
                break;
        }
    }

    initSnapScroll() {
        // Обработчики для snap navigation
        const snapNavItems = document.querySelectorAll('.snap-nav__item');
        
        snapNavItems.forEach(item => {
            item.addEventListener('click', () => {
                const sectionId = item.getAttribute('data-section');
                this.scrollToSection(sectionId);
            });
        });
        
        // Intersection Observer для отслеживания активной секции
        this.initIntersectionObserver();
    }

    scrollToSection(sectionId) {
        const section = document.getElementById(sectionId);
        if (section) {
            section.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    }

    initIntersectionObserver() {
        const sections = document.querySelectorAll('.content-card');
        const snapNavItems = document.querySelectorAll('.snap-nav__item');
        
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    const sectionId = entry.target.id;
                    
                    // Обновляем активное состояние snap navigation
                    snapNavItems.forEach(item => {
                        item.classList.remove('active');
                        if (item.getAttribute('data-section') === sectionId) {
                            item.classList.add('active');
                        }
                    });
                    
                    // Обновляем активное состояние navbar
                    const navbarItems = document.querySelectorAll('.navbar__item[data-section]');
                    navbarItems.forEach(item => {
                        item.classList.remove('navbar__item--active');
                        if (item.getAttribute('data-section') === 'statistics' && sectionId === 'statistics-section') {
                            item.classList.add('navbar__item--active');
                        } else if (item.getAttribute('data-section') === 'quiz' && (sectionId === 'category-selection' || sectionId === 'quiz-section')) {
                            item.classList.add('navbar__item--active');
                        }
                    });
                }
            });
        }, {
            threshold: 0.5,
            rootMargin: '-10% 0px -10% 0px'
        });
        
        sections.forEach(section => {
            observer.observe(section);
        });
    }
}

// Quick quiz functions for sidebar
function startQuickQuiz(category) {
    if (window.quizApp) {
        window.quizApp.startQuiz(category);
    }
}

function showAllCategories() {
    if (window.quizApp) {
        window.quizApp.chooseCategory();
    }
}

function startRandomQuiz() {
    if (window.quizApp && window.quizApp.allCategories.length > 0) {
        const randomCategory = window.quizApp.allCategories[Math.floor(Math.random() * window.quizApp.allCategories.length)];
        window.quizApp.startQuiz(randomCategory);
    }
}

// Add CSS animations for notifications
const notificationStyle = document.createElement('style');
notificationStyle.textContent = `
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
`;
document.head.appendChild(notificationStyle);

// Navigation functions

// Initialize quiz app when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    // Initialize the main quiz app
    window.quizApp = new QuizApp();
    
    // Initialize the template functionality
    if (typeof initNavbar === 'function') {
        initNavbar();
    }
    if (typeof initModals === 'function') {
        initModals();
    }
});
