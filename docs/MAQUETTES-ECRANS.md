# Maquettes écrans — AngeValencia

> Style marketplace moderne. Palette : **orange** (actions/accents), **noir** (navigation basse),
> **beige colombe** `#EAE2CE` (fond). Aucun fond blanc. Prix en **FCFA (XOF)**.

## Côté client

### 1. Écran de connexion / inscription
- Logo (icône avion/sac) orange, bas de page beige.
- Onglets segmentés : **Connexion** | **Inscription**.
- Champs : identifiant (email OU téléphone +225), code PIN 4 chiffres (+ nom en inscription).
- Bandeau rappel discret : « Livraison estimée ~2 mois · Récupération en compagnie de transport ».

### 2. Accueil
- **Bannière promo** (dégradé orange foncé) : « La Chine, à portée de main » + CTA « Découvrir ».
- **Catégories en icônes** : Téléphones, Informatique, Mode, Maison, Autres (scroll horizontal).
- **Offres flash** avec compte à rebours → cartes défilantes avec badge `-X%`.
- **Produits populaires** : grille 2 colonnes, badge noir « POPULAIRE ».
- Barre du bas (noir) : Accueil · Commandes · Panier (badge compteur) · Compte.

### 3. Fiche produit
- Galerie photos (swipe), nom, prix barré + prix réduit si offre flash.
- Encadré **délai de livraison** « ~2 mois » + note récupération compagnie (info avant achat).
- **Tailles disponibles** (vêtements/chaussures) : chips (S, M, L, XL…).
- Description, sélecteur de quantité, bouton « Ajouter au panier ».

### 4. Panier
- Lignes : image, nom, taille, quantité, prix (FCFA).
- Total + rappel : « Paiement ON / Wave à la commande · Frais de transport à l'arrivée ».
- Bouton « Commander » → checkout.

### 5. Checkout (récap avant validation)
- Panier récapitulatif.
- **Ville de récupération** (liste des villes desservies).
- **Compagnie de transport** : pré-sélection automatique (priorité UTB → CTE → SBTA),
  choix possible si plusieurs compagnies desservent la ville (D1).
- **Méthode de paiement produit** : Orange Money | Wave.
- Encadré info orange : livraison ~2 mois + frais de transport payés à l'arrivée.
- CTA : « Payer X FCFA ».

### 6. Suivi de commande (détail)
- Code commande + date.
- **Stepper vertical des 7 étapes** : Commande reçue → Achat en Chine → Expédition →
  En transit → Arrivée en CI → Disponible en compagnie → Récupérée.
- Au statut *Disponible en compagnie* : **carte paiement des frais de transport**
  (montant + bouton Payer ON/Wave).
- Articles + totaux ; historique daté de chaque changement de statut (notification).

### 7. Mes commandes
- Liste : code, badge de statut, articles, total.
- Tap → suivi complet (écran 6).

### 8. Mon compte
- Carte identité (avatar, nom, email/téléphone).
- **Ville de récupération** et **compagnie préférée** (optionnelle, utilisée au checkout).
- Déconnexion.

### 9. Notifications (dans l'app)
- Liste des notifications de statut (badge non-lus), accessible depuis Compte/Commandes.

## Côté administrateur (app/web séparée — réservée équipe AngeValencia)

### 10. Login admin (accès cloisonné)
- Identifiants admin uniquement (aucun accès client possible, 403 sinon).

### 11. Catalogue
- Liste produits (recherche, filtre catégorie).
- Formulaire produit : nom, catégorie, prix FCFA, description, photos,
  **délai de livraison (éditable, défaut ~2 mois)**, flags offre flash/`%`/fin et populaire.
- **Tailles** : ajout/suppression de tailles pour vêtements/chaussures.

### 12. Catégories
- CRUD : nom, icône, ordre, `is_clothing` (gère des tailles), actif/inactif.

### 13. Commandes
- Liste des commandes filtrée par statut.
- Mise à jour du statut (workflow), champ **frais de transport** obligatoire à
  « Disponible en compagnie ».
- Confirmation manuelle des paiements en attendant les webhooks ON/Wave.