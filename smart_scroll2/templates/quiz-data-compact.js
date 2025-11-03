// Расширенная база данных квизов из OpenTriviaQA (английский язык)
const quizData = {
    'general': [
        {
            question: "This drink contains caffeine.",
            options: ["Orange juice", "Coffee", "Beer", "Mineral water"],
            correctAnswer: 1
        },
        {
            question: "If a TV program is rated G then this is true.",
            options: ["It is suitable for young children.", "It contains mild sexual situations.", "It contains moderate violence.", "It is suitable for all audiences."],
            correctAnswer: 3
        },
        {
            question: "The theory of relativity was introduced in physics by this man.",
            options: ["Archimedes", "Albert Einstein", "Isaac Newton", "Galileo Galilei"],
            correctAnswer: 1
        },
        {
            question: "The symbol for the chemical element iron is this.",
            options: ["Zn", "Br", "Fe", "I"],
            correctAnswer: 2
        },
        {
            question: "The author of the novel A Portrait of the Artist as a Young Man is this writer.",
            options: ["William Faulkner", "T. S. Eliot", "Samuel Beckett", "James Joyce"],
            correctAnswer: 3
        },
        {
            question: "The capital of Mongolia is this city.",
            options: ["Davao", "Islamabad", "Quezon", "Ulaanbaatar"],
            correctAnswer: 3
        },
        {
            question: "Mitochondrias function in cells is to perform this.",
            options: ["To control chemical reactions within the cytoplasm", "To process proteins targeted to the plasma membrane", "To store information needed for cellular division", "To convert organic materials into energy"],
            correctAnswer: 3
        },
        {
            question: "The US bought Alaska in this year.",
            options: ["1854", "1942", "1867", "1882"],
            correctAnswer: 2
        },
        {
            question: "The 23rd US President was in office during this period.",
            options: ["1909 - 1913", "1889 - 1893", "1877 - 1881", "1837 - 1841"],
            correctAnswer: 1
        },
        {
            question: "One of these actors did not star in the 1971 movie A Clockwork Orange.",
            options: ["Michael Bates", "Patrick Magee", "Warren Brown", "Malcolm McDowell"],
            correctAnswer: 2
        },
        {
            question: "The first Bulgarian state was formed in this year.",
            options: ["429 AD", "681 AD", "651 AD", "712 AD"],
            correctAnswer: 1
        },
        {
            question: "The 1962 Soccer World Cup tournament was held in this country.",
            options: ["Chile", "Mexico", "Italy", "Switzerland"],
            correctAnswer: 0
        },
        {
            question: "The Meryas were a probably Finno-Ugric tribe who lived in the region of modern Russia. This is the first historian to mention them.",
            options: ["Sima Guang", "Priscus", "Eusebius of Caesarea", "Jordanes"],
            correctAnswer: 3
        },
        {
            question: "The word abacus derives from a Hebrew word, meaning this.",
            options: ["Movement", "Dust", "Wood", "Sky"],
            correctAnswer: 1
        },
        {
            question: "The Chevy Nova sold poorly in Mexico because no va means doesnt go in Spanish.",
            options: ["True", "False"],
            correctAnswer: 1
        },
        {
            question: "A car that gets over 200 miles per gallon is reclaimed by the factory, after its owner calls to congratulate the manufacturers about its excellent performance.",
            options: ["False", "True"],
            correctAnswer: 0
        },
        {
            question: "A very complicated Honda Accord commercial required 606 takes and was done without the use of any computer-generated images.",
            options: ["False", "True"],
            correctAnswer: 1
        },
        {
            question: "Putting sugar in the gas tank of a carburetor-equipped vehicle will ruin the engine.",
            options: ["False", "True"],
            correctAnswer: 0
        },
        {
            question: "Man bought an old motorcycle only to discover that it was once owned by Elvis Presley.",
            options: ["False", "True"],
            correctAnswer: 0
        },
        {
            question: "Cars were stolen by thieves who wrote down VINs (car serial numbers)  and used them to obtain duplicate keys through auto dealerships.",
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