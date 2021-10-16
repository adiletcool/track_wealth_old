import 'package:auto_size_text_pk/auto_size_text_pk.dart';
import 'package:flutter/material.dart';
import 'package:track_wealth/common/constants.dart';
import 'package:track_wealth/common/static/app_color.dart';
import 'package:track_wealth/common/static/formatters.dart';

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
          TradeCard(actionsTitle['buy']! + ': GAZP', '200 шт. по 60 руб.', 1200),
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
              left: BorderSide(color: AppColor.green, width: 10, style: BorderStyle.solid),
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
                    title,
                    maxFontSize: 15,
                    style: TextStyle(color: tradeTitleColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: tradeSubtitleColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ), // TODO autosize
                ],
              ),
              Row(
                children: [
                  Text(
                    MyFormatter.numFormat(operationTotal) + '',
                    maxLines: 1,
                    style: TextStyle(fontSize: 16),
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
}
