import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class MyFormatter {
  static NumberFormat numFormatter = NumberFormat('#,##0.00');
  static NumberFormat intFormatter = NumberFormat('#,###');

  static String numFormat(num number, {int? decimals}) {
    if (decimals != null) number = num.parse(number.toStringAsFixed(decimals));
    return numFormatter.format(number).replaceAll(',', ' ');
  }

  static String intFormat(num number) {
    return intFormatter.format(number).replaceAll(',', ' ');
  }

  static String currencyFormat(num number, String locale, String symbol) {
    return NumberFormat.currency(decimalDigits: 2, locale: locale, symbol: symbol).format(number);
  }
}

class DecimalTextInputFormatter extends TextInputFormatter {
  DecimalTextInputFormatter({this.decimalRange}) : assert(decimalRange == null || decimalRange > 0);

  final int? decimalRange;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue, // unused.
    TextEditingValue newValue,
  ) {
    TextSelection newSelection = newValue.selection;
    String truncated = newValue.text;

    if (decimalRange != null) {
      String value = newValue.text;

      // не более одной точки
      // if ('.'.allMatches(value).length > 1) {
      //   truncated = oldValue.text;
      //   newSelection = oldValue.selection;
      // } // не более decimalRange знаков после точки
      if (value == ".") {
        truncated = "0.";

        newSelection = newValue.selection.copyWith(
          baseOffset: math.min(truncated.length, truncated.length + 1),
          extentOffset: math.min(truncated.length, truncated.length + 1),
        );
      } else if (value == '00') {
        truncated = "0";

        newSelection = newValue.selection.copyWith(
          baseOffset: math.min(truncated.length, truncated.length + 1),
          extentOffset: math.min(truncated.length, truncated.length + 1),
        );
      } else if ((value.isNotEmpty) && (double.tryParse(value) == null)) {
        truncated = oldValue.text;
        newSelection = oldValue.selection;
      } else if (value.contains(".") && value.substring(value.indexOf(".") + 1).length > decimalRange!) {
        truncated = oldValue.text;
        newSelection = oldValue.selection;
      }

      return TextEditingValue(
        text: truncated,
        selection: newSelection,
        composing: TextRange.empty,
      );
    }
    return newValue;
  }
}
