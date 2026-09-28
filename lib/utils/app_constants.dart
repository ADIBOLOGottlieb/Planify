import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Palette de l'application. Les couleurs de fond, de texte et d'accent
/// dépendent des préférences (thème clair/sombre, couleur d'accent) et sont
/// mises à jour par [appliquer].
class AppConstants {
  static const String appName = 'Planify';

  static const Color accentParDefaut = Color(0xFF2ECC70); // émeraude
  static const Color secondaryColor = Color(0xFF3B82F6); // bleu
  static const Color depenseColor = Color(0xFFEF4444); // rouge
  static const Color revenuColor = Color(0xFF10B981); // vert

  static bool _sombre = true;
  static Color _accent = accentParDefaut;

  static void appliquer({required bool sombre, required Color accent}) {
    _sombre = sombre;
    _accent = accent;
  }

  static bool get sombre => _sombre;
  static Color get primaryColor => _accent;

  /// Fond des écrans.
  static Color get bgColor => _sombre ? const Color(0xFF0F172A) : const Color(0xFFF5F7FA);

  /// Fond des cartes, feuilles et boîtes de dialogue.
  static Color get surfaceColor => _sombre ? const Color(0xFF1E293B) : Colors.white;

  /// Texte principal sur [bgColor] / [surfaceColor].
  static Color get texteColor => _sombre ? Colors.white : const Color(0xFF1E293B);

  /// Texte secondaire (libellés, dates…).
  static Color get texteSecondaire => _sombre ? Colors.white70 : Colors.black54;
}

/// Utilitaires globaux de l'application - source unique de vérité
class AppHelpers {
  static final NumberFormat _compactFormat =
      NumberFormat.compact(locale: 'fr_FR');
  static final NumberFormat _decimalFormat =
      NumberFormat.decimalPattern('fr_FR');
  static final DateFormat _dateShort = DateFormat('d MMM yyyy', 'fr_FR');
  static final DateFormat _dateLong = DateFormat.yMMMMd('fr_FR');
  static final DateFormat _monthLong = DateFormat.yMMMM('fr_FR');
  static final DateFormat _monthShort = DateFormat.MMM('fr_FR');

  static String formatMontant(double montant, String devise) {
    final absVal = montant.abs();
    final formatted = absVal >= 1000000
        ? _compactFormat.format(absVal)
        : _decimalFormat.format(absVal);
    return '$formatted $devise';
  }

  /// Montant avec son signe (« -2 500 FCFA »), et « + » si [plus] est vrai.
  static String formatMontantSigne(double montant, String devise, {bool plus = false}) {
    final signe = montant < 0 ? '-' : (plus && montant > 0 ? '+' : '');
    return '$signe${formatMontant(montant, devise)}';
  }

  static String formatDate(DateTime date) {
    return _dateShort.format(date);
  }

  static String formatDateFull(DateTime date) {
    return _dateLong.format(date);
  }

  static String formatMois(DateTime date) {
    return _monthLong.format(date);
  }

  static String formatMoisCourt(DateTime date) {
    return _monthShort.format(date).replaceAll('.', '');
  }

  static double? parseMontant(String input) {
    final normalized = input.replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  static Color hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  /// Bibliothèque des 50 icônes proposées pour les catégories.
  static const Map<String, IconData> iconesCategories = {
    'home': Icons.home_rounded,
    'restaurant': Icons.restaurant_rounded,
    'directions_car': Icons.directions_car_rounded,
    'local_hospital': Icons.local_hospital_rounded,
    'school': Icons.school_rounded,
    'sports_esports': Icons.sports_esports_rounded,
    'checkroom': Icons.checkroom_rounded,
    'phone_android': Icons.phone_android_rounded,
    'more_horiz': Icons.more_horiz_rounded,
    'work': Icons.work_rounded,
    'storefront': Icons.storefront_rounded,
    'laptop': Icons.laptop_rounded,
    'trending_up': Icons.trending_up_rounded,
    'attach_money': Icons.attach_money_rounded,
    'shopping_cart': Icons.shopping_cart_rounded,
    'local_grocery_store': Icons.local_grocery_store_rounded,
    'local_gas_station': Icons.local_gas_station_rounded,
    'directions_bus': Icons.directions_bus_rounded,
    'two_wheeler': Icons.two_wheeler_rounded,
    'flight': Icons.flight_rounded,
    'hotel': Icons.hotel_rounded,
    'electrical_services': Icons.electrical_services_rounded,
    'water_drop': Icons.water_drop_rounded,
    'wifi': Icons.wifi_rounded,
    'tv': Icons.tv_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'spa': Icons.spa_rounded,
    'content_cut': Icons.content_cut_rounded,
    'child_care': Icons.child_care_rounded,
    'pets': Icons.pets_rounded,
    'card_giftcard': Icons.card_giftcard_rounded,
    'volunteer_activism': Icons.volunteer_activism_rounded,
    'church': Icons.church_rounded,
    'celebration': Icons.celebration_rounded,
    'family_restroom': Icons.family_restroom_rounded,
    'medication': Icons.medication_rounded,
    'local_pharmacy': Icons.local_pharmacy_rounded,
    'menu_book': Icons.menu_book_rounded,
    'computer': Icons.computer_rounded,
    'build': Icons.build_rounded,
    'construction': Icons.construction_rounded,
    'savings': Icons.savings_rounded,
    'account_balance': Icons.account_balance_rounded,
    'credit_card': Icons.credit_card_rounded,
    'receipt_long': Icons.receipt_long_rounded,
    'payments': Icons.payments_rounded,
    'request_quote': Icons.request_quote_rounded,
    'agriculture': Icons.agriculture_rounded,
    'local_cafe': Icons.local_cafe_rounded,
    'fastfood': Icons.fastfood_rounded,
  };

  static IconData getCategoryIcon(String iconName) =>
      iconesCategories[iconName] ?? Icons.category_rounded;

  /// Couleur de la barre de consommation d'un budget :
  /// vert sous 60 %, orange de 60 à 90 %, rouge au-delà de 90 %.
  static Color couleurConsommation(double pourcentage,
      {Color normal = Colors.green}) {
    if (pourcentage > 0.9) return AppConstants.depenseColor;
    if (pourcentage >= 0.6) return Colors.orange;
    return normal;
  }

  static String getModeLabel(String mode) {
    const modes = {
      'especes': 'Espèces',
      'mobile_money': 'Mobile Money',
      'virement': 'Virement bancaire',
      'carte': 'Carte bancaire',
    };
    return modes[mode] ?? mode;
  }
}
