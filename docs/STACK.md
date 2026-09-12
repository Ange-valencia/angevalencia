# Stack technique — AngeValencia

Cohérente avec les projets existants de la machine (`marketplace-bouake`, `hebie-assistant`).

## Backend — Python / FastAPI

- **Framework** : FastAPI (Python 3.11+)
- **ORM** : SQLAlchemy 2.0 (synchrone) + Alembic (migrations)
- **Validation** : Pydantic v2 / pydantic-settings
- **Base de données** : PostgreSQL (dev local : SQLite pour premiers tests, comme `marketplace-bouake`)
- **Auth** : JWT (PyJWT) + bcrypt
  - tokens **clients** (scope `client`)
  - tokens **admin** (scope `admin`) — séparation totale des accès
- **Serveur** : uvicorn
- **Paiements** : SDK/API Orange Money + Wave (à intégrer en phase dédiée)
- **Stockage images produits** : disque local en dev, MinIO/S3 en prod

## Mobile / Web — Flutter

- **Framework** : Flutter (SDK déjà présent sur la machine)
- **State management** : Provider (déjà utilisé dans `marketplace-bouake`) — Riverpod en option
- **HTTP** : package `http` ou `dio`
- **Stockage local** : shared_preferences (tokens)
- **Deep links** : app_links (paiement, notifications)

> La même base Flutter peut cibler Android, iOS et Web.
> L'espace **admin** sera une app/web séparée (accès totalement cloisonné).

## Notifications

- MVP : statuts consultables dans l'app + badge sur historique.
- Évolution : notification push (FCM) — à intégrer en phase dédiée.

## Déploiement

- Backend : conteneur Docker + reverse proxy.
- Images : volume persistant / MinIO.
- Base : PostgreSQL.
- Variables via `.env`.

## Arborescence cible

```
angevalencia/
├── docs/            # cahier des charges, décisions, bdd, backlog
├── backend/         # API FastAPI (app/, alembic/, requirements.txt)
└── mobile/          # app Flutter (lib/, android/, pubspec.yaml)
```