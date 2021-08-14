import 'package:flutter/material.dart';
import 'package:track_wealth/common/app_responsive.dart';
import 'package:track_wealth/common/constants.dart';

import 'columns_filter.dart';

class SubHeader extends StatefulWidget {
  final num portfolioTodayChange;
  final num portfolioAllTimeChange;
  final num portfolioAssetsTotal;

  const SubHeader({
    required this.portfolioTodayChange,
    required this.portfolioAllTimeChange,
    required this.portfolioAssetsTotal,
  });

  @override
  _SubHeaderState createState() => _SubHeaderState();
}

class _SubHeaderState extends State<SubHeader> {
  late num portfolioAssetsTotal;

  // * Учитываются только изменения по акциям. Изменение иностранной валюты (если есть) не учитывается
  late num todayChange;
  late num todayChangePercent;
  late num allTimeChange;
  late num allTimeChangePercent;

  @override
  void initState() {
    super.initState();
    portfolioAssetsTotal = widget.portfolioAssetsTotal;

    todayChange = widget.portfolioTodayChange;
    todayChangePercent = getTodayChangePercent();

    allTimeChange = widget.portfolioAllTimeChange;
    allTimeChangePercent = getAllTimeChangePercent();
  }

  num getTodayChangePercent() {
    num res = todayChange * 100 / (portfolioAssetsTotal - todayChange);
    if (res.isNaN) res = 0;
    return res;
  }

  num getAllTimeChangePercent() {
    num res = allTimeChange * 100 / (portfolioAssetsTotal - allTimeChange);
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
    Color bgColor = Theme.of(context).brightness == Brightness.dark ? AppColor.bgDark : AppColor.grey;
    Color textColor = Theme.of(context).brightness == Brightness.dark ? Colors.grey : AppColor.darkGrey;

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
            SizedBox(width: AppResponsive.isMobile(context) ? 20 : 85),
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
        Text(title, style: TextStyle(color: textColor, fontSize: 17)),
        SizedBox(height: 10),
        Text("${MyFormatter.numFormat(todayChange)} ₽", style: changeTextStyle(todayChange)),
        Text("${MyFormatter.numFormat(todayChangePercent)}%", style: changeTextStyle(todayChangePercent)),
      ],
    );
  }

  TextStyle changeTextStyle(num change) {
    return TextStyle(
      color: change >= 0 ? AppColor.selected : AppColor.red,
      fontSize: 18,
    );
  }
}
