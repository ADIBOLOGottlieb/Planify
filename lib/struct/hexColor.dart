import 'package:flutter/material.dart';

class HexColor extends Color {
  static int _getColorFromHex(String? hexColor, Color? defaultColor, context) {
    try {
      if (hexColor == null) {
        if (defaultColor == null) {
          return Colors.grey.value;
        } else {
          return defaultColor.value;
        }
      }
      hexColor = hexColor.replaceAll("#", "");
      hexColor = hexColor.replaceAll("0x", "");
      if (hexColor.length == 6) {
        hexColor = "FF" + hexColor;
      }
      return int.parse(hexColor, radix: 16);
    } catch (e) {
      return Colors.grey.value;
    }
  }

  HexColor(final String? hexColor, {final Color? defaultColor})
      : super(_getColorFromHex(hexColor, defaultColor, null));
}

String? toHexString(Color? color) {
  if (color == null) {
    return null;
  }
  String valueString = color.value.toRadixString(16);
  return "0x" + valueString;
}

