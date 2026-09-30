# Pharma Kin — Trouver des médicaments à Kinshasa

Application permettant aux habitants de Kinshasa de localiser un médicament
disponible dans les pharmacies proches, avec recherche par texte ou par
photo, itinéraire et suivi en temps réel via Google Maps.

## Structure du projet

```
pharma_kin/
├── lib/
│   ├── models/              # Pharmacy, Medicine, StockItem, AppConfig
│   ├── services/            # FirestoreService, LocationService, OcrService
│   └── screens/
│       ├── user_app/        # Recherche, résultats, fiche pharmacie, photo
│       └── pharmacy_app/    # Inscription, gestion du stock
├── admin_web/               # Tableau de bord admin (React, séparé du mobile)
├── firestore/
│   └── firestore.rules      # Règles de sécurité Firebase
└── pubspec.yaml
```

## Ce qui est construit

- **Modèle de données complet** : Pharmacie (avec statut d'inscription et
  de paiement), Médicament (avec noms commerciaux et équivalents validés),
  Stock (par pharmacie, avec fabricant/date d'expiration), Configuration.
- **App utilisateur** : recherche texte avec suggestions, recherche par
  photo (OCR local via ML Kit, sans envoi de données), filtres (garde,
  rayon), tri (distance/récence), fiche pharmacie avec appel/WhatsApp/
  itinéraire (délégué à Google Maps), flux de suggestion d'équivalents.
- **App pharmacie** : inscription (statut "en attente"), gestion du stock
  avec bascule disponible/épuisé, verrouillage si abonnement impayé.
- **Interface admin (web)** : validation des demandes, statistiques,
  rapport de pénuries par médicament, gestion du prix d'abonnement.
- **Règles Firestore** de base reflétant les permissions par rôle.

## Ce qu'il reste à faire avant une V1 utilisable

1. **Configuration Firebase réelle** : créer le projet Firebase, générer
   les fichiers `google-services.json` (Android) et
   `GoogleService-Info.plist` (iOS), et initialiser `firebase_core` dans
   `main.dart`.
2. **Authentification pharmacie robuste** : les règles Firestore actuelles
   sont une base — pour empêcher qu'une pharmacie modifie elle-même son
   propre `paymentStatus`, il faut déplacer cette logique dans des
   **Cloud Functions** plutôt que de compter uniquement sur les règles.
3. **Géocodage des adresses** : convertir l'adresse saisie par la pharmacie
   en latitude/longitude (API de géocodage, ou saisie manuelle sur une
   carte lors de l'inscription).
4. **Mode hors-ligne réel** : mise en cache SQLite des pharmacies et du
   catalogue de médicaments (la dépendance `sqflite` est déjà ajoutée,
   la logique de synchronisation reste à écrire).
5. **Paiement mobile money** : intégration avec un fournisseur (Airtel
   Money / M-Pesa / Orange Money) pour vérifier automatiquement les
   paiements et mettre à jour `paymentStatus`.
6. **Notifications** : rappel aux pharmacies dont le stock est périmé
   (`isStale`) ou dont un lot approche de l'expiration (`isExpiringSoon`).
7. **App admin** : `admin_web/AdminDashboard.jsx` est un point de départ
   fonctionnel à intégrer dans un vrai projet React (authentification
   admin avec Firebase Custom Claims à mettre en place).

## Lancer le projet Flutter (une fois Firebase configuré)

```bash
flutter pub get
flutter run
```
