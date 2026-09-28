import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

/// Image à afficher pour un chemin enregistré (reçu, photo de profil) :
/// URL du serveur, image encodée en `data:` (navigateur) ou fichier local
/// (Android / iOS). Renvoie null si l'image n'est plus disponible.
ImageProvider? imageDepuisChemin(String? chemin) {
  if (chemin == null || chemin.isEmpty) return null;
  if (chemin.startsWith('http') || chemin.startsWith('blob:')) {
    return NetworkImage(chemin);
  }
  if (chemin.startsWith('data:')) {
    return MemoryImage(UriData.parse(chemin).contentAsBytes());
  }
  if (kIsWeb) return null;
  final fichier = File(chemin);
  return fichier.existsSync() ? FileImage(fichier) : null;
}
