const screen = document.querySelector('.ecran');
const preview = document.querySelector('.preview');
const buttons = [...document.querySelectorAll('.button')];
const historiqueList = document.getElementById('historiqueList'); // pour l'historique

// Fonction principale
let currentExpression = '';

function handleInput(value) {
    if (value === 'C') {
        currentExpression = '';
        screen.value = '';
        preview.value = '';
    } else if (['sin', 'cos', 'tan', 'log'].includes(value)) {
        try {
            const num = parseFloat(currentExpression);
            let result;

            if (value === 'sin') result = Math.sin(num);
            if (value === 'cos') result = Math.cos(num);
            if (value === 'tan') result = Math.tan(num);
            if (value === 'log') result = Math.log10(num);

            screen.value = result;
            preview.value = `${value}(${num})`;
            currentExpression = result.toString();
        } catch (e) {
            screen.value = 'Erreur';
            preview.value = '';
        }
    } else if (value === '=') {
        try {
            const result = eval(currentExpression);

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
    } else {
        currentExpression += value;
        preview.value = currentExpression;

        try {
            // Calculer le résultat pendant la saisie
            const result = eval(currentExpression);
            screen.value = result;
        } catch (e) {
            screen.value = ''; // Pas encore une expression valide
        }
    }
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

// Bouton mode sombre
const darkModeButton = document.getElementById('darkModeButton');
darkModeButton.addEventListener('click', () => {
    document.body.classList.toggle("dark-mode");
});