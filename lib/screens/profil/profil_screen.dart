import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/objectif_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/models.dart';
import '../../utils/app_constants.dart';
import '../../utils/export_service.dart';
import '../auth/login_screen.dart';
import '../categories_screen.dart';
import '../sync_settings_screen.dart';
import 'comptes_screen.dart';

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  bool _isStrongPassword(String value) {
    final hasUpper = RegExp(r'[A-Z]').hasMatch(value);
    final hasNumber = RegExp(r'[0-9]').hasMatch(value);
    return value.length >= 8 && hasUpper && hasNumber;
  }

  void _addObjectif(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _AddObjectifSheet(),
    );
  }

  void _editProfil(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;
    final nomCtrl = TextEditingController(text: user.nom);
    final prenomCtrl = TextEditingController(text: user.prenom);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier le profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: prenomCtrl,
                decoration: const InputDecoration(labelText: 'Prénom')),
            TextField(
                controller: nomCtrl,
                decoration: const InputDecoration(labelText: 'Nom')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              await auth.mettreAJourProfil(
                  nom: nomCtrl.text.trim(), prenom: prenomCtrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _changeMdp(BuildContext context) {
    final ancienCtrl = TextEditingController();
    final nouveauCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: ancienCtrl,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Ancien mot de passe')),
            TextField(
                controller: nouveauCtrl,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Nouveau mot de passe')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              if (!_isStrongPassword(nouveauCtrl.text)) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('Mot de passe faible'),
                      backgroundColor: Colors.red));
                }
                return;
              }
              final err = await context.read<AuthProvider>().changerMotDePasse(
                  ancien: ancienCtrl.text, nouveau: nouveauCtrl.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (err != null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                      content: Text(err), backgroundColor: Colors.red));
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('Mot de passe modifié'),
                      backgroundColor: Colors.green));
                }
              }
            },
            child: const Text('Changer'),
          ),
        ],
      ),
    );
  }

  void _changeDevise(BuildContext context) {
    const devises = ['FCFA', 'EUR', 'USD', 'GBP', 'XOF'];
    final auth = context.read<AuthProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choisir une devise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: devises
              .map((d) => ListTile(
                    title: Text(d),
                    selected: auth.currentUser?.devise == d,
                    selectedColor: AppConstants.primaryColor,
                    onTap: () async {
                      await auth.mettreAJourProfil(devise: d);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Déconnecter',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      // Réinitialiser tous les providers pour éviter les fuites de données
      context.read<CategoryProvider>().reset();
      context.read<CompteProvider>().reset();
      context.read<TransactionProvider>().reset();
      context.read<BudgetProvider>().reset();
      context.read<ObjectifProvider>().reset();
      context.read<AlertProvider>().reset();
      context.read<RecurrenceProvider>().reset();
      
      await context.read<AuthProvider>().deconnecter();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (r) => false);
      }
    }
  }

  void _exportData(BuildContext context) {
    final txProvider = context.read<TransactionProvider>();
    final devise = context.read<AuthProvider>().currentUser?.devise ?? 'FCFA';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Exporter les données',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ExportService().exportTransactionsCsv(
                    transactions: txProvider.transactions, devise: devise);
              },
              child: const Text('Exporter en CSV'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ExportService().exportTransactionsPdf(
                    transactions: txProvider.transactions, devise: devise);
              },
              child: const Text('Exporter en PDF'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _deleteAccount(BuildContext context) async {
    final confirm = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: const Text(
            'Cette action supprimera toutes vos données. Voulez-vous continuer ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, 'delete'),
              child:
                  const Text('Supprimer', style: TextStyle(color: Colors.red))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, 'export_delete'),
              child: const Text('Exporter puis supprimer')),
        ],
      ),
    );
    if (confirm == 'export_delete' && context.mounted) {
      _exportData(context);
      await Future.delayed(const Duration(milliseconds: 400));
    }
    if ((confirm == 'delete' || confirm == 'export_delete') &&
        context.mounted) {
      await context.read<AuthProvider>().supprimerCompte();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (r) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final objectifProvider = context.watch<ObjectifProvider>();
    final user = auth.currentUser;
    final devise = user?.devise ?? 'FCFA';

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle),
              child: const Icon(Icons.person_rounded,
                  size: 48, color: AppConstants.primaryColor),
            ),
            const SizedBox(height: 12),
            Text('${user?.prenom ?? ''} ${user?.nom ?? ''}',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(user?.email ?? '', style: const TextStyle(color: Colors.grey)),
            Text('Devise: $devise',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 24),
            // Objectifs section
            _SectionHeader(
                title: 'Objectifs d\'épargne',
                icon: Icons.savings_rounded,
                onAdd: () => _addObjectif(context)),
            if (objectifProvider.objectifs.isEmpty)
            const _EmptyCard(message: 'Aucun objectif défini')
            else
              ...objectifProvider.objectifs
                  .map((o) => _ObjectifCard(objectif: o, devise: devise)),
            const SizedBox(height: 20),
            // Settings
            const _SectionTitle(title: 'Paramètres'),
            _SettingTile(
                icon: Icons.person_outline_rounded,
                label: 'Modifier le profil',
                onTap: () => _editProfil(context)),
            _SettingTile(
                icon: Icons.category_outlined,
                label: 'Gérer les catégories',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CategoriesScreen()))),
            _SettingTile(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Mes Comptes (Mobile Money)',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ComptesScreen()))),
            _SettingTile(
                icon: Icons.lock_outline_rounded,
                label: 'Changer le mot de passe',
                onTap: () => _changeMdp(context)),
            _SettingTile(
                icon: Icons.currency_exchange_rounded,
                label: 'Changer la devise',
                onTap: () => _changeDevise(context)),
            _SettingTile(
                icon: Icons.file_download_outlined,
                label: 'Exporter les données',
                onTap: () => _exportData(context)),
            _SettingTile(
                icon: Icons.sync_rounded,
                label: 'Synchronisation cloud',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SyncSettingsScreen()))),
            _SettingTile(
                icon: Icons.delete_outline_rounded,
                label: 'Supprimer le compte',
                color: Colors.red,
                onTap: () => _deleteAccount(context)),
            const SizedBox(height: 8),
            _SettingTile(
                icon: Icons.logout_rounded,
                label: 'Se déconnecter',
                color: Colors.red,
                onTap: () => _logout(context)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onAdd;

  const _SectionHeader(
      {required this.title, required this.icon, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppConstants.primaryColor),
          const SizedBox(width: 8),
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const Spacer(),
          GestureDetector(
              onTap: onAdd,
              child: const Icon(Icons.add_circle_rounded,
                  color: AppConstants.primaryColor, size: 24)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
          alignment: Alignment.centerLeft,
          child: Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
    );
  }
}

class _ObjectifCard extends StatelessWidget {
  final Objectif objectif;
  final String devise;

  const _ObjectifCard({required this.objectif, required this.devise});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(objectif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
            color: Colors.red, borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) =>
          context.read<ObjectifProvider>().supprimer(objectif.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
            ]),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color:
                          AppConstants.secondaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.savings_rounded,
                      color: AppConstants.secondaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(objectif.nom,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                          'Échéance: ${AppHelpers.formatDate(objectif.dateEcheance)}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: objectif.statut == 'atteint'
                          ? Colors.green.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(
                      objectif.statut == 'atteint'
                          ? '✓ Atteint'
                          : '${(objectif.pourcentage * 100).toInt()}%',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: objectif.statut == 'atteint'
                              ? Colors.green
                              : Colors.grey)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
                value: objectif.pourcentage,
                backgroundColor: Colors.grey.shade200,
                color: AppConstants.secondaryColor,
                borderRadius: BorderRadius.circular(4),
                minHeight: 8),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppHelpers.formatMontant(objectif.montantActuel, devise),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500)),
                Text(
                    '/ ${AppHelpers.formatMontant(objectif.montantCible, devise)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            if (objectif.statut == 'en_cours') ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _alimenterObjectif(context, objectif),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                      color: AppConstants.secondaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppConstants.secondaryColor
                              .withValues(alpha: 0.3))),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded,
                          size: 16, color: AppConstants.secondaryColor),
                      SizedBox(width: 4),
                      Text('Alimenter',
                          style: TextStyle(
                              color: AppConstants.secondaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _alimenterObjectif(BuildContext context, Objectif objectif) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Alimenter: ${objectif.nom}'),
        content: TextField(
            controller: ctrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9\s,\.]')),
            ],
            decoration:
                const InputDecoration(labelText: 'Montant à ajouter')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              final montant = AppHelpers.parseMontant(ctrl.text);
              if (montant != null && montant > 0) {
                await ctx
                    .read<ObjectifProvider>()
                    .alimenter(objectif.id, montant);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200)),
      child: Center(
          child: Text(message,
              style: const TextStyle(color: Colors.grey, fontSize: 13))),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _SettingTile(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppConstants.primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
            ]),
        child: Row(
          children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 20, color: c)),
            const SizedBox(width: 14),
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 14, color: c))),
            Icon(Icons.chevron_right_rounded, color: c.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _AddObjectifSheet extends StatefulWidget {
  const _AddObjectifSheet();

  @override
  State<_AddObjectifSheet> createState() => _AddObjectifSheetState();
}

class _AddObjectifSheetState extends State<_AddObjectifSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  DateTime _echeance = DateTime.now().add(const Duration(days: 90));

  @override
  void dispose() {
    _nomCtrl.dispose();
    _montantCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final objProvider = context.read<ObjectifProvider>();
    final auth = context.read<AuthProvider>();
    final montant = AppHelpers.parseMontant(_montantCtrl.text);
    if (montant == null || montant <= 0) return;
    await objProvider.ajouter(
      nom: _nomCtrl.text.trim(),
      montantCible: montant,
      dateEcheance: _echeance,
      userId: auth.currentUser!.id,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nouvel objectif d\'épargne',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextFormField(
                controller: _nomCtrl,
                decoration:
                    const InputDecoration(labelText: 'Nom de l\'objectif'),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null),
            const SizedBox(height: 16),
            TextFormField(
              controller: _montantCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9\s,\.]')),
              ],
              decoration: InputDecoration(
                  labelText: 'Montant cible',
                  suffixText:
                      context.read<AuthProvider>().currentUser?.devise ??
                          'FCFA'),
              validator: (v) =>
                  v == null || AppHelpers.parseMontant(v) == null
                  ? 'Montant invalide'
                  : null,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _echeance,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                  builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: AppConstants.primaryColor)),
                      child: child!),
                );
                if (picked != null) setState(() => _echeance = picked);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: AppConstants.primaryColor, size: 20),
                    const SizedBox(width: 12),
                    Text('Échéance: ${AppHelpers.formatDate(_echeance)}',
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: _save, child: const Text('Créer l\'objectif')),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
