import 'package:cloud_firestore/cloud_firestore.dart';

/// Document unique dans la collection "config" (id: "global")
/// géré depuis l'interface administrateur.
class AppConfig {
  final double monthlySubscriptionPrice; // en USD ou CDF, à préciser
  final int freeTrialDurationDays;
  final int gracePeriodDurationDays;

  AppConfig({
    required this.monthlySubscriptionPrice,
    this.freeTrialDurationDays = 30,
    this.gracePeriodDurationDays = 30,
  });

  factory AppConfig.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppConfig(
      monthlySubscriptionPrice:
          (data['monthlySubscriptionPrice'] ?? 0).toDouble(),
      freeTrialDurationDays: data['freeTrialDurationDays'] ?? 30,
      gracePeriodDurationDays: data['gracePeriodDurationDays'] ?? 30,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'monthlySubscriptionPrice': monthlySubscriptionPrice,
      'freeTrialDurationDays': freeTrialDurationDays,
      'gracePeriodDurationDays': gracePeriodDurationDays,
    };
  }
}
