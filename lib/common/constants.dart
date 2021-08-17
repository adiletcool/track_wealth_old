import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:track_wealth/common/services/dashboard.dart';

import 'models/portfolio.dart';
import 'services/auth.dart';

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
  static Color selected = Color(0xff008a86);
  static Color black = Colors.black;
  static Color grey = Color(0xffF5F5F5);
  static Color darkGrey = Color(0xff8a8a8a);
  static Color white = Colors.white;
  static Color red = Color(0xfff32221);
  static Color bgDark = Color(0xFF1A1A1A);

  static Color themeBasedColor(context, darkColor, lightColor) {
    return Theme.of(context).brightness == Brightness.dark ? darkColor : lightColor;
  }
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
    return NumberFormat.currency(decimalDigits: 2, locale: locale, symbol: symbol).format(number);
  }
}

InputDecoration myInputDecoration = InputDecoration(
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  isDense: true,
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: AppColor.selected),
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

Map<String, String> tooltips = {
  'Актив': 'Наименование актива',
  'Тикер': 'Код актива',
  'Количество': 'Размер лота * Количество лотов',
  'Ср. Цена, ₽': 'Средняя цена открытой позиции',
  'Тек. Цена, ₽': 'Текущая цена за 1 акцию',
  'Изм. сегодня, %': 'Процентное изменение цены актива за день',
  'Прибыль, ₽': 'Курсовая прибыль по инструменту за все время', //TODO: , включающая дивиденды и комиссию
  'Прибыль, %': 'Средневзвешенная процентная прибыль по инструменту за все время', //, включающая дивиденды и комиссию
  'Доля, %': 'Доля инструмента, относительно стоимости портфеля',
  'Стоимость, ₽': 'Рыночная стоимость позиции по инструменту в портфеле',
  'open_pos_change': 'Прибыль или убыток только по открытым позициям.',
  'totalWorth': 'Рыночная стоимость всех активов, а также денежные средства, конвертированные в рубли по текущему курсу.',
};

/*
List<Map<String, dynamic>> sampleUserAssets = [
  {"secId": "GMKN", "boardId": "TQBR", "shortName": "ГМКНорНик", "quantity": 15, "meanPrice": 22160.00},
  {"secId": "LKOH", "boardId": "TQBR", "shortName": "Лукойл", "quantity": 30, "meanPrice": 4751.5},
  {"secId": "SBER", "boardId": "TQBR", "shortName": "Сбербанк", "quantity": 610, "meanPrice": 191.37},
  {"secId": "YNDX", "boardId": "TQBR", "shortName": "Yandex clA", "quantity": 33, "meanPrice": 4177.80},
  {"secId": "AGRO", "boardId": "TQBR", "shortName": "AGRO-гдр", "quantity": 100, "meanPrice": 896.00},
  {"secId": "RTKM", "boardId": "TQBR", "shortName": "Ростел -ао", "quantity": 560, "meanPrice": 81.78},
  {"secId": "FIVE", "boardId": "TQBR", "shortName": "FIVE-гдр", "quantity": 16, "meanPrice": 2420.00},
  {"secId": "ALRS", "boardId": "TQBR", "shortName": "АЛРОСА ао", "quantity": 120, "meanPrice": 69.97},
  {"secId": "M-RM", "boardId": "FQBR", "shortName": "Macy's", "quantity": 38, "meanPrice": 1200.00},
  {"secId": "VTBR", "boardId": "TQBR", "shortName": "ВТБ ао", "quantity": 60000, "meanPrice": 0.046069},
  {"secId": "MGNT", "boardId": "TQBR", "shortName": "Магнит ао", "quantity": 2, "meanPrice": 5486.00},
  {"secId": "MTLRP", "boardId": "TQBR", "shortName": "Мечел ап", "quantity": 30, "meanPrice": 132.38},
  {"secId": "OXY-RM", "boardId": "FQBR", "shortName": "Occidental", "quantity": 4, "meanPrice": 1993.00},
  {"secId": "DSKY", "boardId": "TQBR", "shortName": "ДетскийМир", "quantity": 400, "meanPrice": 143.29},
  {"secId": "MVID", "boardId": "TQBR", "shortName": "М.видео", "quantity": 22, "meanPrice": 728.60},
  {"secId": "LNTA", "boardId": "TQBR", "shortName": "Лента др", "quantity": 70, "meanPrice": 252.10},
  {"secId": "TATN", "boardId": "TQBR", "shortName": "Татнфт 3ао", "quantity": 116, "meanPrice": 540.20},
  {"secId": "FIXP", "boardId": "TQBR", "shortName": "FIXP-гдр", "quantity": 40, "meanPrice": 745.20},
  {"secId": "MAIL", "boardId": "TQBR", "shortName": "MAIL-гдр", "quantity": 32, "meanPrice": 2042.40},
  {"secId": "RSTI", "boardId": "TQBR", "shortName": "Россети ао", "quantity": 45000, "meanPrice": 1.70},
];
*/

List<Map<String, dynamic>> newUserCurrencies = [
  {'code': 'RUB', 'name': 'Рубли', 'value': 0, 'locale': 'ru', 'symbol': '₽'},
  {'code': 'USD000UTSTOM', 'name': 'Доллары', 'value': 0, 'locale': 'en_US', 'symbol': '\$'},
  {'code': 'EUR_RUB__TOM', 'name': 'Евро', 'value': 0, 'locale': 'eu', 'symbol': '€'},
];

PreferredSizeWidget simpleAppBar(context, {Widget? title, bool? centerTitle, List<Widget>? actions}) {
  Color bgColor = AppColor.themeBasedColor(context, Colors.white, Colors.black);

  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    leading: IconButton(
      icon: Icon(Icons.arrow_back, color: bgColor),
      onPressed: () => Navigator.pop(context),
    ),
    title: title,
    centerTitle: centerTitle,
    actions: actions,
  );
}

void userLogout(context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        content: Text('Вы уверены, что хотите выйти из аккаунта?'),
        actions: [
          TextButton(
            child: Text(
              'Да',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () async {
              await context.read<AuthService>().signOut();

              // trigger to reload DashboardState
              context.read<DashboardState>().loadDataState = null;

              // не popUnti, т.к. home закрылся после popAndPushNamed(context, '/dashboard'))
              Navigator.popUntil(context, ModalRoute.withName('/dashboard'));
              Navigator.popAndPushNamed(context, '/');
            },
          ),
          TextButton(
            child: Text('Отмена'),
            onPressed: () => Navigator.pop(context),
          )
        ],
      );
    },
  );
}

String? validatePortfolioName(BuildContext context, String? name, {String? exceptName}) {
  if (name!.isEmpty) name = 'Основной портфель';
  name = name.trim();
  if (name.length < 3) return 'Имя должно содержать не менее трех символов';
  List<Portfolio> portfolios = context.read<DashboardState>().portfolios;
  bool hasSameName;

  hasSameName = portfolios.where((p) => p.name != exceptName).any((portfolio) => portfolio.name == name);

  if (hasSameName) {
    return 'Портфель с таким именем уже существует';
  }
  return null;
}

List<String> availableBrokers = [
  'Сбербанк',
  "Тинькофф",
  "Финам",
  "ВТБ ",
  "БКС",
  "Открытие",
  "Альфа-директ",
  "Церих",
  "Не выбран",
];
