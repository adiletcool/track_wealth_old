import 'package:flutter/material.dart';
import 'package:track_wealth/common/orientation.dart';
import 'package:track_wealth/common/static/app_color.dart';
import 'package:track_wealth/common/static/formatters.dart';
import 'package:track_wealth/common/static/portfolio_helpers.dart';

import 'columns_filter.dart';

class SubHeader extends StatefulWidget {
  final num portfolioTodayChange;
  final num portfolioAllTimeChange;
  final num portfolioStocksTotal;

  const SubHeader({
    required this.portfolioTodayChange,
    required this.portfolioAllTimeChange,
    required this.portfolioStocksTotal,
  });

  @override
  _SubHeaderState createState() => _SubHeaderState();
}

class _SubHeaderState extends State<SubHeader> {
  late num portfolioStocksTotal;

  // * Учитываются только изменения по акциям. Изменение иностранной валюты (если есть) не учитывается
  late num todayChange;
  late num todayChangePercent;
  late num allTimeChange;
  late num allTimeChangePercent;

  @override
  void initState() {
    super.initState();
    portfolioStocksTotal = widget.portfolioStocksTotal;

    todayChange = widget.portfolioTodayChange;
    todayChangePercent = getTodayChangePercent();

    allTimeChange = widget.portfolioAllTimeChange;
    allTimeChangePercent = getAllTimeChangePercent();
  }

  num getTodayChangePercent() {
    num res = todayChange * 100 / (portfolioStocksTotal - todayChange);
    if (res.isNaN) res = 0;
    return res;
  }

  num getAllTimeChangePercent() {
    num res = allTimeChange * 100 / (portfolioStocksTotal - allTimeChange);
    if (res.isNaN) res = 0;
    return res;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          amountChangedCard(context),
          ColumnFilterButton(), // widget.updateColumnFilter
        ],
      ),
    );
  }

  Widget amountChangedCard(BuildContext context) {
    Color bgColor = AppColor.themeBasedColor(context, AppColor.lightBlue, AppColor.lightGrey);
    Color textColor = AppColor.themeBasedColor(context, Colors.grey, AppColor.darkGrey);

    return Tooltip(
      message: tooltips['open_pos_change']!,
      showDuration: const Duration(seconds: 5),
      margin: const EdgeInsets.all(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            changeCardColumn('Cегодня: ', todayChange, todayChangePercent, textColor: textColor),
            SizedBox(width: AppOrientation.isPortrait(context) ? 20 : 85),
            changeCardColumn('За все время: ', allTimeChange, allTimeChangePercent, textColor: textColor),
          ],
        ),
      ),
    );
  }

  Widget changeCardColumn(String title, num todayChange, num todayChangePercent, {required Color textColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: textColor, fontSize: 15)),
        SizedBox(height: 5),
        Text("${MyFormatter.numFormat(todayChange)} ₽", style: changeTextStyle(todayChange)),
        Text("${MyFormatter.numFormat(todayChangePercent)}%", style: changeTextStyle(todayChangePercent)),
      ],
    );
  }

  TextStyle changeTextStyle(num change) {
    return TextStyle(
      color: change >= 0 ? AppColor.green : AppColor.red,
      fontSize: 17,
    );
  }
}
