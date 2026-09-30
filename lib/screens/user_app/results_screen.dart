import 'package:flutter/material.dart';
import '../../models/medicine.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import 'pharmacy_detail_screen.dart';

enum SortOption { distance, lastUpdated }

class ResultsScreen extends StatefulWidget {
  final Medicine medicine;
  const ResultsScreen({super.key, required this.medicine});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final _firestoreService = FirestoreService();

  bool _onDutyOnly = false;
  double? _radiusKm; // null = toute la ville
  SortOption _sortOption = SortOption.distance;

  Future<List<PharmacyResult>>? _futureResults;
  bool _searchedEquivalents = false;
  List<Medicine> _equivalents = [];

  @override
  void initState() {
    super.initState();
    _runSearch();
  }

  Future<void> _runSearch() async {
    setState(() {
      _futureResults = _loadResults();
    });
  }

  Future<List<PharmacyResult>> _loadResults() async {
    final position = await LocationService.getCurrentPosition();
    final results = await _firestoreService.findPharmaciesForMedicine(
      medicineId: widget.medicine.id,
      userLat: position.latitude,
      userLng: position.longitude,
      onDutyOnly: _onDutyOnly,
      maxRadiusKm: _radiusKm,
    );

    if (_sortOption == SortOption.lastUpdated) {
      results.sort(
          (a, b) => b.stockItem.lastUpdated.compareTo(a.stockItem.lastUpdated));
    }
    // Le tri par distance et priorité "garde" est déjà géré côté service.

    return results;
  }

  Future<void> _loadEquivalents() async {
    final equivalents =
        await _firestoreService.getEquivalents(widget.medicine.equivalentIds);
    setState(() {
      _searchedEquivalents = true;
      _equivalents = equivalents;
    });
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Pharmacies de garde'),
            selected: _onDutyOnly,
            onSelected: (v) {
              setState(() => _onDutyOnly = v);
              _runSearch();
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('1 km'),
            selected: _radiusKm == 1,
            onSelected: (v) {
              setState(() => _radiusKm = v ? 1 : null);
              _runSearch();
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('3 km'),
            selected: _radiusKm == 3,
            onSelected: (v) {
              setState(() => _radiusKm = v ? 3 : null);
              _runSearch();
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('5 km'),
            selected: _radiusKm == 5,
            onSelected: (v) {
              setState(() => _radiusKm = v ? 5 : null);
              _runSearch();
            },
          ),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.sort, size: 18),
            label: Text(_sortOption == SortOption.distance
                ? 'Trier: Distance'
                : 'Trier: Récence'),
            onPressed: () {
              setState(() {
                _sortOption = _sortOption == SortOption.distance
                    ? SortOption.lastUpdated
                    : SortOption.distance;
              });
              _runSearch();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    if (!_searchedEquivalents) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'Le médicament "${widget.medicine.genericName}" est '
                'indisponible dans les pharmacies proches de vous.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (widget.medicine.equivalentIds.isNotEmpty) ...[
                const Text('Voulez-vous qu\'on vous suggère un équivalent ?'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _loadEquivalents,
                      child: const Text('Oui, voir les équivalents'),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Non merci'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (_equivalents.isEmpty) {
      return const Center(
        child: Text('Aucun équivalent validé disponible pour ce médicament.'),
      );
    }

    return ListView.builder(
      itemCount: _equivalents.length,
      itemBuilder: (context, index) {
        final eq = _equivalents[index];
        return ListTile(
          title: Text(eq.genericName),
          subtitle: const Text('Équivalent suggéré'),
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ResultsScreen(medicine: eq),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.medicine.genericName)),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: FutureBuilder<List<PharmacyResult>>(
              future: _futureResults,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur : ${snapshot.error}'));
                }
                final results = snapshot.data ?? [];
                if (results.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final r = results[index];
                    return _PharmacyResultTile(result: r);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PharmacyResultTile extends StatelessWidget {
  final PharmacyResult result;
  const _PharmacyResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final pharmacy = result.pharmacy;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Row(
          children: [
            Expanded(
                child: Text(pharmacy.name,
                    style: const TextStyle(fontWeight: FontWeight.bold))),
            if (pharmacy.isOnDuty)
              const Chip(
                label: Text('De garde', style: TextStyle(fontSize: 11)),
                backgroundColor: Colors.indigo,
                labelStyle: TextStyle(color: Colors.white),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        subtitle: Text(
          '${pharmacy.commune} · ${result.distanceKm.toStringAsFixed(1)} km\n'
          '💊 Disponible'
          '${result.stockItem.isStale ? " (info à vérifier)" : ""}',
        ),
        isThreeLine: true,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PharmacyDetailScreen(
              pharmacy: pharmacy,
              stockItem: result.stockItem,
            ),
          ),
        ),
      ),
    );
  }
}
