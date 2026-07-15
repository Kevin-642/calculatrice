# Calculatrice Cosmique

Calculatrice Android Flutter simple et scientifique, pensée pour une publication propre sur Google Play.

## Fonctionnalites

- Opérations de base avec priorité mathématique.
- Parenthèses, puissances, notation scientifique et multiplication implicite.
- Point ou virgule pour saisir les nombres décimaux.
- Fonctions scientifiques : trigonométrie, logarithmes, racine, factorielle,
  pourcentage, inverse, valeur absolue, exponentielle, π et e.
- Modes degrés et radians.
- Mémoire MC, MR, M+ et M−, conservée après la fermeture.
- Historique local interactif des 12 derniers calculs, conservé après la fermeture.
- Appui long sur la touche de suppression pour effacer l’expression.
- Mode contraste élevé conservé entre les sessions.
- Messages explicites pour les opérations impossibles.
- Ouverture cosmique animée, splash Android sombre, nébuleuses, orbites et étoiles.
- Fonctionne hors ligne et ne demande aucune permission Android.

## Architecture

- `lib/calculator_engine.dart` : analyse et évaluation sécurisée des expressions.
- `lib/calculator_controller.dart` : état, règles de saisie et opérations scientifiques.
- `lib/calculator_preferences.dart` : persistance locale des réglages et de l’historique.
- `lib/main.dart` : interface Flutter et composants visuels.

Les fichiers `index.html`, `style.css` et `app.js` appartiennent à l’ancien prototype
web. Ils sont conservés uniquement comme référence et ne font pas partie de
l’application Android publiée.

## Developpement

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

## Build Play Store

Avant l’envoi sur Google Play, crée une clé de signature Android et ajoute un fichier
`key.properties` à la racine du projet. Ce fichier est ignoré par Git.

Exemple de `key.properties`:

```properties
storePassword=mot_de_passe_du_store
keyPassword=mot_de_passe_de_la_cle
keyAlias=upload
storeFile=C:/chemin/vers/upload-keystore.jks
```

Puis génère l’Android App Bundle :

```powershell
flutter build appbundle --release
```

Le fichier à envoyer dans Play Console sera dans :

```text
build/app/outputs/bundle/release/app-release.aab
```

## Publication

Consulte [PLAY_STORE_CHECKLIST.md](PLAY_STORE_CHECKLIST.md) avant de publier.
