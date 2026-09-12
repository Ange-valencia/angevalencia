# AngeValencia

Marketplace single-vendeur : produits importés de Chine vendus en Côte d'Ivoire.
Achat géré par l'équipe AngeValencia, puis récupération par le client en compagnie de transport (UTB / CTE / SBTA).

## Stack
- **Backend** : FastAPI + SQLAlchemy + PostgreSQL (voir `docs/STACK.md`)
- **Mobile/Web** : Flutter + Provider
- **Paiements** : Orange Money, Wave (en 2 temps : produit puis transport)

## Documentation
- `docs/CAHIER-DES-CHARGES.md` — spécifications fonctionnelles
- `docs/DECISIONS.md` — arbitrages des points ouverts (compagnies, retours, délais)
- `docs/STACK.md` — stack technique
- `docs/BASE-DONNEES.md` — modèle de données
- `docs/BACKLOG.md` — plan de développement

## Structure
```
angevalencia/
├── docs/
├── backend/        # API FastAPI (à construire)
└── mobile/         # App Flutter (à construire)
```