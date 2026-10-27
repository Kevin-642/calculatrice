# Campagne Movember 2026 — Calculatrice Cosmique

## Livraison du 27 octobre 2026

Identité temporaire limitée à novembre 2026, selon la date locale du téléphone.
Logo moustachu dans l’en-tête, message non bloquant sous l’historique dans la zone
défilante. Ni déplacement des touches, ni modification de leurs couleurs.
L’écran de lancement et l’icône du lanceur Android restent les originaux.
L’asset fourni constitue également la proposition d’icône alternative, non déployée
comme icône native : une icône native statique ne reviendrait pas automatiquement
à l’original en décembre.

## Architecture et périmètre

- `lib/main.dart` : raccordement du contexte saisonnier, logo, carte.
- `lib/movember_campaign.dart` : présentation, calendrier, reprise et minuterie.
- `assets/brand/logo.png` : original conservé.
- `assets/brand/movember_2026.png` : proposition générée, 2 286 609 octets.
- `test/movember_campaign_test.dart` : dates, formats d’écran et reprise.
- Moteur, contrôleur, préférences, formules, conversions et historiques inchangés.
- Aucune dépendance, permission, collecte, requête réseau ou service ajouté.

## Validation

- `flutter analyze` : aucune anomalie.
- `flutter test --reporter expanded` : 29 tests réussis.
- Régressions couvertes : opérations usuelles et scientifiques, décimales,
  erreurs, mémoire, historique, grapheur et ouverture des conversions.
- Campagne : calcul 2+3=5 et conservation de l’historique après expiration.
- Formats : 320×568, 390×844, 844×390 et 800×1280, sans exception de layout.
- Dates : avant novembre, début et fin novembre, décembre, novembre 2027,
  désactivation explicite et changement de date pendant la mise en arrière-plan.
- Performance : image d’en-tête décodée à 144 pixels de large (environ 81 Kio RGBA
  pour une image carrée), aucune animation supplémentaire, une minuterie à minuit
  annulée en pause et à la destruction. Surcoût source de l’asset : environ 2,18 Mio.
  Aucun profilage RAM/FPS sur appareil réel effectué ; aucune mesure de fluidité
  ni validation visuelle manuelle multi-appareils n’est revendiquée.

## Restauration

Le 1er décembre 2026, logo original et suppression de la carte automatiques,
à minuit si l’application reste ouverte ou à sa reprise. L’état de calcul est
conservé. La campagne ne se réactive pas en novembre 2027.
La date dépend de l’horloge locale : une modification manuelle peut modifier
l’activation, réévaluée à la prochaine reprise ou à minuit.

Pour désactiver avant cette date, reconstruire avec :

```powershell
flutter build appbundle --release --dart-define=MOVEMBER_ENABLED=false
```

Ajouter un numéro de build inédit pour une livraison Play. Ne pas effacer les
données de l’application. Pour supprimer définitivement la campagne du code,
retirer l’enveloppe MovemberCampaign, la carte, le choix de logo et l’asset déclaré,
en conservant l’original. Aucun changement de données à migrer.

## Google Play / Android

Référence commune Google Play Android octobre 2026 consultée. Application Outils,
non jeu : aucune fonctionnalité Play Games ajoutée, aucune migration de SDK.
Manifest principal sans permission ni service ; minSdk 24 et target/compileSdk 36
inchangés. Cette intervention graphique ne change pas les déclarations de données.
Aucune échéance réglementaire nouvelle n’est utilisée pour justifier un changement.
Le statut effectif du circuit de test ne peut pas être déduit des fichiers locaux.

Candidat préparé par `flutter build appbundle --release --build-name=1.2.3 --build-number=7`.
Ce numéro doit être vérifié comme disponible dans la Play Console avant envoi.
Ne pas promouvoir vers la production ni modifier les testeurs pour cette campagne.
L’automatisation Firefox a été refusée par l’outil : contrôle des URL non pris en
charge pour ce navigateur. Aucun téléversement ni changement Play Console effectué.

## Création de l’asset

Outil intégré image_gen, skill imagegen ; référence : visuel Movember fourni,
mascotte planétaire de droite et univers cosmique du logo existant.
Prompt de génération :

> Create a square 1024x1024 alternative Movember app icon for Calculatrice Cosmique.
> Reference the rightmost planetary mascot of the supplied campaign image: friendly
> blue violet ringed planet with expressive eyes, magnificent dark curled moustache,
> discreet blue awareness ribbon, tiny wizard hat with stars. Deep navy galaxy
> background, blue violet nebulae and sparse stars, luminous planetary rings.
> Polished playful 3D illustration, legible silhouette at small icon sizes, centered
> with generous safe margins. No text, no numbers, no border, no watermark.
> This is an alternative proposal, preserve cosmic identity.

Le fichier obtenu est conservé tel que généré ; format carré, contrôlé visuellement.

## Résultat de compilation

Compilation release réussie le 27 octobre 2026, code de sortie 0.
Fichier local : `build/app/outputs/bundle/release/app-release.aab`.
Taille : 43 417 363 octets (environ 41,4 Mio).
Version candidate : 1.2.3 (7), paramètres de compilation explicites ; la version
par défaut du pubspec reste 1.2.2+6.
SHA-256 : `EE48163D3814CB985BC050C34B23EBE0AAEFDF4E1DF129C32DCF8F97969B0579`.
Bundle conservé localement, non ajouté à Git et non envoyé à Google Play.
