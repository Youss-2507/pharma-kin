import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/pharmacy.dart';

class PharmacyRegisterScreen extends StatefulWidget {
  const PharmacyRegisterScreen({super.key});

  @override
  State<PharmacyRegisterScreen> createState() => _PharmacyRegisterScreenState();
}

class _PharmacyRegisterScreenState extends State<PharmacyRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _commune = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _submitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      // 1. Créer le compte d'authentification du pharmacien
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );

      // 2. Créer la fiche pharmacie en statut "en attente"
      //    NB: latitude/longitude à géocoder depuis l'adresse côté serveur,
      //    ou saisies manuellement ici via une future étape "localiser sur la carte".
      final pharmacy = Pharmacy(
        id: cred.user!.uid,
        name: _name.text.trim(),
        address: _address.text.trim(),
        latitude: 0,
        longitude: 0,
        phone: _phone.text.trim(),
        commune: _commune.text.trim(),
        openingHours: '',
        registrationStatus: RegistrationStatus.pending,
        accountCreatedAt: DateTime.now(),
        paymentStatus: PaymentStatus.freeTrial,
        active: false,
      );

      await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(cred.user!.uid)
          .set(pharmacy.toFirestore());

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Inscription envoyée'),
            content: const Text(
              'Votre demande a été transmise. Elle sera examinée avant '
              'activation de votre compte. Vous recevrez une notification '
              'une fois validée.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? 'Erreur')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inscrire ma pharmacie')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nom de la pharmacie'),
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Adresse'),
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
              TextFormField(
                controller: _commune,
                decoration: const InputDecoration(labelText: 'Commune'),
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Téléphone'),
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
              ),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email (identifiant)'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@')) ? 'Email invalide' : null,
              ),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(labelText: 'Mot de passe'),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.length < 6) ? '6 caractères minimum' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const CircularProgressIndicator()
                    : const Text('Envoyer ma demande'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
