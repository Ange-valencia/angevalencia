# Décisions — points ouverts du cahier des charges

Statut des décisions : initiales, réversibles. Chaque décision est enregistrée ici avec sa date.

## D1. Villes desservies par plusieurs compagnies (Abidjan, Bouaké, Daloa, Gagnoa…)

**Décision (12/09/2026)** : combiner les deux approches.

1. **Choix proposé au client** : au checkout, si la ville du client est desservie par plusieurs compagnies, la liste est affichée et le client choisit SA compagnie préférée.
2. **Compagnie par défaut** (pré-sélectionnée) selon une règle de priorité fixe :
   `UTB → CTE → SBTA`.
3. Si le client choisit une compagnie qui ne dessert pas sa ville → erreur bloquante au checkout.

**Motif** : simple à implémenter, transparent pour l'utilisateur, et laisse la décision finale à l'utilisateur (meilleure expérience).

**Implémentation** : la priorité est un champ `priority` (int) sur la table de liaison `company_serves_city`, renseigné au seed.

## D2. Gestion des retours / colis non récupérés

**Décision (12/09/2026)** :

- Un colis est gardé **14 jours** par la compagnie de transport à partir du statut "Disponible en compagnie de transport".
- Passé ce délai et sans réaction du client : le colis revient à l'équipe AngeValencia (statut `retour_entrepot`).
- **Remboursement** : le client est remboursé du **prix du produit** uniquement. Les **frais de transport ne sont pas remboursables**.
- Le remboursement s'effectue par le même canal de paiement que la commande (OM ou Wave), sous réserve des délais de l'opérateur.
- Décision à confirmer avec l'équipe métier avant développement (point à valider).

**À définir plus tard** :
- Rétractation légale (14 jours) — consulter un juriste local.
- Garantie/avarie produit (à l'ouverture du colis).

## D3. Délai de livraison affiché

**Décision** : valeur **fixe globale « ~2 mois »** pour le MVP, stockée en configuration du catalogue (éditable par l'admin). Affichée :
- sur chaque fiche produit ;
- dans le récapitulatif juste avant validation de la commande.

## D4. Paiements (MVP)

**Décision** :
- Orange Money et Wave via les API officielles (checkout).
- Paiement 1 (produit) au moment de la commande — obligatoire pour que la commande existe.
- Paiement 2 (frais de transport) possible dès le statut "Arrivée en Côte d'Ivoire" (avant "Disponible en compagnie"). Le client peut aussi payer plus tard, à la compagnie.
- Statut de paiement indépendant du statut de livraison (2 curseurs).

## D5. Identification de la compagnie selon la localisation

**Décision (MVP)** : à partir de la **ville choisie** par le client (champ du profil ou sélection au checkout). La géolocalisation GPS peut être ajoutée en v2 (résolution ville la plus proche).