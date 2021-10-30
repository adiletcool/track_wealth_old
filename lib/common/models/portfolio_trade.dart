import 'package:auto_size_text_pk/auto_size_text_pk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:track_wealth/common/constants.dart';
import 'package:track_wealth/common/static/app_color.dart';
import 'package:track_wealth/common/static/formatters.dart';
import 'package:track_wealth/common/static/portfolio_helpers.dart';

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

class TradeCard extends StatelessWidget {
  final Trade trade;
  const TradeCard(this.trade);

  @override
  Widget build(BuildContext context) {
    Color tradeColor = AppColor.themeBasedColor(context, AppColor.lightBlue, AppColor.lightGrey);
    Color tradeTitleColor = AppColor.themeBasedColor(context, Colors.white, AppColor.black);
    Color tradeSubtitleColor = AppColor.themeBasedColor(context, AppColor.greyTitle, AppColor.darkGrey);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          height: 60,
          decoration: BoxDecoration(
            color: tradeColor,
            border: Border(
              left: BorderSide(
                color: getBorderColor(),
                width: 10,
                style: BorderStyle.solid,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AutoSizeText(
                    getCardTitle(),
                    maxFontSize: 15,
                    style: TextStyle(color: tradeTitleColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    getCardSubTitle(),
                    style: TextStyle(fontSize: 14, color: tradeSubtitleColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ), // TODO autosize
                ],
              ),
              Row(
                children: [
                  AutoSizeText(
                    MyFormatter.numFormat(trade.operationTotal) + getCurrencySymbol(),
                    maxFontSize: 15,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ), // TODO: format to currency, autosize
                  Icon(Icons.more_vert_outlined, size: 28, color: tradeSubtitleColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color getBorderColor() {
    switch (trade.action) {
      case 'buy':
      case 'deposit':
      case 'dividends':
      case 'revenue':
        return AppColor.green;
      case 'sell':
      case 'withdraw':
      case 'expense':
        return AppColor.redBlood;
      default:
        return Colors.indigo;
    }
  }

  String getCurrencySymbol() {
    String? symbol = availableCurrencies.firstWhere((c) => c['code'] == trade.currencyCode)['symbol'];
    symbol ??= '';
    return symbol;
  }

  String getCardTitle() {
    switch (trade.actionType) {
      case 'stocks':
        StockTrade _trade = trade as StockTrade;
        return '${actionsTitle[_trade.action]}: ${_trade.secId}';
      case 'money':
        return actionsTitle['money']!;
      default:
        return 'Unknown trade type ${trade.actionType}\n$trade';
    }
  }

  String getCardSubTitle() {
    switch (trade.actionType) {
      case 'stocks':
        StockTrade _trade = trade as StockTrade;
        return '${_trade.quantity} шт. по ${_trade.price}';
      case 'money':
        return actionsTitle[trade.action]!;
      default:
        return 'Unknown trade type ${trade.actionType}\n$trade';
    }
  }
}
