import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:track_wealth/core/util/formatters.dart';
import 'package:track_wealth/features/trades/trade_card.dart';

abstract class Trade {
  final String actionType; // stocks / money
  final String action; // buy / sell / dividends / deposit ...
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

  Widget build(BuildContext context) => TradeCard(this);

  @override
  String toString() {
    return 'Trade($actionType, $action, ${MyFormatter.numFormat(operationTotal)}, ${date.substring(0, 19)}, $currencyCode)';
  }

  factory Trade.fromJson(Object json) {
    Map<String, dynamic> _trade = json as Map<String, dynamic>;

    switch (_trade['actionType']) {
      case 'stocks':
        if (_trade['action'] == 'dividends')
          return DividendsTrade.fromJson(_trade);
        else
          return StockTrade.fromJson(_trade);
      case 'money':
        return MoneyTrade.fromJson(_trade);
      default:
        throw 'Unknown actionType ${_trade['actionType']}';
    }
  }
}

class StockTrade extends Trade {
  final String secId;
  final String boardId;
  final String shortName;
  final num price;
  final int quantity;
  final num fee;

  num get operationTotal => price * quantity + fee * (action == 'buy' ? 1 : -1);
  num get meanPrice => operationTotal / quantity;

  StockTrade({
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
          actionType: 'stocks',
          action: action, // покупка / продажа
          date: date,
          currencyCode: currencyCode,
          note: note,
        );

  @override
  String toString() {
    return 'Trade($actionType, $action, $secId, ${MyFormatter.numFormat(operationTotal)}, ${date.substring(0, 19)}, $currencyCode)';
  }

  // Redirecting named constructor
  StockTrade.fromJson(Map<String, dynamic> json)
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
          actionType: 'stocks',
          action: 'dividends',
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
          actionType: 'money',
          action: action, // deposit / withdraw / revenue / expense
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
