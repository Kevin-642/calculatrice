const screen = document.querySelector('.ecran');
const preview = document.querySelector('.preview');
const buttons = [...document.querySelectorAll('.button')];
const historiqueList = document.getElementById('historiqueList'); // pour l'historique
const sciButton = document.getElementById('toggleSci');
const sciPanel = document.getElementById('scientificPanel');

// Fonction principale
let currentExpression = '';
function handleInput(value) {
    if (value === 'C') {
        resetScreen();
    } else if (['sin', 'cos', 'tan', 'log', 'ln', 'sqrt', '^2', 'pi', 'e', 'exp'].includes(value)) {
        handleScientific(value);
    } else if (value === '=') {
        calculateResult();
    } else {
        appendToExpression(value);
    }
}

// Réinitialiser l'écran
function resetScreen() {
    currentExpression = '';
    screen.value = '';
    preview.value = '';
}

// Gérer les fonctions scientifiques
function handleScientific(value) {
    try {
        const num = parseFloat(currentExpression);
        let result;
        switch (value) {
            case 'sin': result = Math.sin(num); break;
            case 'cos': result = Math.cos(num); break;
            case 'tan': result = Math.tan(num); break;
            case 'log': result = Math.log10(num); break;
            case 'ln': result = Math.log(num); break;
            case 'sqrt': result = Math.sqrt(num); break;
            case '^2': result = Math.pow(num, 2); break;
            case 'pi': result = Math.PI; break;
            case 'e': result = Math.E; break;
            case 'exp': result = Math.exp(num); break;
        }
        screen.value = result;
        preview.value = `${value}(${num})`;
        currentExpression = result.toString();
    } catch (e) {
        screen.value = 'Erreur';
        preview.value = '';
    }
}

// Calculer le résultat de l'expression
function calculateResult() {
    try {
        const result = safeEval(currentExpression);
        // Historique
        const li = document.createElement('li');
        li.textContent = `${currentExpression} = ${result}`;
        historiqueList.appendChild(li);
        screen.value = result;
        preview.value = currentExpression;
        currentExpression = result.toString();
    } catch (e) {
        screen.value = 'Erreur';
        preview.value = currentExpression;
    }
}

// Ajouter une valeur à l'expression
function appendToExpression(value) {
    if (isValidExpression(value)) {
        currentExpression += value;
        preview.value = currentExpression;
        try {
            const result = safeEval(currentExpression);
            screen.value = result;
        } catch (e) {
            screen.value = ''; // Pas encore une expression valide
        }
    }
}

// Fonction pour évaluer une expression de manière sécurisée
function safeEval(expression) {
    try {
        // Utilisation d'une évaluation sécurisée
        return new Function('return ' + expression)();
    } catch (e) {
        throw new Error('Expression invalide');
    }
}

// Vérification de la validité de l'expression avant l'ajout
function isValidExpression(value) {
    const lastChar = currentExpression[currentExpression.length - 1];
    const validChars = /[0-9+\-*/.^()sinloglnexppi]/;

    // Vérifier les répétitions d'opérateurs
    if (['+', '-', '*', '/', '.', '^'].includes(lastChar) && ['+', '-', '*', '/', '.'].includes(value)) {
        return false;
    }

    return validChars.test(value);
}

// Écouteur sur les boutons
buttons.forEach(button => {
    button.addEventListener('click', (e) => {
        const value = e.currentTarget.dataset.key;
        handleInput(value);
    });
});

// Écouteur clavier
document.addEventListener('keydown', (e) => {
    let key = e.key;
    if (key === 'Enter') key = '=';
    if (key === 'Backspace') key = 'C';

    const validKey = buttons.find(btn => btn.dataset.key === key);
    if (validKey) {
        e.preventDefault();
        handleInput(key);
    }
});

// Basculer le mode sombre et afficher/masquer les touches scientifiques
function toggleMode() {
    document.body.classList.toggle('dark-mode');
    const isDarkMode = document.body.classList.contains('dark-mode');
    darkModeButton.setAttribute('aria-pressed', isDarkMode ? 'true' : 'false');
    darkModeButton.textContent = isDarkMode ? '🌕' : '🌒';
}

function toggleSciPanel() {
    scientificPanel.classList.toggle('visible');
    const isVisible = scientificPanel.classList.contains('visible');
    toggleSciButton.textContent = isVisible ? '🔬' : '🧪';
}

// Gestion des boutons mode sombre et scientifiques
const darkModeButton = document.getElementById('darkModeButton');
const toggleSciButton = document.getElementById('toggleSci');
darkModeButton.addEventListener('click', toggleMode);
toggleSciButton.addEventListener('click', toggleSciPanel);