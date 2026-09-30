import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/user_app/search_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Utilise la configuration native (android/app/google-services.json).
  // Si le fichier n'est pas encore en place, l'app se lance quand même
  // mais toutes les fonctionnalités liées à Firebase échoueront —
  // utile pour tester l'interface avant d'avoir fini la config Firebase.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase non configuré pour le moment : $e');
  }

  runApp(const PharmaKinApp());
}

class PharmaKinApp extends StatelessWidget {
  const PharmaKinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pharma Kin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: const SearchScreen(),
    );
  }
}
