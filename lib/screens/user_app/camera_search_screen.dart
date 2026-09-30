import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/medicine.dart';
import '../../services/ocr_service.dart';

class CameraSearchScreen extends StatefulWidget {
  const CameraSearchScreen({super.key});

  @override
  State<CameraSearchScreen> createState() => _CameraSearchScreenState();
}

class _CameraSearchScreenState extends State<CameraSearchScreen> {
  final _ocrService = OcrService();
  final _picker = ImagePicker();

  File? _image;
  bool _loading = false;
  OcrResult? _result;

  Future<void> _takePhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() {
      _image = File(picked.path);
      _loading = true;
      _result = null;
    });

    final result = await _ocrService.recognizeFromImage(_image!);
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recherche par photo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!, height: 220, fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: Text(_image == null ? 'Prendre une photo' : 'Reprendre une photo'),
              onPressed: _loading ? null : _takePhoto,
            ),
            const SizedBox(height: 24),
            if (_loading) const CircularProgressIndicator(),
            if (_result != null) _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    final result = _result!;

    if (result.confident) {
      final medicine = result.matches.first;
      return Column(
        children: [
          Text('Médicament détecté : ${medicine.genericName}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, medicine),
            child: const Text('Voir les pharmacies disponibles'),
          ),
        ],
      );
    }

    if (result.matches.length > 1) {
      // Plusieurs correspondances possibles : on laisse l'utilisateur choisir,
      // on ne devine jamais à sa place.
      return Column(
        children: [
          const Text('Plusieurs correspondances possibles, laquelle correspond ?'),
          const SizedBox(height: 8),
          ...result.matches.map((m) => ListTile(
                title: Text(m.genericName),
                onTap: () => Navigator.pop(context, m),
              )),
        ],
      );
    }

    // Aucune correspondance fiable trouvée
    return Column(
      children: [
        const Icon(Icons.error_outline, color: Colors.orange, size: 40),
        const SizedBox(height: 8),
        const Text(
          'Aucune correspondance fiable trouvée.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: _loading ? null : _takePhoto,
              child: const Text('Réessayer une photo'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(context), // repli : saisie manuelle
              child: const Text('Taper le nom manuellement'),
            ),
          ],
        ),
      ],
    );
  }
}
