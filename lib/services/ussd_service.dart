import 'package:url_launcher/url_launcher_string.dart';

class UssdService {
  static Future<void> lancerTransfert({
    required String operateur,
    required double montant,
    required String numero,
  }) async {
    String code = '';
    final montantInt = montant.toInt();

    if (operateur == 'TMoney') {
      // Syntaxe: *145*1*MONTANT*NUMERO#
      code = '*145*1*$montantInt*$numero#';
    } else if (operateur == 'Flooz') {
      // Syntaxe: *155*1*NUMERO*MONTANT# (Note: Moov often uses *155*1*NUMERO*MONTANT#)
      code = '*155*1*$numero*$montantInt#';
    }

    if (code.isNotEmpty) {
      await _lancerCode(code);
    }
  }

  static Future<void> lancerAchatCredit({
    required String operateur,
    required double montant,
  }) async {
    String code = '';
    final montantInt = montant.toInt();

    if (operateur == 'TMoney') {
      // Syntaxe: *145*3*1*MONTANT# (Crédit pour soi)
      code = '*145*3*1*$montantInt#';
    } else if (operateur == 'Flooz') {
      // Syntaxe: *155*4*1*MONTANT# (Crédit pour soi)
      code = '*155*4*1*$montantInt#';
    }

    if (code.isNotEmpty) {
      await _lancerCode(code);
    }
  }

  static Future<void> lancerForfaitMixx({
    required String operateur,
    required String typeForfait, // ex: '500', '1000'
  }) async {
    String code = '';
    if (operateur == 'TMoney' || operateur == 'Yas') {
      // MIXX by Yas est sur TogoCom
      if (typeForfait == '500') {
        code = '*145*2*5*1#'; // Exemple de syntaxe MIXX 500
      } else if (typeForfait == '1000') {
        code = '*145*2*5*2#';
      } else {
        code = '*145*2*5#'; // Menu MIXX
      }
    }

    if (code.isNotEmpty) {
      await _lancerCode(code);
    }
  }

  static Future<void> _lancerCode(String code) async {
    // Encodage du # en %23 pour l'URI tel:
    final encodedCode = code.replaceAll('#', '%23');
    final url = 'tel:$encodedCode';
    
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    }
  }
}
