# Base de données — AngeValencia

Modèle de données prévu pour l'API FastAPI + SQLAlchemy.

## Tables

### users
| colonne | type | notes |
|---|---|---|
| id | int PK | |
| role | enum('client','admin') | séparation totale des accès |
| email | varchar unique nullable | inscription email OU téléphone |
| phone | varchar unique nullable | |
| password_hash | varchar | bcrypt |
| full_name | varchar | |
| city | varchar nullable | ville de récupération (D5) |
| preferred_company_id | FK nullable | compagnie préférée (D1) |
| created_at | datetime | |

### categories
| colonne | type | notes |
|---|---|---|
| id | int PK | Téléphones, Informatique, Mode, Maison, Autres |
| name | varchar unique | |
| icon | varchar | icône pour l'écran catégories |
| is_clothing | bool | True = gère des tailles (Mode) |
| sort_order | int | |
| is_active | bool | |

### products
| colonne | type | notes |
|---|---|---|
| id | int PK | |
| category_id | FK | |
| name | varchar | |
| description | text | |
| price_xof | int | prix en FCFA |
| image_url(s) | text/JSON | photos |
| is_flash_offer | bool | offre flash |
| flash_discount_pct | int nullable | % de réduction |
| flash_ends_at | datetime nullable | fin du compte à rebours |
| is_popular | bool | section "produits populaires" |
| delivery_delay_text | varchar | ex : "~2 mois" (D3, éditable) |
| is_active | bool | |
| created_at | datetime | |

### product_sizes
| colonne | type | notes |
|---|---|---|
| id | int PK | |
| product_id | FK | |
| size_label | varchar | ex : S, M, L, XL ; pointures 40/41/42 |
| position | int | ordre d'affichage |

> Pas de stock par taille : simple liste (cf. cahier des charges 3.2).

### transport_companies
| colonne | type | notes |
|---|---|---|
| id | int PK | UTB, CTE, SBTA |
| name | varchar unique | |
| priority | int | ordre de pré-sélection par défaut (D1) : UTB=1, CTE=2, SBTA=3 |
| is_active | bool | |

### cities
| colonne | type | notes |
|---|---|---|
| id | int PK | |
| name | varchar unique | Abidjan, Bouaké, Daloa… |

### company_serves_city (liaison)
| colonne | type | notes |
|---|---|---|
| company_id | FK | |
| city_id | FK | |
| priority | int nullable | priorité par ville (fallback D1) |
| unique(company_id, city_id) | | |

### orders
| colonne | type | notes |
|---|---|---|
| id | int PK | |
| user_id | FK | |
| status | enum | voir workflow ci-dessous |
| total_product_xof | int | somme produits (paiement 1) |
| shipping_fee_xof | int nullable | frais de transport (paiement 2) |
| shipping_fee_status | enum('pending','paid') | paiement 2 |
| city_id | FK | ville de récupération |
| company_id | FK | compagnie choisie (D1) |
| created_at | datetime | |
| paid_at | datetime nullable | paiement 1 |

> Deux curseurs indépendants : `status` (livraison) et `shipping_fee_status` (frais transport).

### order_items
| colonne | type | notes |
|---|---|---|
| id | int PK | |
| order_id | FK | |
| product_id | FK | snapshot produit |
| product_name | varchar | copie au moment de la commande |
| size_label | varchar nullable | taille choisie |
| unit_price_xof | int | |
| quantity | int | |

### order_status_history
| colonne | type | notes |
|---|---|---|
| id | int PK | |
| order_id | FK | |
| status | enum | |
| note | text nullable | commentaire admin |
| changed_at | datetime | base des notifications |

### payments
| colonne | type | notes |
|---|---|---|
| id | int PK | |
| order_id | FK | |
| type | enum('product','shipping') | paiement 1 ou 2 |
| method | enum('orange_money','wave') | |
| amount_xof | int | |
| status | enum('pending','success','failed','refunded') | |
| operator_transaction_id | varchar nullable | id chez OM/Wave |
| created_at | datetime | |

### promotions
| colonne | type | notes |
|---|---|---|
| id | int PK | |
| product_id | FK nullable | liée à un produit ou à une catégorie |
| category_id | FK nullable | |
| discount_pct | int | |
| starts_at / ends_at | datetime | |
| label | varchar | ex : "Offre flash" |

*Le champ `is_flash_offer` de `products` peut suffire pour le MVP ; `promotions` sera dérivé plus tard si besoin.*

### notifications
| colonne | type | notes |
|---|---|---|
| id | int PK | |
| user_id | FK | |
| order_id | FK | |
| title / body | varchar | |
| read | bool | |
| created_at | datetime | |

## Workflow statuts de commande (livraison)

```
commande_recue
   → achat_chine
   → expedition
   → en_transit
   → arrivee_ci
   → disponible_compagnie  (shipping_fee payable)
   → recuperee
```

Statuts d'exception (D2) :
- `retour_entrepot` (colis non récupéré après 14 jours)
- `annulee` (client ou admin, avant paiement)

## Règle compagnie (D1)

- Ville choisie → liste des compagnies via `company_serves_city`.
- Si une seule : utilisée directement.
- Si plusieurs : client choisit ; pré-sélection selon `transport_companies.priority`.
- Validation : la compagnie choisie doit desservir la ville.

## Données de seed

- 3 compagnies + 3 relations `company_serves_city` complètes (listes du cahier des charges).
- Catégories initiales : Téléphones, Informatique, Mode, Maison, Autres.
- Éventuellement quelques produits de démonstration.