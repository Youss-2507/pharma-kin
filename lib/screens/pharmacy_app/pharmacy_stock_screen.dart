import 'package:flutter/material.dart';
import '../../models/pharmacy.dart';
import '../../models/medicine.dart';
import '../../models/stock_item.dart';
import '../../services/firestore_service.dart';
import 'add_stock_item_screen.dart';

class PharmacyStockScreen extends StatefulWidget {
  final Pharmacy pharmacy;
  const PharmacyStockScreen({super.key, required this.pharmacy});

  @override
  State<PharmacyStockScreen> createState() => _PharmacyStockScreenState();
}

class _PharmacyStockScreenState extends State<PharmacyStockScreen> {
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final canEdit = widget.pharmacy.canEditStock;

    return Scaffold(
      appBar: AppBar(title: const Text('Mon stock')),
      body: Column(
        children: [
          if (!canEdit)
            Container(
              width: double.infinity,
              color: Colors.red.shade50,
              padding: const EdgeInsets.all(12),
              child: const Text(
                'Paiement en attente : votre stock est visible par les '
                'utilisateurs mais vous ne pouvez plus le modifier. '
                'Réglez votre abonnement pour réactiver la modification.',
                style: TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<StockItem>>(
              stream: _firestoreService.watchPharmacyStock(widget.pharmacy.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data!;
                if (items.isEmpty) {
                  return const Center(
                    child: Text('Aucun médicament ajouté pour le moment.'),
                  );
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _StockItemTile(
                      item: item,
                      canEdit: canEdit,
                      onToggle: (newStatus) async {
                        final updated = StockItem(
                          id: item.id,
                          pharmacyId: item.pharmacyId,
                          medicineId: item.medicineId,
                          status: newStatus,
                          manufacturer: item.manufacturer,
                          expirationDate: item.expirationDate,
                          lastUpdated: DateTime.now(),
                        );
                        await _firestoreService.upsertStockItem(updated);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un médicament'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AddStockItemScreen(pharmacyId: widget.pharmacy.id),
                ),
              ),
            )
          : null,
    );
  }
}

class _StockItemTile extends StatelessWidget {
  final StockItem item;
  final bool canEdit;
  final void Function(StockStatus newStatus) onToggle;

  const _StockItemTile({
    required this.item,
    required this.canEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = item.status == StockStatus.available;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        // NB : dans une vraie intégration, on résout ici le nom du
        // médicament via son medicineId (jointure ou cache local).
        title: Text('Médicament #${item.medicineId}'),
        subtitle: Text(
          'Fabricant : ${item.manufacturer.isEmpty ? "—" : item.manufacturer}\n'
          '${item.expirationDate != null ? "Expire le ${item.expirationDate!.day}/${item.expirationDate!.month}/${item.expirationDate!.year}" : ""}'
          '${item.isExpiringSoon ? "  ⚠️ Bientôt périmé" : ""}',
        ),
        isThreeLine: true,
        trailing: Switch(
          value: isAvailable,
          onChanged: canEdit
              ? (v) => onToggle(v ? StockStatus.available : StockStatus.outOfStock)
              : null,
        ),
      ),
    );
  }
}
