import 'package:auto_size_text_pk/auto_size_text_pk.dart';
import 'package:flutter/material.dart';
import 'package:track_wealth/core/portfolio/portfolio_trade.dart';
import 'package:track_wealth/core/util/app_color.dart';
import 'package:track_wealth/core/util/formatters.dart';
import 'package:track_wealth/core/util/portfolio_helpers.dart';

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
