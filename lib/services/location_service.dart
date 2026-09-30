import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationService {
  /// Demande la position actuelle de l'utilisateur (avec gestion des
  /// permissions). Lève une exception explicite si refusée.
  static Future<Position> getCurrentPosition() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied) {
        throw Exception('Permission de localisation refusée');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Permission de localisation bloquée définitivement. '
          'Activez-la dans les paramètres du téléphone.');
    }
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Distance en kilomètres entre deux points GPS (formule de Haversine).
  static double distanceKm(
      double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * (pi / 180);

  /// Ouvre Google Maps en mode navigation vers la pharmacie.
  /// Approche recommandée : on ne construit pas de navigation maison,
  /// on délègue le guidage temps réel à Google Maps (plus robuste).
  static Future<void> openNavigationTo({
    required double destLat,
    required double destLng,
  }) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception("Impossible d'ouvrir Google Maps");
    }
  }

  static Future<void> callPharmacy(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static Future<void> openWhatsApp(String phoneNumber) async {
    // phoneNumber au format international sans "+" (ex: 243812345678)
    final uri = Uri.parse('https://wa.me/$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
