import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/alert_provider.dart';
import '../../providers/compte_provider.dart';
import '../../models/models.dart';
import '../../utils/app_constants.dart';
import '../../utils/ussd_service.dart';
import '../../utils/receipt_service.dart';
import 'dart:io';

class AddTransactionScreen extends StatefulWidget {
  final String initialType;
  final Transaction? transaction;
  const AddTransactionScreen(
      {super.key, this.initialType = 'depense', this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _type;
  final _montantCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  String _modePaiement = 'especes';
  String? _categorieId;
  String? _compteId;
  String? _justificatifPath;

  // USSD related
  bool _viaUssd = false;
  String _ussdType = 'credit'; // 'credit', 'transfert', 'mixx'
  final _numeroDestCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    if (widget.transaction != null) {
      final t = widget.transaction!;
      _montantCtrl.text = t.montant.toStringAsFixed(0);
      _descriptionCtrl.text = t.description ?? '';
      _date = t.dateTransaction;
      _modePaiement = t.modePaiement;
      _categorieId = t.categorieId;
      _compteId = t.compteId;
      _justificatifPath = t.justificatif;
    }
  }

  @override
  void dispose() {
    _montantCtrl.dispose();
    _descriptionCtrl.dispose();
    _numeroDestCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _categorieId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez remplir tous les champs')));
      return;
    }

    final montant = AppHelpers.parseMontant(_montantCtrl.text);
    if (montant == null || montant <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Montant invalide')));
      return;
    }

    final auth = context.read<AuthProvider>();
    final txProvider = context.read<TransactionProvider>();
    final catProvider = context.read<CategoryProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    final alertProvider = context.read<AlertProvider>();
    final compteProvider = context.read<CompteProvider>();

    // Déclencher USSD si activé
    if (widget.transaction == null && _viaUssd && _compteId != null) {
      final compte = compteProvider.findById(_compteId);
      if (compte != null && compte.operateur != null) {
        if (_ussdType == 'credit') {
          await UssdService.lancerAchatCredit(
            operateur: compte.operateur!,
            montant: montant,
          );
        } else if (_ussdType == 'transfert') {
          if (_numeroDestCtrl.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Numéro destinataire requis')));
            return;
          }
          await UssdService.lancerTransfert(
            operateur: compte.operateur!,
            montant: montant,
            numero: _numeroDestCtrl.text,
          );
        } else if (_ussdType == 'mixx') {
          await UssdService.lancerForfaitMixx(
            operateur: compte.operateur!,
            typeForfait: montant.toStringAsFixed(0),
          );
        }
      }
    }

    if (widget.transaction != null) {
      final updated = Transaction(
        id: widget.transaction!.id,
        montant: montant,
        type: _type,
        dateTransaction: _date,
        description: _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
        modePaiement: _modePaiement,
        justificatif: _justificatifPath,
        categorieId: _categorieId!,
        compteId: _compteId,
        utilisateurId: auth.currentUser!.id,
        dateCreation: widget.transaction!.dateCreation,
      );
      updated.categorie = catProvider.findById(_categorieId!);
      await txProvider.modifier(updated, compteProvider: compteProvider);
    } else {
      await txProvider.ajouter(
        montant: montant,
        type: _type,
        date: _date,
        description: _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
        modePaiement: _modePaiement,
        justificatif: _justificatifPath,
        categorieId: _categorieId!,
        compteId: _compteId,
        userId: auth.currentUser!.id,
        catProvider: catProvider,
        compteProvider: compteProvider,
      );
    }

    budgetProvider.rafraichirDepenses(txProvider,
        alertProvider: alertProvider,
        userId: auth.currentUser!.id,
        emitAlerts: true);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
              colorScheme:
                  const ColorScheme.light(primary: AppConstants.primaryColor)),
          child: child!),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final catProvider = context.watch<CategoryProvider>();
    final categories = _type == 'depense'
        ? catProvider.depenseCategories
        : catProvider.revenuCategories;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction != null
            ? 'Modifier la transaction'
            : 'Nouvelle transaction'),
        backgroundColor: _type == 'depense'
            ? AppConstants.depenseColor
            : AppConstants.revenuColor,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type toggle
              Container(
                decoration: BoxDecoration(
                    color: AppConstants.surfaceColor,
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Expanded(
                        child: _TypeButton(
                            label: 'Dépense',
                            selected: _type == 'depense',
                            color: AppConstants.depenseColor,
                            onTap: () => setState(() {
                                  _type = 'depense';
                                  _categorieId = null;
                                }))),
                    Expanded(
                        child: _TypeButton(
                            label: 'Revenu',
                            selected: _type == 'revenu',
                            color: AppConstants.revenuColor,
                            onTap: () => setState(() {
                                  _type = 'revenu';
                                  _categorieId = null;
                                }))),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Amount
              TextFormField(
                controller: _montantCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[0-9\s,\.]')),
                ],
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Montant',
                  suffixText:
                      context.read<AuthProvider>().currentUser?.devise ??
                          'FCFA',
                  suffixStyle: const TextStyle(fontWeight: FontWeight.w500),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Montant requis';
                  final parsed = AppHelpers.parseMontant(v);
                  if (parsed == null) {
                    return 'Montant invalide';
                  }
                  if (parsed <= 0) {
                    return 'Montant doit être positif';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Date
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                      color: AppConstants.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15))),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: AppConstants.primaryColor, size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Date',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(AppHelpers.formatDate(_date),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Category
              const Text('Catégorie',
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final selected = _categorieId == cat.id;
                  final color = AppHelpers.hexToColor(cat.couleur);
                  return GestureDetector(
                    onTap: () => setState(() => _categorieId = cat.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? color : color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: selected
                                ? color
                                : color.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(AppHelpers.getCategoryIcon(cat.icone),
                              size: 16, color: selected ? Colors.white : color),
                          const SizedBox(width: 6),
                          Text(cat.nom,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: selected ? Colors.white : color)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Description
              TextFormField(
                controller: _descriptionCtrl,
                decoration: const InputDecoration(
                    labelText: 'Description (optionnel)',
                    prefixIcon: Icon(Icons.notes_rounded)),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              // Justificatif
              const Text('Justificatif',
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final path =
                          await ReceiptService().pickAndSaveReceipt();
                      if (path != null) {
                        setState(() => _justificatifPath = path);
                      }
                    },
                    icon: const Icon(Icons.photo_camera_rounded),
                    label: const Text('Ajouter un reçu'),
                  ),
                  const SizedBox(width: 12),
                  if (_justificatifPath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _justificatifPath!.startsWith('http')
                          ? Image.network(_justificatifPath!,
                              width: 48, height: 48, fit: BoxFit.cover)
                          : Image.file(File(_justificatifPath!),
                              width: 48, height: 48, fit: BoxFit.cover),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Mode de paiement
              DropdownButtonFormField<String>(
                value: _modePaiement,
                decoration: const InputDecoration(
                    labelText: 'Mode de paiement',
                    prefixIcon: Icon(Icons.payment_rounded)),
                items: const [
                  DropdownMenuItem(value: 'especes', child: Text('Espèces')),
                  DropdownMenuItem(
                      value: 'mobile_money', child: Text('Mobile Money')),
                  DropdownMenuItem(
                      value: 'virement', child: Text('Virement bancaire')),
                  DropdownMenuItem(
                      value: 'carte', child: Text('Carte bancaire')),
                ],
                onChanged: (v) => setState(() {
                  _modePaiement = v!;
                  if (_modePaiement != 'mobile_money') _compteId = null;
                }),
              ),
              if (_modePaiement == 'mobile_money') ...[
                const SizedBox(height: 16),
                Consumer<CompteProvider>(
                  builder: (context, provider, child) {
                    final comptes = provider.items;
                    if (comptes.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Aucun compte mobile money configuré. Allez dans les réglages pour en ajouter.',
                                style: TextStyle(fontSize: 12, color: Colors.amber),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return DropdownButtonFormField<String>(
                      value: _compteId,
                      decoration: const InputDecoration(
                          labelText: 'Sélectionner le compte',
                          prefixIcon: Icon(Icons.account_balance_wallet_rounded)),
                      items: comptes.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(c.nom),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _compteId = v),
                      validator: (v) => v == null ? 'Veuillez choisir un compte' : null,
                    );
                  },
                ),
                Consumer<CompteProvider>(builder: (context, provider, child) {
                  final selectedCompte = _compteId != null ? provider.findById(_compteId) : null;
                  if (selectedCompte == null || selectedCompte.operateur == null) return const SizedBox.shrink();
                  
                  return Column(
                    children: [
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Effectuer via USSD', style: TextStyle(fontSize: 14)),
                        subtitle: Text('Lancer le code ${selectedCompte.operateur} automatiquement'),
                        value: _viaUssd,
                        activeColor: AppConstants.primaryColor,
                        onChanged: (v) => setState(() => _viaUssd = v),
                      ),
                      if (_viaUssd) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _ussdType,
                          decoration: const InputDecoration(labelText: 'Type de transaction USSD'),
                          items: const [
                            DropdownMenuItem(value: 'credit', child: Text('Achat de crédit (Soi)')),
                            DropdownMenuItem(value: 'transfert', child: Text('Transfert d\'argent')),
                            DropdownMenuItem(value: 'mixx', child: Text('Forfait MIXX / Forfait')),
                          ],
                          onChanged: (v) => setState(() => _ussdType = v!),
                        ),
                        if (_ussdType == 'transfert') ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _numeroDestCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Numéro du destinataire',
                              prefixIcon: Icon(Icons.contact_phone_rounded),
                            ),
                            validator: (v) => _viaUssd && _ussdType == 'transfert' && (v == null || v.isEmpty) ? 'Requis' : null,
                          ),
                        ],
                      ],
                    ],
                  );
                }),
              ],
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                    backgroundColor: _type == 'depense'
                        ? AppConstants.depenseColor
                        : AppConstants.revenuColor),
                child: Text(
                    widget.transaction != null ? 'Modifier' : 'Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton(
      {required this.label,
      required this.selected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10)),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: selected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}
