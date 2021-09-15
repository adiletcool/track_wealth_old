import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

abstract class Trade {
  final String type;
  final String operation;
  final Timestamp date;
  final String currencyCode;
  final String? note;

  Trade({
    required this.type,
    required this.date,
    required this.operation,
    required this.currencyCode,
    required this.note,
  });

  Map<String, dynamic> toJson();

  Widget build() {
    return Container(
      child: Text(this.type),
    );
  }
}

/*
* TODO: при получении списка trades создаем список объектов класса Trade:
List<Map<String, dynamic>> trades = [...{}, ...{}];

апкастим до Trade
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

void a() {
  List<Widget> trades = portfolioTrades.map((trade) => trade.build()).toList();
}
*/

class AssetTrade extends Trade {
  final String secId;
  final bool isForeign;
  final String shortName;
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
    required this.price,
    required this.quantity,
    required this.fee,
  }) : super(
          type: 'assets',
          date: date,
          operation: operation, // покупка / продажа
          currencyCode: currencyCode,
          note: note,
        );

  // Redirecting named constructor
  AssetTrade.fromJson(Map<String, dynamic> json)
      : this(
          date: json['date'],
          operation: json['operation'],
          currencyCode: json['currencyCode'],
          note: json['note'],
          secId: json['secId'],
          isForeign: json['isForeign'],
          shortName: json['shortName'],
          price: json['price'],
          quantity: json['quantity'],
          fee: json['fee'],
        );

  @override
  Map<String, dynamic> toJson() {
    return {
      // * Передаем ключ type, чтобы определять наследника
      'type': type,
      'date': date,
      'operation': operation,
      'currencyCode': currencyCode,
      'note': note,
      'secId': secId,
      'isForeign': isForeign,
      'shortName': shortName,
      'price': price,
      'quantity': quantity,
      'fee': fee,
    };
  }
}

class MoneyTrade extends Trade {
  final num quantity;

  MoneyTrade({
    required Timestamp date,
    required String operation,
    required String currencyCode,
    required String? note,
    required this.quantity,
  }) : super(
          type: 'money',
          date: date,
          operation: operation, // Внесение / вывод / доход / расход
          currencyCode: currencyCode,
          note: note,
        );

  MoneyTrade.fromJson(Map<String, dynamic> json)
      : this(
          date: json['date'],
          operation: json['operation'],
          currencyCode: json['currencyCode'],
          note: json['note'],
          quantity: json['quantity'],
        );

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type, // ! Передаем параметр, через который потом будем определять, какой класс создавать
      'date': date,
      'operation': operation,
      'currencyCode': currencyCode,
      'note': note,
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
    required String operation,
    required this.secId,
    required this.isForeign,
    required this.divPerShare,
    required this.numShares,
  }) : super(
          type: 'dividends',
          date: date,
          operation: operation,
          currencyCode: currencyCode,
          note: note,
        );

  DividendsTrade.fromJson(Map<String, dynamic> json)
      : this(
          date: json['date'],
          operation: json['operation'],
          currencyCode: json['currencyCode'],
          note: json['note'],
          secId: json['secId'],
          isForeign: json['isForeign'],
          divPerShare: json['divPerShare'],
          numShares: json['numShares'],
        );

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type, // ! Передаем параметр, через который потом будем определять, какой класс создавать
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
