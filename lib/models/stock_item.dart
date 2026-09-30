import 'package:cloud_firestore/cloud_firestore.dart';

enum StockStatus { available, outOfStock }

class StockItem {
  final String id;
  final String pharmacyId;
  final String medicineId;
  final StockStatus status;
  final String manufacturer;
  final DateTime? expirationDate;
  final DateTime lastUpdated;

  StockItem({
    required this.id,
    required this.pharmacyId,
    required this.medicineId,
    required this.status,
    required this.manufacturer,
    this.expirationDate,
    required this.lastUpdated,
  });

  /// Vrai si la date d'expiration est dans moins de 60 jours
  bool get isExpiringSoon {
    if (expirationDate == null) return false;
    return expirationDate!.difference(DateTime.now()).inDays <= 60;
  }

  /// Vrai si l'info n'a pas été mise à jour depuis plus de 7 jours (fiabilité)
  bool get isStale => DateTime.now().difference(lastUpdated).inDays > 7;

  factory StockItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockItem(
      id: doc.id,
      pharmacyId: data['pharmacyId'] ?? '',
      medicineId: data['medicineId'] ?? '',
      status: StockStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'outOfStock'),
        orElse: () => StockStatus.outOfStock,
      ),
      manufacturer: data['manufacturer'] ?? '',
      expirationDate: (data['expirationDate'] as Timestamp?)?.toDate(),
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'pharmacyId': pharmacyId,
      'medicineId': medicineId,
      'status': status.name,
      'manufacturer': manufacturer,
      'expirationDate':
          expirationDate != null ? Timestamp.fromDate(expirationDate!) : null,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}
