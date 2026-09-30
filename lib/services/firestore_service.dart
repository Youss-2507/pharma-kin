import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pharmacy.dart';
import '../models/medicine.dart';
import '../models/stock_item.dart';
import 'location_service.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  CollectionReference get _pharmacies => _db.collection('pharmacies');
  CollectionReference get _medicines => _db.collection('medicines');
  CollectionReference get _stock => _db.collection('stock');

  // ---------- MÉDICAMENTS ----------

  /// Recherche floue par nom générique ou nom commercial.
  /// Firestore ne fait pas de recherche floue nativement : on récupère les
  /// médicaments dont un mot-clé commence par la requête (préfixe), et on
  /// affine côté client si besoin d'une tolérance aux fautes de frappe.
  Future<List<Medicine>> searchMedicines(String query) async {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];

    final snapshot = await _medicines
        .where('searchKeywords', arrayContains: q)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.map((d) => Medicine.fromFirestore(d)).toList();
    }

    // Repli : préfixe (utile si l'utilisateur tape juste le début du mot)
    final prefixSnapshot = await _medicines
        .orderBy('genericName')
        .startAt([q])
        .endAt(['$q\uf8ff'])
        .limit(20)
        .get();
    return prefixSnapshot.docs.map((d) => Medicine.fromFirestore(d)).toList();
  }

  Future<List<Medicine>> getEquivalents(List<String> ids) async {
    if (ids.isEmpty) return [];
    final snapshot = await _medicines
        .where(FieldPath.documentId, whereIn: ids)
        .get();
    return snapshot.docs.map((d) => Medicine.fromFirestore(d)).toList();
  }

  // ---------- PHARMACIES + STOCK ----------

  /// Pour un médicament donné, renvoie les pharmacies (visibles, validées)
  /// qui l'ont en stock disponible, triées par distance à l'utilisateur.
  Future<List<PharmacyResult>> findPharmaciesForMedicine({
    required String medicineId,
    required double userLat,
    required double userLng,
    bool onDutyOnly = false,
    double? maxRadiusKm,
  }) async {
    final stockSnapshot = await _stock
        .where('medicineId', isEqualTo: medicineId)
        .where('status', isEqualTo: StockStatus.available.name)
        .get();

    final results = <PharmacyResult>[];

    for (final stockDoc in stockSnapshot.docs) {
      final stockItem = StockItem.fromFirestore(stockDoc);
      final pharmacyDoc = await _pharmacies.doc(stockItem.pharmacyId).get();
      if (!pharmacyDoc.exists) continue;

      final pharmacy = Pharmacy.fromFirestore(pharmacyDoc);
      if (!pharmacy.isVisibleToUsers) continue;
      if (onDutyOnly && !pharmacy.isOnDuty) continue;

      final distanceKm = LocationService.distanceKm(
        userLat,
        userLng,
        pharmacy.latitude,
        pharmacy.longitude,
      );

      if (maxRadiusKm != null && distanceKm > maxRadiusKm) continue;

      results.add(PharmacyResult(
        pharmacy: pharmacy,
        stockItem: stockItem,
        distanceKm: distanceKm,
      ));
    }

    // Tri : pharmacies de garde d'abord, puis distance, puis fraîcheur
    results.sort((a, b) {
      if (a.pharmacy.isOnDuty != b.pharmacy.isOnDuty) {
        return a.pharmacy.isOnDuty ? -1 : 1;
      }
      final distCompare = a.distanceKm.compareTo(b.distanceKm);
      if (distCompare != 0) return distCompare;
      return b.stockItem.lastUpdated.compareTo(a.stockItem.lastUpdated);
    });

    return results;
  }

  Future<List<Pharmacy>> getOnDutyPharmacies() async {
    final snapshot = await _pharmacies
        .where('isOnDuty', isEqualTo: true)
        .where('registrationStatus', isEqualTo: RegistrationStatus.validated.name)
        .get();
    return snapshot.docs
        .map((d) => Pharmacy.fromFirestore(d))
        .where((p) => p.isVisibleToUsers)
        .toList();
  }

  // ---------- GESTION STOCK (côté pharmacie) ----------

  Future<void> upsertStockItem(StockItem item) async {
    await _stock.doc(item.id.isEmpty ? null : item.id).set(
          item.toFirestore(),
          SetOptions(merge: true),
        );
  }

  Stream<List<StockItem>> watchPharmacyStock(String pharmacyId) {
    return _stock
        .where('pharmacyId', isEqualTo: pharmacyId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => StockItem.fromFirestore(d)).toList());
  }
}

/// Résultat combiné pharmacie + info de stock + distance, utilisé pour
/// l'affichage des fiches résultats dans l'écran de recherche.
class PharmacyResult {
  final Pharmacy pharmacy;
  final StockItem stockItem;
  final double distanceKm;

  PharmacyResult({
    required this.pharmacy,
    required this.stockItem,
    required this.distanceKm,
  });
}
