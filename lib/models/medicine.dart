import 'package:cloud_firestore/cloud_firestore.dart';

class Medicine {
  final String id;
  final String genericName; // ex: Paracétamol
  final List<String> commercialNames; // ex: [Doliprane, Efferalgan]
  final String category; // antidouleur, antibiotique, antipaludéen...
  final String form; // comprimé, sirop, injectable...
  final bool prescriptionRequired;
  final String? imageReference;
  final List<String> equivalentIds; // ids d'autres Medicine, validés par un pharmacien

  Medicine({
    required this.id,
    required this.genericName,
    this.commercialNames = const [],
    required this.category,
    required this.form,
    this.prescriptionRequired = false,
    this.imageReference,
    this.equivalentIds = const [],
  });

  /// Tous les noms sous lesquels ce médicament peut être recherché
  List<String> get searchableNames => [genericName, ...commercialNames];

  factory Medicine.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Medicine(
      id: doc.id,
      genericName: data['genericName'] ?? '',
      commercialNames: List<String>.from(data['commercialNames'] ?? []),
      category: data['category'] ?? '',
      form: data['form'] ?? '',
      prescriptionRequired: data['prescriptionRequired'] ?? false,
      imageReference: data['imageReference'],
      equivalentIds: List<String>.from(data['equivalentIds'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'genericName': genericName,
      'commercialNames': commercialNames,
      'category': category,
      'form': form,
      'prescriptionRequired': prescriptionRequired,
      'imageReference': imageReference,
      'equivalentIds': equivalentIds,
      // Champ utilisé pour la recherche insensible à la casse côté Firestore
      'searchKeywords': [
        genericName.toLowerCase(),
        ...commercialNames.map((n) => n.toLowerCase()),
      ],
    };
  }
}
