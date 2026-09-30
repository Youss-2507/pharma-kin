import 'package:cloud_firestore/cloud_firestore.dart';

enum RegistrationStatus { pending, validated, rejected }

enum PaymentStatus { freeTrial, upToDate, unpaidGracePeriod, suspended }

class Pharmacy {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String phone;
  final String? whatsapp;
  final String commune; // ex: Gombe, Ngaliema, Bandal...
  final String openingHours;
  final bool isOnDuty; // pharmacie de garde
  final DateTime? dutyStartDate;
  final DateTime? dutyEndDate;
  final RegistrationStatus registrationStatus;
  final DateTime accountCreatedAt;
  final DateTime? freeTrialStartDate;
  final PaymentStatus paymentStatus;
  final DateTime? lastPaymentDate;
  final bool active; // visible ou non côté utilisateurs

  Pharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phone,
    this.whatsapp,
    required this.commune,
    required this.openingHours,
    this.isOnDuty = false,
    this.dutyStartDate,
    this.dutyEndDate,
    this.registrationStatus = RegistrationStatus.pending,
    required this.accountCreatedAt,
    this.freeTrialStartDate,
    this.paymentStatus = PaymentStatus.freeTrial,
    this.lastPaymentDate,
    this.active = false,
  });

  /// Visible côté app utilisateur : validée + pas suspendue
  bool get isVisibleToUsers =>
      registrationStatus == RegistrationStatus.validated &&
      paymentStatus != PaymentStatus.suspended;

  /// Peut-elle modifier son stock ? Non si en période de grâce impayée.
  bool get canEditStock => paymentStatus != PaymentStatus.unpaidGracePeriod &&
      paymentStatus != PaymentStatus.suspended;

  factory Pharmacy.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Pharmacy(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      phone: data['phone'] ?? '',
      whatsapp: data['whatsapp'],
      commune: data['commune'] ?? '',
      openingHours: data['openingHours'] ?? '',
      isOnDuty: data['isOnDuty'] ?? false,
      dutyStartDate: (data['dutyStartDate'] as Timestamp?)?.toDate(),
      dutyEndDate: (data['dutyEndDate'] as Timestamp?)?.toDate(),
      registrationStatus: RegistrationStatus.values.firstWhere(
        (e) => e.name == (data['registrationStatus'] ?? 'pending'),
        orElse: () => RegistrationStatus.pending,
      ),
      accountCreatedAt:
          (data['accountCreatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      freeTrialStartDate: (data['freeTrialStartDate'] as Timestamp?)?.toDate(),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == (data['paymentStatus'] ?? 'freeTrial'),
        orElse: () => PaymentStatus.freeTrial,
      ),
      lastPaymentDate: (data['lastPaymentDate'] as Timestamp?)?.toDate(),
      active: data['active'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'whatsapp': whatsapp,
      'commune': commune,
      'openingHours': openingHours,
      'isOnDuty': isOnDuty,
      'dutyStartDate':
          dutyStartDate != null ? Timestamp.fromDate(dutyStartDate!) : null,
      'dutyEndDate':
          dutyEndDate != null ? Timestamp.fromDate(dutyEndDate!) : null,
      'registrationStatus': registrationStatus.name,
      'accountCreatedAt': Timestamp.fromDate(accountCreatedAt),
      'freeTrialStartDate': freeTrialStartDate != null
          ? Timestamp.fromDate(freeTrialStartDate!)
          : null,
      'paymentStatus': paymentStatus.name,
      'lastPaymentDate':
          lastPaymentDate != null ? Timestamp.fromDate(lastPaymentDate!) : null,
      'active': active,
    };
  }
}
