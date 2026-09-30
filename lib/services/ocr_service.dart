import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/medicine.dart';
import 'firestore_service.dart';

/// Reconnaissance du texte imprimé sur une boîte/blister de médicament.
/// Tourne entièrement sur le téléphone (ML Kit) : fonctionne hors-ligne,
/// aucune photo n'est envoyée à un serveur.
///
/// Choix assumé : on ne tente PAS de reconnaître un comprimé nu par sa
/// forme/couleur (peu fiable, risque médical). Si l'OCR ne trouve pas de
/// correspondance fiable, on redirige vers la saisie manuelle plutôt que
/// de deviner.
class OcrResult {
  final String rawText;
  final List<Medicine> matches;
  final bool confident;

  OcrResult({required this.rawText, required this.matches, required this.confident});
}

class OcrService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _firestoreService = FirestoreService();

  Future<OcrResult> recognizeFromImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    final rawText = recognizedText.text;

    if (rawText.trim().isEmpty) {
      return OcrResult(rawText: '', matches: [], confident: false);
    }

    // On extrait les mots "candidats" (longueur >= 4, alphabétiques) car
    // le nom du médicament est rarement le premier mot lu sur l'emballage.
    final candidateWords = rawText
        .split(RegExp(r'[\s,;:/\\\n]+'))
        .where((w) => w.length >= 4)
        .where((w) => RegExp(r'^[a-zA-ZÀ-ÿ]+$').hasMatch(w))
        .toList();

    final allMatches = <Medicine>[];
    for (final word in candidateWords) {
      final results = await _firestoreService.searchMedicines(word);
      for (final m in results) {
        if (!allMatches.any((existing) => existing.id == m.id)) {
          allMatches.add(m);
        }
      }
    }

    // On considère le résultat "confiant" seulement si on a UNE correspondance
    // nette. Plusieurs correspondances ambiguës => on préfère laisser
    // l'utilisateur choisir ou ressaisir, jamais deviner silencieusement.
    final confident = allMatches.length == 1;

    return OcrResult(
      rawText: rawText,
      matches: allMatches,
      confident: confident,
    );
  }

  void dispose() {
    _textRecognizer.close();
  }
}
