import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../services/settings_service.dart';
import '../utils/app_constants.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/chargement_donnees.dart';

/// Sauvegarde sur le serveur et synchronisation entre appareils.
/// Le jeton d'accès est obtenu à la connexion (Laravel Sanctum) : il n'est
/// jamais saisi à la main.
class SyncSettingsScreen extends StatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  State<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends State<SyncSettingsScreen> {
  final _settings = SettingsService();
  final _api = ApiService();
  final _urlCtrl = TextEditingController();
  bool _enabled = false;
  bool _connecte = false;
  bool _loading = true;
  bool _synchro = false;
  DateTime? _derniereSynchro;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _enabled = await _settings.isSyncEnabled();
    _urlCtrl.text = await _settings.getApiBaseUrl();
    _connecte = await _api.estConnecte();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _synchroniser() async {
    setState(() => _synchro = true);
    await chargerDonneesUtilisateur(context);
    if (!mounted) return;
    setState(() {
      _synchro = false;
      _derniereSynchro = DateTime.now();
    });
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Données sauvegardées et synchronisées.')));
  }

  Future<void> _enregistrerUrl() async {
    await _settings.setApiBaseUrl(_urlCtrl.text);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_connecte
            ? 'Adresse du serveur enregistrée.'
            : 'Adresse enregistrée. Reconnectez-vous pour obtenir un accès au serveur.')));
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthViewModel>().currentUser?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Sauvegarde & synchronisation')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(_connecte ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                          color: _connecte ? AppConstants.revenuColor : Colors.grey, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_connecte ? 'Connecté au serveur Planify' : 'Mode hors ligne',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              _connecte
                                  ? 'Compte : $email'
                                  : 'Vos données sont enregistrées uniquement sur ce téléphone. '
                                      'Connectez-vous avec Internet pour les sauvegarder.',
                              style: TextStyle(fontSize: 12, color: AppConstants.texteSecondaire),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _enabled,
                  onChanged: (v) async {
                    await _settings.setSyncEnabled(v);
                    setState(() => _enabled = v);
                  },
                  title: const Text('Synchronisation automatique'),
                  subtitle: const Text(
                      'Envoie vos modifications au serveur dès que la connexion le permet.'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: !_connecte || !_enabled || _synchro ? null : _synchroniser,
                  icon: _synchro
                      ? const SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.backup_rounded),
                  label: const Text('Sauvegarder maintenant'),
                ),
                if (_derniereSynchro != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Dernière sauvegarde : ${AppHelpers.formatDate(_derniereSynchro!)} '
                      'à ${_derniereSynchro!.hour.toString().padLeft(2, '0')}:'
                      '${_derniereSynchro!.minute.toString().padLeft(2, '0')}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppConstants.texteSecondaire),
                    ),
                  ),
                const SizedBox(height: 24),
                ExpansionTile(
                  title: const Text('Avancé'),
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  children: [
                    TextField(
                      controller: _urlCtrl,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Adresse du serveur (API)',
                        hintText: 'https://api.planify.tg',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _enregistrerUrl, child: const Text('Enregistrer l\'adresse')),
                  ],
                ),
              ],
            ),
    );
  }
}
