import 'package:flutter/material.dart';
import '../../models/medicine.dart';
import '../../models/stock_item.dart';
import '../../services/firestore_service.dart';

class AddStockItemScreen extends StatefulWidget {
  final String pharmacyId;
  const AddStockItemScreen({super.key, required this.pharmacyId});

  @override
  State<AddStockItemScreen> createState() => _AddStockItemScreenState();
}

class _AddStockItemScreenState extends State<AddStockItemScreen> {
  final _firestoreService = FirestoreService();
  final _searchController = TextEditingController();
  final _manufacturerController = TextEditingController();

  List<Medicine> _suggestions = [];
  Medicine? _selectedMedicine;
  DateTime? _expirationDate;
  StockStatus _status = StockStatus.available;
  bool _saving = false;

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    final results = await _firestoreService.searchMedicines(query);
    setState(() => _suggestions = results);
  }

  Future<void> _pickExpirationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _expirationDate = picked);
  }

  Future<void> _save() async {
    if (_selectedMedicine == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un médicament')),
      );
      return;
    }
    setState(() => _saving = true);

    final item = StockItem(
      id: '', // Firestore génère l'id à la création
      pharmacyId: widget.pharmacyId,
      medicineId: _selectedMedicine!.id,
      status: _status,
      manufacturer: _manufacturerController.text.trim(),
      expirationDate: _expirationDate,
      lastUpdated: DateTime.now(),
    );

    await _firestoreService.upsertStockItem(item);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un médicament')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _search,
              decoration: const InputDecoration(
                labelText: 'Rechercher un médicament',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            if (_selectedMedicine == null)
              ..._suggestions.map((m) => ListTile(
                    title: Text(m.genericName),
                    onTap: () => setState(() {
                      _selectedMedicine = m;
                      _suggestions = [];
                      _searchController.text = m.genericName;
                    }),
                  )),
            if (_selectedMedicine != null) ...[
              const SizedBox(height: 16),
              Text('Médicament sélectionné : ${_selectedMedicine!.genericName}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SegmentedButton<StockStatus>(
                segments: const [
                  ButtonSegment(
                      value: StockStatus.available, label: Text('Disponible')),
                  ButtonSegment(
                      value: StockStatus.outOfStock, label: Text('Épuisé')),
                ],
                selected: {_status},
                onSelectionChanged: (s) => setState(() => _status = s.first),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _manufacturerController,
                decoration: const InputDecoration(labelText: 'Fabricant'),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_expirationDate == null
                    ? "Date d'expiration"
                    : "Expire le ${_expirationDate!.day}/${_expirationDate!.month}/${_expirationDate!.year}"),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickExpirationDate,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator()
                    : const Text('Enregistrer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
