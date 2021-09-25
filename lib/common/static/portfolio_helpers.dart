import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_wealth/common/models/portfolio.dart';
import 'package:track_wealth/common/services/portfolio.dart';

Map<String, String> tooltips = {
  'Актив': 'Наименование актива',
  'Тикер': 'Код актива',
  'Количество': 'Размер лота * Количество лотов',
  'Ср. Цена, ₽': 'Средняя цена открытой позиции',
  'Тек. Цена, ₽': 'Текущая цена за 1 акцию',
  'Изм. сегодня, %': 'Процентное изменение цены актива за день',
  'Прибыль, ₽': 'Курсовая прибыль по инструменту за все время',
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

String? validatePortfolioName(BuildContext context, String? name, {String? exceptName}) {
  if (name!.isEmpty) name = 'Основной портфель';
  name = name.trim();
  if (name.length < 3) return 'Имя должно содержать не менее трех символов';
  List<Portfolio> portfolios = context.read<PortfolioState>().portfolios;
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
