import 'package:flutter/material.dart';
import '../utils/settings_service.dart';
import '../utils/secure_store.dart';

class SyncSettingsScreen extends StatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  State<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends State<SyncSettingsScreen> {
  final _settings = SettingsService();
  final _secure = SecureStore();
  final _urlCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _enabled = await _settings.isSyncEnabled();
    _urlCtrl.text = await _settings.getApiBaseUrl();
    _tokenCtrl.text = await _secure.getToken() ?? '';
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    await _settings.setSyncEnabled(_enabled);
    await _settings.setApiBaseUrl(_urlCtrl.text);
    if (_tokenCtrl.text.trim().isNotEmpty) {
      await _secure.setToken(_tokenCtrl.text);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Paramètres de synchro enregistrés')));
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Synchronisation Cloud')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SwitchListTile(
                    value: _enabled,
                    onChanged: (v) => setState(() => _enabled = v),
                    title: const Text('Activer la synchronisation'),
                    subtitle: const Text('Utilise l’API Laravel (JWT)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'URL API',
                      hintText: 'https://exemple.com',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tokenCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Token JWT',
                      hintText: 'Bearer token',
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: _save, child: const Text('Enregistrer')),
                ],
              ),
            ),
    );
  }
}
