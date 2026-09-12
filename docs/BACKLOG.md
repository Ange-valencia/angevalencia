# Backlog de développement — AngeValencia

Ordre conseillé. Chaque phase est livrable et testable indépendamment.

## Phase 0 — Fondations du projet
- [x] Initialiser le dépôt git `angevalencia` (dépôt séparé des autres projets)
- [x] Créer le backend FastAPI : `app/`, `alembic`, `requirements.txt`, `.env.example`
- [x] Structure `app/api`, `core`, `models.py`, `schemas.py`, `config.py`, `database.py` (alignée sur `marketplace-bouake`)
- [x] Créer le projet Flutter : `mobile/` (client)
- [x] Schéma `docs/MAQUETTES-ECRANS.md` (aligné sur la maquette)
- [x] Seed initial : 34 villes, UTB/CTE/SBTA, 5 catégories, compte admin (`scripts/seed_db.py`)

## Phase 1 — Authentification & comptes
- [x] Modèle `users` + tables créées à l'import (`Base.metadata.create_all`)
- [x] `POST /auth/register` (email ou téléphone + mot de passe)
- [x] `POST /auth/login` → JWT scope `client`
- [x] Endpoints "Mon compte" (profile, ville, compagnie préférée)
- [x] Espace "Mon compte" côté Flutter (édition profil, ville, compagnie)

## Phase 2 — Admin : catalogue & produits
- [x] Login admin (JWT scope `admin`, endpoint séparé) — **accès totalement cloisonné** (403 pour un client)
- [x] CRUD catégories (avec `is_clothing` pour les tailles)
- [x] CRUD produits (prix FCFA, photos, description, `is_popular`)
- [x] Tailles par produit (`product_sizes`) via écran API admin
- [x] Offres flash : `is_flash_offer`, réduction, `flash_ends_at` (compte à rebours)
- [x] Seed de démonstration (catégories + produits)

## Phase 3 — Catalogue côté client
- [x] Écran accueil : bannière promo, catégories en icônes, offres flash (compte à rebours), produits populaires
- [x] Liste produits par catégorie
- [x] Fiche produit : photos, prix FCFA, description, **délai ~2 mois affiché**, sélecteur de taille (vêt/chaussures)
- [ ] Filtres / tri (prix, popularité)

## Phase 4 — Panier & commande (paiement 1)
- [x] Panier (ajout produit + taille + quantité)
- [x] Checkout : adresse/Ville → choix compagnie de transport (D1 : priorité + liste si multi)
- [x] Écran récap avant validation : produits + **délai de livraison rappelé**
- [x] `POST /orders` → création commande au statut `commande_recue` (lien paiement OM/Wave)
- [ ] Webhook/callback OM & Wave VALIDATION manuelle du 1er paiement (endpoint : `admin/payments/{id}/confirm`)
- [x] Confirmation de commande + `payments` OK

## Phase 5 — Suivi de commande & notifications
- [x] Workflow statuts (barre d'étapes sur fiche commande)
- [x] Endpoint admin : mise à jour du statut `order_status_history`
- [x] `notifications` en base + bouton lecture dans l'app (API)
- [x] Historique des commandes côté client avec statut + étapes
- [ ] (option) Notification push FCM — hors MVP initial

## Phase 6 — Paiement transport (paiement 2)
- [x] Endpoint `POST /orders/{id}/pay-shipping` (OM/Wave) activé au statut `arrivee_ci` / `disponible_compagnie`
- [x] Statut `shipping_fee_status` (pending → paid)
- [x] Carte paiement transport dans l'écran de suivi (Flutter)
- [ ] Règle des 14 jours (D2) : colis non récupéré → `retour_entrepot` (worker/script à créer)

## Phase 7 — Qualité, sécurité & déploiement
- [ ] Tests backend (auth, catalogue, commandes, paiements mockés)
- [ ] Tests Flutter widgets (panier, checkout)
- [ ] Revue sécurité : secrets, validation, limites admin
- [ ] Docker compose (backend + postgres + minio)
- [ ] Build APK de démonstration/sortie
- [ ] Mise en production (reverse proxy, backups BD)

---

## Hors périmètre (v2)
- Géolocalisation GPS pour détection automatique de la ville (D5)
- Retours produits / avis clients
- Promotion avancée (codes promo, panier)
- Multi-vendeurs (exclu par le modèle single-vendeur)