# Cahier des charges — AngeValencia

> Marketplace mobile/web — produits importés de Chine, vente en Côte d'Ivoire
> Modèle : **single-vendeur** (équipe AngeValencia uniquement, pas de commerçants tiers)

---

## 1. Présentation générale

AngeValencia est une marketplace mobile/web qui permet aux clients en Côte d'Ivoire d'acheter des produits importés de Chine.

- L'équipe AngeValencia gère elle-même les achats en Chine.
- Les produits sont ensuite mis en ligne pour que les clients puissent commander.
- **Pas de commerçants tiers** : modèle à un seul vendeur (l'équipe AngeValencia).

## 2. Types d'utilisateurs

| Rôle | Droits |
|---|---|
| **Client** | Créer un compte, parcourir le catalogue, commander, payer, suivre sa commande. Aucun accès à l'espace admin. |
| **Administrateur** (équipe AngeValencia) | Gérer le catalogue produits, les prix, les tailles, les commandes, le suivi de livraison. |

## 3. Côté Client

### 3.1 Compte
- Inscription / connexion (email ou téléphone)
- Espace "Mon compte"

### 3.2 Catalogue produits
- Liste de produits organisés par **catégories** : Téléphones, Informatique, Mode, Maison, Autres.
- Fiche produit : photos, description, prix (en **FCFA / XOF**).
- Pour les catégories **vêtements et chaussures** : liste des **tailles disponibles** par produit (sans gestion de stock fin par taille — simple affichage des tailles proposées).
- Mise en avant possible de **promotions / offres flash** (avec compte à rebours).

### 3.3 Délai de livraison
- Délai de livraison estimé (**~2 mois**) affiché clairement :
  - sur la fiche produit, **et**
  - avant la validation de la commande.
- Suivi de commande par étapes :
  1. Commande reçue
  2. Achat effectué en Chine
  3. Expédition
  4. En transit
  5. Arrivée en Côte d'Ivoire
  6. Disponible en compagnie de transport
- **Notification au client** à chaque changement de statut.

### 3.4 Paiement en 2 temps
1. **À la commande** : paiement du prix du produit.
2. **À l'arrivée en Côte d'Ivoire** : paiement séparé des **frais de transport** pour récupérer le colis.

**Méthodes de paiement intégrées : Orange Money (OM) et Wave.**

### 3.5 Livraison / récupération
- **Pas de livraison à domicile.**
- Le colis est envoyé à la **compagnie de transport la plus proche du client**.
- Le client récupère son colis à la compagnie après avoir payé les frais de transport.
- L'application identifie/affiche la **compagnie de transport correspondant à l'adresse / localisation** du client.

#### Compagnies partenaires et villes desservies

**UTB** : Abidjan, Bouaké, Yamoussoukro, Daloa, Gagnoa, San-Pédro, Soubré, Sassandra, Man, Korhogo, Ferkessédougou, Dimbokro, Tiébissou, Béoumi, Bouaflé, Bonon, Gonaté, Duékoué, Divo, Méagui, Yabayo

**CTE** : Abidjan, Abengourou, Bondoukou, Bouna, Bouaflé, Bouaké, Daoukro, Mankono, Séguéla, Tanda, Tiébissou, Yamoussoukro

**SBTA** : Abidjan, Agboville, Daloa, Diégonéfla, Divo, Gagnoa, Issia, Méagui, Oumé, San-Pédro, Soubré, Abengourou, Bondoukou, Vavoua, Tiassalé

**Villes desservies par plusieurs compagnies** (Abidjan, Bouaké, Daloa, Gagnoa, etc.) : choix laissé au client (voir `DECISIONS.md`).

### 3.6 Panier et commandes
- Panier classique.
- Historique des commandes avec statut de livraison visible.

## 4. Côté Administrateur
- Ajouter / modifier / supprimer des produits.
- Définir les prix (en FCFA).
- Pour vêtements/chaussures : ajouter la liste des tailles disponibles par produit.
- Gérer les catégories.
- Suivre et mettre à jour le **statut des commandes** :
  achat en Chine → expédition → arrivée → disponible en compagnie de transport.
- Aucune visibilité pour les clients — accès totalement séparé, réservé à l'équipe AngeValencia.

## 5. Identité visuelle
- Couleurs : **orange, noir, beige (couleur "colombe")** — pas de blanc en fond.
- Prix affichés en **FCFA (XOF)**.
- Style marketplace moderne :
  - bannière promo
  - catégories en icônes
  - offres flash avec compte à rebours
  - produits populaires

## 6. Points à clarifier (décidés — voir `DECISIONS.md`)
- Villes multi-compagnies : choix du client + priorité par défaut.
- Retours / colis non récupérés : démarche définie dans `DECISIONS.md`.

## 7. Données de référence
Les listes de compagnies/villes sont considérées comme **données de base** (seed) en base de données :
table `transport_company` + table `city` + relation `company_serves_city` (voir `BASE-DONNEES.md`).