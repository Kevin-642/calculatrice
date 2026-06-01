# Checklist Google Play

## Technique

- Lancer `flutter analyze`.
- Lancer `flutter test`.
- Verifier l'app sur un telephone Android ou un emulateur.
- Creer une cle d'upload et renseigner `key.properties`.
- Generer `flutter build appbundle --release`.
- Ne jamais commiter `key.properties`, `.jks` ou `.keystore`.

## Fiche Play Console

- Nom: Calculatrice Cosmique.
- Description courte: Calculatrice simple et scientifique au style spatial, utilisable hors ligne.
- Categorie: Outils.
- Declaration de confidentialite: aucune collecte de donnees.
- Public cible: general.
- Captures d'ecran: au moins deux captures telephone.
- Icone: verifier le rendu avant publication.

## Confidentialite

L'application ne demande aucune permission Android, ne contient pas de publicite, ne cree pas de compte utilisateur et n'envoie aucune donnee vers un serveur.
