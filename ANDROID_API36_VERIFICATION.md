# Préparation Android 16 — 13 octobre 2026

## Synthèse de déploiement — vérifiée le 15 octobre 2026

- Version **1.2.2 (code 6)** publiée sur **Tests fermés - Alpha**.
  Play Console affiche « Disponible pour certains testeurs », dernière release
  6 (1.2.2), date de sortie **14 octobre 2026 à 13 h 46**, 178 pays/régions.
- Bundle corrigé accepté par Play : minimum API 24, cible API 36.
  L'erreur de minimum SDK liée à la protection automatique n'est plus présente.
- Déploiement demandé à 100 % de la piste Alpha. Seul avertissement lors de
  la validation : 2 027 modèles auparavant compatibles ne le sont plus,
  conséquence du passage à Android 7.0 minimum.
- Aucun changement restant à soumettre ou prêt à publier dans la vue
  d'ensemble lors de la vérification du 15 octobre. Publication gérée activée.
- Il ne s'agit pas d'une sortie en production : le dernier contrôle d'accès,
  le 14 octobre, indiquait encore 8 testeurs sur les 12 requis pendant 14 jours.
- Preuve locale : `build/play-alpha-1.2.2.jpg` (non versionnée).
- Changements techniques : AGP 8.9.1, minimum Android API 24, version 1.2.2+6,
  cache Kotlin ignoré ; aucune modification des fonctions de calcul.

Les sections suivantes conservent l'historique des vérifications.

## Correctif du 14 octobre 2026 — protection automatique Play

Suite au message Play Console fourni par Kevin, `minSdk` est fixé à 24
dans `android/app/build.gradle.kts`. Android 7.0 devient le minimum ; les
appareils Android 5 et 6 ne pourront pas installer cette nouvelle version.
La cible et la compilation restent à l'API 36. Nouvelle version : 1.2.2+6,
car le code 5 est déjà utilisé sur Play. Notes de version préparées dans
`PLAY_STORE_RELEASE_NOTES_1.2.2.md`.
Les vérifications du 13 octobre ci-dessous concernent l'ancien bundle 1.2.1+5.

Validation du nouveau bundle le 14 octobre :
- `flutter build appbundle --release --no-pub` réussi, 39,2 Mo.
- Manifeste release généré : `minSdkVersion=24`, `targetSdkVersion=36`,
  `versionName=1.2.2`, `versionCode=6`.
- Signature vérifiée avec `jarsigner -verify`.
- SHA-256 : `732CDCCBAAB4D41ADC36DABD14D83A1C37F37D2C14E3B4EE85C92154E55E60D7`.
- Aucun changement du code Dart depuis les 23 tests réussis du 13 octobre.
- `git diff --check` réussi.
- Accès production revérifié le 14 octobre : toujours bloqué, 8 testeurs
  sur les 12 requis pendant 14 jours consécutifs.

## Périmètre et constat

Calculatrice Cosmique (`com.kevincreation.calculatricecosmique`) uniquement.
La capture Play Console fournie signale une version ciblant l'API 35 et une
prolongation au 1er novembre 2026. La configuration de production sur Play
n'a pas été consultée directement.

Le dépôt ciblait déjà Android 16 : `compileSdk = 36`, `targetSdk = 36`,
version `1.2.1+5` (commit `46c96a7`). Aucun changement de cible supplémentaire
n'est nécessaire. Android Gradle Plugin passe de 8.7.3 à 8.9.1, minimum
officiellement indiqué pour l'API 36. Gradle 8.12 et Kotlin 2.1.0 sont conservés.
Le cache local Kotlin est ignoré par Git.

## Vérifications

- Flutter 3.32.6 / Dart 3.8.1 ; compilation avec JDK 17.
- `flutter analyze` : aucune anomalie.
- `flutter test` : 23 tests réussis (calculs, préférences, portrait, paysage).
- Manifeste release fusionné : version 1.2.1, code 5, minimum API 21,
  cible API 36 ; aucune permission contacts, localisation ou Internet,
  aucun service déclaré. AndroidX ajoute une permission interne de niveau
  signature `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`.
- L'interface utilise `SafeArea` et `LayoutBuilder` ; aucune restriction
  d'orientation ni désactivation de l'affichage bord à bord repérée.
- Aucun SDK publicitaire, de facturation ou de géolocalisation dans pubspec.
- `flutter build appbundle --release` : réussi, AAB signé généré dans
  `build/app/outputs/bundle/release/app-release.aab` (39,2 Mo annoncés par Flutter).
  `jarsigner -verify` confirme la signature ; certificat auto-signé habituel
  pour une clé Android. Correspondance avec la clé d'import Play non vérifiée.
  SHA-256 : `97DB52CE549C2E699B8C77E99017DF6088802BB27FE98B437EE27A8854903244`.
- `flutter build apk --release` : réussi ; `aapt dump badging` confirme
  l'identifiant, la version 1.2.1/code 5 et l'API cible 36 dans l'APK.
- APK release installé sur `emulator-5554`, Android 16/API 36 : démarrage
  à froid réussi (`Status: ok`). Capture `build/calculatrice-api36.png`
  examinée : écran principal visible, commandes dégagées des barres système.
  Aucun `FATAL EXCEPTION`, `E/flutter` ou `Unable to start activity` dans
  les 1 000 dernières lignes logcat lues après lancement. Ce contrôle ne
  remplace pas un parcours complet sur téléphone/tablette ni le rapport Play.
- `git diff --check` : réussi.

## Publication

### État réel vérifié dans Play Console le 13 octobre 2026

- Production inactive, accès non encore accordé. Le bouton « Demander à
  publier en production » est désactivé : 8 testeurs inscrits actuellement,
  contre 12 requis pendant au moins 14 jours sans interruption.
- La version 1.2.1/code 5 est déjà active en tests fermés Alpha depuis
  le 22 juillet 2026. Son SDK cible affiché est **36** et Play indique
  une compatibilité avec les pages mémoire de 16 Ko.
- Le code 5 est donc déjà utilisé : le nouvel AAB local ne peut pas être
  importé avec ce même code. Une nouvelle compilation destinée à un nouvel
  import devra employer au minimum le code 6 (revérifier avant import).
- Aucune nouvelle version importée ou publiée : publication en production
  bloquée par les conditions d'accès. L'origine exacte de l'ancienne alerte
  API 35 n'a pas été déterminée ; la version active Alpha cible déjà l'API 36.

Les indications de préparation ci-dessous précèdent cette vérification directe.

Les déclarations Play (dont Sécurité des données) ne sont pas validées par
une compilation. Vérifier dans l'explorateur des app bundles si le code 5
a déjà été utilisé ; si oui, générer un bundle avec un code supérieur au
maximum présent sur toutes les pistes. La version préparée reste 1.2.1+5.
Tester la version puis la publier en production avant l'échéance affichée.
Un dépôt en test interne ne résout pas à lui seul l'alerte de production.
Aucune publication effectuée pendant cette préparation.

## Sources officielles consultées

- Exigence API cible et prolongation :
  https://support.google.com/googleplay/android-developer/answer/11926878
- Minimum AGP pour l'API 36 :
  https://developer.android.com/build/releases/about-agp
- Compatibilité Gradle / JDK d'AGP 8.9 :
  https://developer.android.com/build/releases/agp-8-9-0-release-notes
- Changements Android 16 (bord à bord, grands écrans, retour système) :
  https://developer.android.com/about/versions/16/behavior-changes-16

La référence commune GOOGLE_PLAY_ANDROID_OCTOBRE_2026.md a été lue.
Les migrations sans rapport (Android 17, jeux, geofencing) sont hors périmètre.
