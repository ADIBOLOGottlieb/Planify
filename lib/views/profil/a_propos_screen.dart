import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../services/api_service.dart';
import '../../utils/app_constants.dart';

/// Page « À propos » : version, politique de confidentialité, mentions
/// légales et signalement d'un problème à l'administrateur.
class AProposScreen extends StatelessWidget {
  const AProposScreen({super.key});

  static const _politique = '''
Planify enregistre vos transactions, budgets, objectifs et catégories d'abord sur votre téléphone (base SQLite locale).

Si vous activez la synchronisation, ces données sont envoyées au serveur Planify par une connexion chiffrée (HTTPS/TLS) et associées à votre compte. Elles ne sont ni vendues ni partagées avec des tiers.

Votre mot de passe n'est jamais stocké en clair : il est haché (PBKDF2 sur l'appareil, bcrypt sur le serveur). Votre jeton de connexion est conservé dans le stockage sécurisé du téléphone (Android Keystore / Keychain iOS) et expire après 24 heures.

Les photos de reçus restent dans le dossier privé de l'application ; elles ne sont envoyées au serveur que si la synchronisation est activée.

L'administrateur ne consulte que des statistiques globales anonymisées.

Vous pouvez exporter vos données (CSV, PDF) et supprimer votre compte à tout moment depuis le Profil : la suppression efface vos données sur l'appareil et sur le serveur.''';

  static const _mentions = '''
Planify — application mobile de planification des dépenses.

Réalisée par ADIBOLO Y. A. Gottlieb dans le cadre du mémoire de Licence Professionnelle « Développeur d'applications », Institut FORMATEC, Lomé (Togo).

Directeur de mémoire : M. AKANATE Alassani.

Planify est un outil d'aide à la gestion budgétaire ; il ne constitue pas un conseil financier et n'effectue aucune opération bancaire. Les codes USSD proposés sont lancés dans l'application Téléphone : l'opération est validée par l'utilisateur auprès de son opérateur (Moov Africa Togo, Yas Togo).''';

  void _afficherTexte(BuildContext context, String titre, String texte) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(titre)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Text(texte, style: const TextStyle(height: 1.5)),
          ),
        ),
      ),
    );
  }

  Future<void> _signaler(BuildContext context) async {
    final sujetCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    final envoyer = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Signaler un problème'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: sujetCtrl, decoration: const InputDecoration(labelText: 'Sujet')),
            const SizedBox(height: 8),
            TextField(
              controller: messageCtrl,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Décrivez le problème'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Envoyer')),
        ],
      ),
    );
    if (envoyer != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final api = ApiService();
    String message;
    if (sujetCtrl.text.trim().isEmpty || messageCtrl.text.trim().isEmpty) {
      message = 'Sujet et description requis.';
    } else if (!await api.estConnecte()) {
      message = 'Connectez-vous en ligne pour envoyer un signalement.';
    } else {
      try {
        await api.envoyerSignalement(sujetCtrl.text.trim(), messageCtrl.text.trim());
        message = 'Merci, votre signalement a été transmis.';
      } on ApiException catch (e) {
        message = e.message;
      }
    }
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('À propos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.account_balance_wallet_rounded,
                  size: 42, color: AppConstants.primaryColor),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
              child: Text('Planify', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (_, snap) => Center(
              child: Text(
                snap.hasData
                    ? 'Version ${snap.data!.version} (${snap.data!.buildNumber})'
                    : '',
                style: TextStyle(color: AppConstants.texteSecondaire),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Politique de confidentialité'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _afficherTexte(context, 'Confidentialité', _politique),
          ),
          ListTile(
            leading: const Icon(Icons.gavel_rounded),
            title: const Text('Mentions légales'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _afficherTexte(context, 'Mentions légales', _mentions),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Signaler un problème'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _signaler(context),
          ),
        ],
      ),
    );
  }
}
