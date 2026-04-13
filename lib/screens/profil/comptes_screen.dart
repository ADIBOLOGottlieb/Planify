import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/compte_provider.dart';
import '../../utils/app_constants.dart';

class ComptesScreen extends StatelessWidget {
  const ComptesScreen({super.key});

  void _showAddCompte(BuildContext context) {
    final nomCtrl = TextEditingController();
    final soldeCtrl = TextEditingController();
    String icone = 'account_balance_wallet_rounded';
    String couleur = '#2ECC71';
    String selectedProvider = 'TMoney';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConstants.bgColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Nouveau Compte Mobile Money',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedProvider,
                decoration: const InputDecoration(labelText: 'Fournisseur'),
                items: ['TMoney', 'Flooz', 'Mixx by Yas', 'Autre']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    selectedProvider = v!;
                    nomCtrl.text = v;
                    if (v == 'TMoney') {
                      couleur = '#E53935'; // Red-ish for TMoney
                    } else if (v == 'Flooz') {
                      couleur = '#FB8C00'; // Orange for Flooz/Moov
                    } else if (v == 'Mixx by Yas') {
                      couleur = '#1E88E5'; // Blue for Mixx
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nomCtrl,
                decoration: const InputDecoration(labelText: 'Nom du compte'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: soldeCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Solde actuel',
                  suffixText: context.read<AuthProvider>().currentUser?.devise ?? 'FCFA',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final solde = double.tryParse(soldeCtrl.text) ?? 0;
                  String? operateur;
                  if (selectedProvider == 'TMoney') operateur = 'TMoney';
                  if (selectedProvider == 'Flooz') operateur = 'Flooz';
                  if (selectedProvider == 'Mixx by Yas') operateur = 'Yas';
                  
                  context.read<CompteProvider>().ajouter(
                        nom: nomCtrl.text.isEmpty ? selectedProvider : nomCtrl.text,
                        solde: solde,
                        icone: icone,
                        couleur: couleur,
                        operateur: operateur,
                        userId: context.read<AuthProvider>().currentUser!.id,
                      );
                  Navigator.pop(ctx);
                },
                child: const Text('Ajouter'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes Comptes')),
      body: Consumer<CompteProvider>(
        builder: (context, provider, child) {
          final items = provider.items;
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 64, color: Colors.grey.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text('Aucun compte configuré',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _showAddCompte(context),
                    child: const Text('Ajouter un compte'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return Card(
                color: AppConstants.surfaceColor,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppHelpers.hexToColor(item.couleur),
                    child: const Icon(Icons.account_balance_wallet_rounded,
                        color: Colors.white),
                  ),
                  title: Text(item.nom,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Solde actuel'),
                  trailing: Text(
                    AppHelpers.formatMontant(item.solde,
                        context.read<AuthProvider>().currentUser?.devise ?? 'FCFA'),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                        fontSize: 16),
                  ),
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Supprimer le compte ?'),
                        content: const Text(
                            'Voulez-vous vraiment supprimer ce compte ? Les transactions liées ne seront pas supprimées mais ne seront plus rattachées.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Annuler')),
                          TextButton(
                            onPressed: () {
                              provider.supprimer(item.id);
                              Navigator.pop(ctx);
                            },
                            child: const Text('Supprimer',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCompte(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
