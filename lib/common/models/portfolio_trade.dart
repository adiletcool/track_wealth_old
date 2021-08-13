import 'package:cloud_firestore/cloud_firestore.dart';

abstract class Trade {
  final String operation;
  final Timestamp date;
  final String currencyCode;
  final String? note;

  Trade({
    required this.date,
    required this.operation,
    required this.currencyCode,
    required this.note,
  });
}

/*
* TODO: при получении списка trades создаем список объектов класса Trade:
List<Map<String, dynamic>> trades = [...{}, ...{}];

List<Trade> portfolioTrades = trades.map<Trade>((t) {
  switch (t['type']) {
    case 'assets':
      return AssetTrade.fromJson(t);
    case 'money':
      return MoneyTrade.fromJson(t);
    case 'dividends':
      return DividendsTrade.fromJson(t);
    default:
      throw 'Unknown trade type: ${t['type']}';
  }
}).toList();
*/

class AssetTrade extends Trade {
  final String secId;
  final bool isForeign;
  final String shortName;
  final bool isPurchase;
  final num price;
  final int quantity;
  final num fee;

  AssetTrade({
    required Timestamp date,
    required String operation,
    required String currencyCode,
    required String? note,
    required this.secId,
    required this.isForeign,
    required this.shortName,
    required this.isPurchase,
    required this.price,
    required this.quantity,
    required this.fee,
  }) : super(
          date: date,
          operation: operation, // покупка / продажа
          currencyCode: currencyCode,
          note: note,
        );

  factory AssetTrade.fromJson(Map<String, dynamic> json) {
    return AssetTrade(
      date: json['date'],
      operation: json['operation'],
      currencyCode: json['currencyCode'],
      note: json['note'],
      secId: json['secId'],
      isForeign: json['isForeign'],
      shortName: json['shortName'],
      isPurchase: json['isPurchase'],
      price: json['price'],
      quantity: json['quantity'],
      fee: json['fee'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // * Передаем ключ type, чтобы определять наследника
      'type': 'assets',
      'date': date,
      'operation': operation,
      'currencyCode': currencyCode,
      'note': note,
      'secId': secId,
      'isForeign': isForeign,
      'shortName': shortName,
      'isPurchase': isPurchase,
      'price': price,
      'quantity': quantity,
      'fee': fee,
    };
  }
}

class MoneyTrade extends Trade {
  final bool isReceive;
  final num quantity;

  MoneyTrade({
    required Timestamp date,
    required String operation,
    required String currencyCode,
    required String? note,
    required this.isReceive,
    required this.quantity,
  }) : super(
          date: date,
          operation: operation, // Внесение / вывод / доход / расход
          currencyCode: currencyCode,
          note: note,
        );

  factory MoneyTrade.fromJson(Map<String, dynamic> json) {
    return MoneyTrade(
      date: json['date'],
      operation: json['operation'],
      currencyCode: json['currencyCode'],
      note: json['note'],
      isReceive: json['isReceive'],
      quantity: json['quantity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': 'money', // ! Передаем параметр, через который потом будем определять, какой класс создавать
      'date': date,
      'operation': operation,
      'currencyCode': currencyCode,
      'note': note,
      'isReceive': isReceive,
      'quantity': quantity,
    };
  }
}

class DividendsTrade extends Trade {
  final String secId;
  final bool isForeign;
  final String divPerShare;
  final int numShares;

  DividendsTrade({
    required Timestamp date,
    required String currencyCode,
    required String? note,
    required this.secId,
    required this.isForeign,
    required this.divPerShare,
    required this.numShares,
  }) : super(date: date, operation: 'Дивиденды', currencyCode: currencyCode, note: note);

  factory DividendsTrade.fromJson(Map<String, dynamic> json) {
    return DividendsTrade(
      date: json['date'],
      currencyCode: json['currencyCode'],
      note: json['note'],
      secId: json['secId'],
      isForeign: json['isForeign'],
      divPerShare: json['divPerShare'],
      numShares: json['numShares'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': 'dividends', // ! Передаем параметр, через который потом будем определять, какой класс создавать
      'date': date,
      'currencyCode': currencyCode,
      'note': note,
      'secId': secId,
      'isForeign': isForeign,
      'divPerShare': divPerShare,
      'numShares': numShares,
    };
  }
}
