import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppConstants {
  static const String appName = 'Planify';
  
  // Couleurs pour Dark Mode Premium
  static const Color primaryColor = Color(0xFF2ECC70); // Emerald Green
  static const Color secondaryColor = Color(0xFF3B82F6); // Vibrant Blue
  static const Color depenseColor = Color(0xFFEF4444); // Neon Red
  static const Color revenuColor = Color(0xFF10B981); // Neon Green
  
  // Fonds sombres
  static const Color bgColor = Color(0xFF0F172A); // Very Dark Slate
  static const Color surfaceColor = Color(0xFF1E293B); // Dark Slate for cards
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

  static IconData getCategoryIcon(String iconName) {
    const icons = <String, IconData>{
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
    };
    return icons[iconName] ?? Icons.category_rounded;
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
