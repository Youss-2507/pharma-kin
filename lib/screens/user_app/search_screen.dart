import 'package:flutter/material.dart';
import '../../models/medicine.dart';
import '../../services/firestore_service.dart';
import 'results_screen.dart';
import 'camera_search_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _firestoreService = FirestoreService();
  List<Medicine> _suggestions = [];
  bool _loading = false;

  Future<void> _onQueryChanged(String query) async {
    if (query.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() => _loading = true);
    final results = await _firestoreService.searchMedicines(query);
    setState(() {
      _suggestions = results;
      _loading = false;
    });
  }

  void _openResults(Medicine medicine) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsScreen(medicine: medicine),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trouver un médicament')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                hintText: 'Ex: Paracétamol, Doliprane...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text("Chercher à partir d'une photo"),
              onPressed: () async {
                final medicine = await Navigator.push<Medicine>(
                  context,
                  MaterialPageRoute(builder: (_) => const CameraSearchScreen()),
                );
                if (medicine != null) _openResults(medicine);
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final medicine = _suggestions[index];
                  return ListTile(
                    title: Text(medicine.genericName),
                    subtitle: medicine.commercialNames.isNotEmpty
                        ? Text(medicine.commercialNames.join(', '))
                        : null,
                    trailing: medicine.prescriptionRequired
                        ? const Icon(Icons.receipt_long, size: 18)
                        : null,
                    onTap: () => _openResults(medicine),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
