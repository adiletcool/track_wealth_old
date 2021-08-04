import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

class AppColor {
  static Color yellow = Color(0xffFFC222);
  static Color selectedDrawerItem = Color(0xff0179B5);
  static Color black = Colors.black;
  static Color grey = Color(0xffF5F5F5);
  static Color darkGrey = Color(0xff8a8a8a);
  static Color white = Colors.white;
  static Color green = Color(0xff34A853);
  static Color red = Color(0xffCD4932);
  static Color bgDark = Color(0xFF1A1A1A);
}

class MyFormatter {
  static NumberFormat numFormatter = NumberFormat('#,##0.00');
  static NumberFormat intFormatter = NumberFormat('#,###');
  static String numFormat(num number) {
    return numFormatter.format(number).replaceAll(',', ' ');
  }

  static String intFormat(num number) {
    return intFormatter.format(number).replaceAll(',', ' ');
  }

  static String currencyFormat(num number, String locale, String symbol) {
    return NumberFormat.currency(locale: locale, decimalDigits: 2, symbol: symbol).format(number);
  }
}

InputDecoration myInputDecoration = InputDecoration(
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  isDense: true,
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: AppColor.selectedDrawerItem),
    borderRadius: BorderRadius.circular(10),
  ),
);

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

extension EmailValidator on String {
  bool isValidEmail() {
    return RegExp(
            r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(this);
  }
}

BoxDecoration roundedBoxDecoration = BoxDecoration(
  borderRadius: BorderRadius.circular(10),
);

String getSignInErrorMessage(String errorCode) {
  switch (errorCode) {
    case 'wrong-password':
      return 'Неверный пароль, либо пользователь с такой почтой использует вход через соц. сети.';
    case 'user-not-found':
      return 'Пользователь с такой почтой не найден.';
    case 'too-many-requests':
      return 'Превышено количество попыток входа. Пожалуйста, попробуйте позже.';
    case 'invalid-verification-code':
      return 'Неверный код';
    default:
      return errorCode;
  }
}

String getSignUpErrorMessage(String errorCode) {
  switch (errorCode) {
    case 'weak-password':
      return 'Слишком простой пароль.';
    case 'email-already-in-use':
      return 'Пользователь с такой почтой уже существует.';
    default:
      return errorCode;
  }
}
