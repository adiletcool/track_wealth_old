import 'package:flutter/material.dart';
import 'package:track_wealth/common/constants.dart';
import 'package:track_wealth/common/static/app_color.dart';
import 'package:track_wealth/common/static/decorations.dart';

class TradesPage extends StatefulWidget {
  @override
  _TradesPageState createState() => _TradesPageState();
}

class _TradesPageState extends State<TradesPage> {
  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColor.themeBasedColor(context, AppColor.darkBlue, AppColor.white);

    return Container(
      color: bgColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TradeCard(actionsTitle['money']!, actionsTitle['deposit']!, 50000),
          TradeCard(actionsTitle['buy']! + ': GAZP', '2000 шт. по 60 руб.', 120000),
        ],
      ),
    );
  }
}

class TradeCard extends StatelessWidget {
  final String title, subtitle;
  final num operationTotal;

  const TradeCard(this.title, this.subtitle, this.operationTotal);

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
              left: BorderSide(color: AppColor.green, width: 11, style: BorderStyle.solid),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: TextStyle(fontSize: 16, color: tradeTitleColor)),
                  Text(subtitle, style: TextStyle(fontSize: 15, color: tradeSubtitleColor)), // TODO autosize
                ],
              ),
              Row(
                children: [
                  Text(operationTotal.toString(), style: TextStyle(fontSize: 14.5)), // TODO: format to currency, autosize
                  Icon(Icons.more_vert_outlined, size: 28, color: tradeSubtitleColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
