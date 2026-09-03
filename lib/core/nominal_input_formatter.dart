import 'package:flutter/services.dart';

/// Formats nominal Rupiah inputs with a dot as the thousands separator.
///
/// Examples:
/// 1500 -> 1.500
/// 1500000 -> 1.500.000
/// 1500000,50 -> 1.500.000,50
class NominalInputFormatter extends TextInputFormatter {
  const NominalInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;

    if (raw.isEmpty) {
      return newValue;
    }

    // Nominal uses comma for an optional decimal part. Dots are treated as
    // grouping separators and are rebuilt automatically below.
    final cleaned = raw.replaceAll(RegExp(r'[^0-9,]'), '');
    if (cleaned.isEmpty) {
      return oldValue;
    }

    final commaIndex = cleaned.indexOf(',');
    final integerPart = commaIndex >= 0
        ? cleaned.substring(0, commaIndex)
        : cleaned;
    final decimalPart = commaIndex >= 0
        ? cleaned.substring(commaIndex + 1).replaceAll(',', '')
        : null;

    final formattedInteger = _formatThousands(integerPart);
    final formatted = decimalPart == null
        ? formattedInteger
        : '$formattedInteger,$decimalPart';

    final digitsBeforeCursor = _countDigitsAndComma(
      raw.substring(0, newValue.selection.end),
    );
    final newCursor = _cursorForLogicalPosition(
      formatted,
      digitsBeforeCursor,
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursor),
      composing: TextRange.empty,
    );
  }

  static String _formatThousands(String digits) {
    if (digits.isEmpty) {
      return '0';
    }

    final normalized = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final buffer = StringBuffer();

    for (var i = 0; i < normalized.length; i++) {
      if (i > 0 && (normalized.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(normalized[i]);
    }

    return buffer.toString();
  }

  static int _countDigitsAndComma(String value) {
    return value.split('').where((char) => RegExp(r'[0-9,]').hasMatch(char)).length;
  }

  static int _cursorForLogicalPosition(String formatted, int logicalPosition) {
    if (logicalPosition <= 0) {
      return 0;
    }

    var count = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (RegExp(r'[0-9,]').hasMatch(formatted[i])) {
        count++;
        if (count >= logicalPosition) {
          return i + 1;
        }
      }
    }

    return formatted.length;
  }
}

String formatNominalInput(double amount) {
  if (amount == amount.roundToDouble()) {
    final digits = amount.round().abs().toString();
    final formatted = NominalInputFormatter._formatThousands(digits);
    return amount < 0 ? '-$formatted' : formatted;
  }

  final fixed = amount.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  final parts = fixed.split('.');
  final integer = NominalInputFormatter._formatThousands(parts.first);
  return '$integer,${parts.last}';
}

double? parseNominalInput(String value) {
  var text = value.trim();
  if (text.isEmpty) {
    return null;
  }

  text = text.replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(text);
}
