import 'package:flutter/material.dart';
import '../../models/pharmacy.dart';
import '../../models/stock_item.dart';
import '../../services/location_service.dart';

class PharmacyDetailScreen extends StatelessWidget {
  final Pharmacy pharmacy;
  final StockItem stockItem;

  const PharmacyDetailScreen({
    super.key,
    required this.pharmacy,
    required this.stockItem,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = (DateTime d) => '${d.day}/${d.month}/${d.year}';

    return Scaffold(
      appBar: AppBar(title: Text(pharmacy.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pharmacy.isOnDuty)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.nightlight_round, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text('Pharmacie de garde actuellement'),
                ],
              ),
            ),
          _InfoRow(icon: Icons.location_on, text: pharmacy.address),
          _InfoRow(icon: Icons.map, text: pharmacy.commune),
          _InfoRow(icon: Icons.access_time, text: pharmacy.openingHours),
          const Divider(height: 32),
          const Text('Détail du produit',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.check_circle,
            text: stockItem.status.name == 'available'
                ? 'Disponible'
                : 'Épuisé',
          ),
          if (stockItem.manufacturer.isNotEmpty)
            _InfoRow(icon: Icons.factory, text: 'Fabricant : ${stockItem.manufacturer}'),
          if (stockItem.expirationDate != null)
            _InfoRow(
              icon: Icons.event,
              text:
                  'Expire le : ${dateFormat(stockItem.expirationDate!)}',
            ),
          _InfoRow(
            icon: Icons.update,
            text:
                'Mis à jour le ${dateFormat(stockItem.lastUpdated)}'
                '${stockItem.isStale ? " — information à vérifier auprès de la pharmacie" : ""}',
          ),
          const Divider(height: 32),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Le prix n\'est pas affiché dans l\'application. '
              'Contactez la pharmacie pour le connaître.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.call),
                  label: const Text('Appeler'),
                  onPressed: () => LocationService.callPharmacy(pharmacy.phone),
                ),
              ),
              if (pharmacy.whatsapp != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.chat),
                    label: const Text('WhatsApp'),
                    onPressed: () =>
                        LocationService.openWhatsApp(pharmacy.whatsapp!),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.directions),
              label: const Text('Itinéraire (navigation Google Maps)'),
              onPressed: () => LocationService.openNavigationTo(
                destLat: pharmacy.latitude,
                destLng: pharmacy.longitude,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
