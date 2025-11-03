// Тестовая база данных квизов
const quizData = {
    'general': [
        {
            question: "What is the capital of France?",
            options: ["London", "Paris", "Berlin", "Madrid"],
            correctAnswer: 1
        },
        {
            question: "What is 2 + 2?",
            options: ["3", "4", "5", "6"],
            correctAnswer: 1
        },
        {
            question: "What is the largest planet in our solar system?",
            options: ["Earth", "Jupiter", "Saturn", "Neptune"],
            correctAnswer: 1
        }
    ],
    'science-technology': [
        {
            question: "What is the chemical symbol for water?",
            options: ["H2O", "CO2", "NaCl", "O2"],
            correctAnswer: 0
        },
        {
            question: "What is the speed of light?",
            options: ["300,000 km/s", "150,000 km/s", "450,000 km/s", "600,000 km/s"],
            correctAnswer: 0
        }
    ],
    'history': [
        {
            question: "In which year did World War II end?",
            options: ["1943", "1944", "1945", "1946"],
            correctAnswer: 2
        },
        {
            question: "Who was the first president of the United States?",
            options: ["John Adams", "Thomas Jefferson", "George Washington", "Benjamin Franklin"],
            correctAnswer: 2
        }
    ],
    'geography': [
        {
            question: "What is the largest country in the world?",
            options: ["Canada", "China", "Russia", "USA"],
            correctAnswer: 2
        },
        {
            question: "What is the longest river in the world?",
            options: ["Amazon", "Nile", "Yangtze", "Mississippi"],
            correctAnswer: 1
        }
    ],
    'literature': [
        {
            question: "Who wrote 'Romeo and Juliet'?",
            options: ["Charles Dickens", "William Shakespeare", "Jane Austen", "Mark Twain"],
            correctAnswer: 1
        }
    ],
    'music': [
        {
            question: "Which instrument has 88 keys?",
            options: ["Guitar", "Piano", "Violin", "Drums"],
            correctAnswer: 1
        }
    ],
    'movies': [
        {
            question: "Who directed 'The Godfather'?",
            options: ["Martin Scorsese", "Francis Ford Coppola", "Steven Spielberg", "Alfred Hitchcock"],
            correctAnswer: 1
        }
    ],
    'sports': [
        {
            question: "How many players are on a basketball team?",
            options: ["4", "5", "6", "7"],
            correctAnswer: 1
        }
    ],
    'animals': [
        {
            question: "What is the fastest land animal?",
            options: ["Lion", "Cheetah", "Antelope", "Horse"],
            correctAnswer: 1
        }
    ],
    'entertainment': [
        {
            question: "What is the highest-grossing film of all time?",
            options: ["Avatar", "Titanic", "Avengers: Endgame", "Star Wars"],
            correctAnswer: 0
        }
    ],
    'television': [
        {
            question: "Which TV show is set in Westeros?",
            options: ["Breaking Bad", "Game of Thrones", "The Walking Dead", "Stranger Things"],
            correctAnswer: 1
        }
    ],
    'video-games': [
        {
            question: "What company created the game 'Minecraft'?",
            options: ["EA", "Ubisoft", "Mojang", "Activision"],
            correctAnswer: 2
        }
    ],
    'celebrities': [
        {
            question: "Who is known as the 'King of Pop'?",
            options: ["Elvis Presley", "Michael Jackson", "Prince", "Madonna"],
            correctAnswer: 1
        }
    ],
    'people': [
        {
            question: "Who painted the Mona Lisa?",
            options: ["Vincent van Gogh", "Pablo Picasso", "Leonardo da Vinci", "Michelangelo"],
            correctAnswer: 2
        }
    ],
    'world': [
        {
            question: "How many continents are there?",
            options: ["5", "6", "7", "8"],
            correctAnswer: 2
        }
    ],
    'brain-teasers': [
        {
            question: "What comes next in the sequence: 2, 4, 8, 16, ?",
            options: ["24", "32", "20", "28"],
            correctAnswer: 1
        }
    ],
    'for-kids': [
        {
            question: "What color do you get when you mix red and blue?",
            options: ["Green", "Purple", "Orange", "Yellow"],
            correctAnswer: 1
        }
    ],
    'hobbies': [
        {
            question: "What is the art of folding paper called?",
            options: ["Calligraphy", "Origami", "Pottery", "Sculpture"],
            correctAnswer: 1
        }
    ],
    'humanities': [
        {
            question: "What is the study of human behavior called?",
            options: ["Biology", "Psychology", "Chemistry", "Physics"],
            correctAnswer: 1
        }
    ],
    'religion-faith': [
        {
            question: "What is the holy book of Islam?",
            options: ["Bible", "Torah", "Quran", "Vedas"],
            correctAnswer: 2
        }
    ],
    'newest': [
        {
            question: "What year was the iPhone first released?",
            options: ["2005", "2006", "2007", "2008"],
            correctAnswer: 2
        }
    ],
    'rated': [
        {
            question: "What is the highest rating on IMDb?",
            options: ["9.0", "9.5", "10.0", "8.5"],
            correctAnswer: 2
        }
    ]
};

// Функция для получения случайных вопросов из категории
function getRandomQuestions(category, count = 10) {
    const questions = quizData[category];
    if (!questions) return [];
    
    const shuffled = [...questions].sort(() => 0.5 - Math.random());
    return shuffled.slice(0, Math.min(count, questions.length));
}

// Функция для получения списка категорий
function getCategories() {
    return Object.keys(quizData);
}

// Функция для получения количества вопросов в категории
function getCategoryQuestionCount(category) {
    return quizData[category] ? quizData[category].length : 0;
}

// Функция для получения статистики по всем категориям
function getCategoriesStats() {
    const stats = {};
    Object.keys(quizData).forEach(category => {
        stats[category] = {
            count: quizData[category].length,
            name: category
        };
    });
    return stats;
}
