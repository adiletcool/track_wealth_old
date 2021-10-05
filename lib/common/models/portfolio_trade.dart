import 'package:flutter/widgets.dart';

abstract class Trade {
  final String actionType; // Акции / Деньги
  final String action; // Купить / Продать / Дивиденды / Внести ...
  final String date; // 2021-10-05 03:39:22.652
  final String currencyCode;
  num get operationTotal;

  final String? note;

  Trade({
    required this.actionType,
    required this.action,
    required this.date,
    required this.currencyCode,
    required this.note,
  });

  Map<String, dynamic> toJson();

  Widget build() {
    return Container(
      child: Text(this.actionType),
    );
  }
}

/*
* TODO: при получении списка trades создаем список объектов класса Trade:
List<Map<String, dynamic>> trades = [...{}, ...{}];

апкастим до Trade
List<Trade> portfolioTrades = trades.map<Trade>((t) {
  switch (t['actionType']) {
    case 'Акции':
      if (t['action'] == 'Дивиденды')
        return DividendsTrade.fromJson(t);
      else 
        return AssetTrade.fromJson(t);
    case 'Деньги':
      return MoneyTrade.fromJson(t);
    default:
      throw 'Unknown trade actionType: ${t['actionType']}';
  }
}).toList();

void a() {
  List<Widget> trades = portfolioTrades.map((trade) => trade.build()).toList();
}
*/

class AssetTrade extends Trade {
  final String secId;
  final String boardId;
  final String shortName;
  final num price;
  final int quantity;
  final num fee;

  num get operationTotal => price * quantity + fee * (action == 'Купить' ? 1 : -1);

  AssetTrade({
    required String date,
    required String action,
    required String currencyCode,
    required String? note,
    required this.secId,
    required this.shortName,
    required this.boardId,
    required this.price,
    required this.quantity,
    required this.fee,
  }) : super(
          actionType: 'Акции',
          action: action, // покупка / продажа
          date: date,
          currencyCode: currencyCode,
          note: note,
        );

  // Redirecting named constructor
  AssetTrade.fromJson(Map<String, dynamic> json)
      : this(
          action: json['action'],
          date: json['date'],
          currencyCode: json['currencyCode'],
          note: json['note'],
          secId: json['secId'],
          boardId: json['boardId'],
          shortName: json['shortName'],
          price: json['price'],
          quantity: json['quantity'],
          fee: json['fee'],
        );

  @override
  Map<String, dynamic> toJson() {
    return {
      // * Передаем ключ type, чтобы определять наследника
      'actionType': actionType,
      'action': action,
      'date': date,
      'currencyCode': currencyCode,
      'note': note,
      'secId': secId,
      'boardId': boardId,
      'shortName': shortName,
      'price': price,
      'quantity': quantity,
      'fee': fee,
    };
  }
}

class MoneyTrade extends Trade {
  final num operationTotal;
  // num get operationTotal => _operationTotal;

  MoneyTrade({
    required String date,
    required String action,
    required String currencyCode,
    required num operationTotal,
    required String? note,
  })  : operationTotal = operationTotal,
        super(
          actionType: 'Деньги',
          action: action, // Внесение / вывод / доход / расход
          date: date,
          currencyCode: currencyCode,
          note: note,
        );

  MoneyTrade.fromJson(Map<String, dynamic> json)
      : this(
          action: json['action'],
          date: json['date'],
          currencyCode: json['currencyCode'],
          operationTotal: json['operationTotal'],
          note: json['note'],
        );

  @override
  Map<String, dynamic> toJson() {
    return {
      'actionType': actionType, // ! Передаем параметр, через который потом будем определять, какой класс создавать
      'action': action,
      'date': date,
      'currencyCode': currencyCode,
      'operationTotal': operationTotal,
      'note': note,
    };
  }
}

class DividendsTrade extends Trade {
  final String secId;
  final String boardId;
  final num divPerShare;
  final int numShares;

  num get operationTotal => divPerShare * numShares;

  DividendsTrade({
    required String date,
    required String currencyCode,
    required String? note,
    required this.secId,
    required this.boardId,
    required this.divPerShare,
    required this.numShares,
  }) : super(
          actionType: 'Акции',
          action: 'Дивиденды',
          date: date,
          currencyCode: currencyCode,
          note: note,
        );

  DividendsTrade.fromJson(Map<String, dynamic> json)
      : this(
          date: json['date'],
          currencyCode: json['currencyCode'],
          secId: json['secId'],
          boardId: json['boardId'],
          divPerShare: json['divPerShare'],
          numShares: json['numShares'],
          note: json['note'],
        );

  @override
  Map<String, dynamic> toJson() {
    return {
      'actionType': actionType,
      'action': action, // ! Передаем параметр, через который потом будем определять, какой класс создавать
      'date': date,
      'currencyCode': currencyCode,
      'note': note,
      'secId': secId,
      'boardId': boardId,
      'divPerShare': divPerShare,
      'numShares': numShares,
    };
  }
}
