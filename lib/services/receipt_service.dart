import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Photos prises ou choisies par l'utilisateur (reçus, photo de profil),
/// copiées dans le dossier privé de l'application.
class ReceiptService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> _choisirEtCopier(ImageSource source, String dossier, String prefixe) async {
    final picked = await _picker.pickImage(source: source, maxWidth: 1600, imageQuality: 80);
    if (picked == null) return null;

    // Navigateur : pas de système de fichiers, l'image est conservée en data URI.
    if (kIsWeb) {
      final octets = await picked.readAsBytes();
      final type = picked.mimeType ?? 'image/jpeg';
      return 'data:$type;base64,${base64Encode(octets)}';
    }

    final dir = await getApplicationDocumentsDirectory();
    final cible = Directory('${dir.path}/$dossier');
    if (!await cible.exists()) {
      await cible.create(recursive: true);
    }
    final fileName = '${prefixe}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final saved = await File(picked.path).copy('${cible.path}/$fileName');
    return saved.path;
  }

  /// Photo d'un reçu, prise avec l'appareil photo ou choisie dans la galerie.
  Future<String?> pickAndSaveReceipt({ImageSource source = ImageSource.camera}) =>
      _choisirEtCopier(source, 'receipts', 'receipt');

  Future<String?> choisirPhotoProfil() =>
      _choisirEtCopier(ImageSource.gallery, 'profil', 'avatar');
}
