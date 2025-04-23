// Import du style principal
import './style.css';

// Sélection des éléments du DOM
const screen = document.querySelector('.ecran');
const preview = document.querySelector('.preview');
const buttons = [...document.querySelectorAll('.button')];
const historiqueList = document.getElementById('historiqueList');
const toggleButton = document.getElementById('toggleScientific');
const sciContainer = document.querySelector('.scientifiques');
const installButton = document.getElementById('installButton');

let currentExpression = '';

// Fonction scientifique pour les calculs
const scientificFunctions = {
    sin: (x) => Math.sin(x),
    cos: (x) => Math.cos(x),
    tan: (x) => Math.tan(x),
    log: (x) => Math.log10(x),
    ln: (x) => Math.log(x),
    sqrt: (x) => Math.sqrt(x),
    pow2: (x) => Math.pow(x, 2),
    pow3: (x) => Math.pow(x, 3),
    abs: (x) => Math.abs(x),
    inv: (x) => 1 / x,
    pi: () => Math.PI,
    e: () => Math.E,
};

// Fonction de gestion des entrées
function handleInput(value) {
    if (value === 'C') {
        currentExpression = '';
        screen.value = '';
        preview.value = '';
        return;
    }

    // Traitement des fonctions scientifiques
    if (value in scientificFunctions) {
        try {
            const isConst = ['pi', 'e'].includes(value);
            const num = isConst ? null : parseFloat(currentExpression || screen.value);
            const result = scientificFunctions[value](num);

            screen.value = result;
            preview.value = isConst ? value : `${value}(${num})`;
            currentExpression = result.toString();

            addToHistorique(`${preview.value} = ${result}`);
        } catch {
            screen.value = 'Erreur';
            preview.value = '';
        }
        return;
    }

    // Traitement du calcul (fonction "=")
    if (value === '=') {
        try {
            const result = eval(currentExpression);
            addToHistorique(`${currentExpression} = ${result}`);

            screen.value = result;
            preview.value = currentExpression;
            currentExpression = result.toString();
        } catch {
            screen.value = 'Erreur';
            preview.value = currentExpression;
        }
        return;
    }

    // Traitement classique des entrées (ajout des valeurs)
    currentExpression += value;
    preview.value = currentExpression;

    try {
        screen.value = eval(currentExpression);
    } catch {
        screen.value = '';
    }
}

// Ajoute une entrée à l'historique
function addToHistorique(entry) {
    const li = document.createElement('li');
    li.textContent = entry;
    historiqueList.appendChild(li);
    historiqueList.scrollTop = historiqueList.scrollHeight; // Scroll automatique
}

// Gestion des événements sur les boutons
buttons.forEach(button => {
    const key = button.dataset.key || button.dataset.fn;
    if (key) {
        button.addEventListener('click', () => handleInput(key));
    }
});

// Gestion des événements clavier
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

// Fonction pour activer/désactiver le mode sombre
document.getElementById('darkModeButton').addEventListener('click', () => {
    document.body.classList.toggle("dark-mode");
});

// Fonction pour afficher/masquer les fonctions scientifiques
toggleButton.addEventListener('click', () => {
    sciContainer.classList.toggle('hidden');
});

// Logique de l'installation de l'application en PWA
let deferredPrompt;
window.addEventListener('beforeinstallprompt', (e) => {
    // Empêcher l'affichage automatique du prompt
    e.preventDefault();
    deferredPrompt = e;
    installButton.style.display = 'block'; // Afficher le bouton d'installation
});

// Gestion du clic sur le bouton d'installation
installButton.addEventListener('click', () => {
    if (deferredPrompt) {
        deferredPrompt.prompt(); // Afficher le prompt d'installation
        deferredPrompt.userChoice.then((choiceResult) => {
            if (choiceResult.outcome === 'accepted') {
                console.log('L\'utilisateur a installé l\'application.');
            } else {
                console.log('L\'utilisateur a rejeté l\'installation.');
            }
            deferredPrompt = null;
            installButton.style.display = 'none'; // Masquer le bouton après l'installation
        });
    }
});

// Enregistrement du Service Worker pour la PWA
if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
      navigator.serviceWorker
        .register(new URL('./service-worker.js', import.meta.url)) // Remplacement ici
        .then((registration) => {
          console.log('Service Worker enregistré avec succès:', registration);
        })
        .catch((error) => {
          console.log('Échec de l\'enregistrement du Service Worker:', error);
        });
    });
  }
  

// Vérification du mode d'affichage
if (window.matchMedia('(display-mode: standalone)').matches) {
    installButton.style.display = 'none'; // Cacher le bouton si l'app est déjà installée
}