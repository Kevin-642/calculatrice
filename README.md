# Calculatrice Cosmique

Calculatrice Android Flutter simple et scientifique, pensee pour une publication propre sur Google Play.

## Fonctionnalites

- Operations de base avec priorite mathematique.
- Parentheses, nombres decimaux et suppression rapide.
- Fonctions scientifiques: sin, cos, tan, log, ln, sqrt, x2, pi, e, exp.
- Historique local des derniers calculs.
- Mode contraste eleve.
- Fonctionne hors ligne et ne demande aucune permission Android.

## Developpement

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

## Build Play Store

Avant l'envoi sur Google Play, cree une cle de signature Android et ajoute un fichier `key.properties` a la racine du projet. Ce fichier est ignore par Git.

Exemple de `key.properties`:

```properties
storePassword=mot_de_passe_du_store
keyPassword=mot_de_passe_de_la_cle
keyAlias=upload
storeFile=C:/chemin/vers/upload-keystore.jks
```

Puis genere l'Android App Bundle:

```powershell
flutter build appbundle --release
```

Le fichier a envoyer dans Play Console sera dans:

```text
build/app/outputs/bundle/release/app-release.aab
```

## Publication

Consulte [PLAY_STORE_CHECKLIST.md](PLAY_STORE_CHECKLIST.md) avant de publier.
