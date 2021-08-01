import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_wealth/common/constants.dart';
import 'package:track_wealth/common/app_responsive.dart';
import 'package:track_wealth/common/drawer_state.dart';

import 'columns_filter.dart';
import 'operations/operations.dart';

class Header extends StatefulWidget {
  @override
  _HeaderState createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  final TextStyle headerStyle = TextStyle(fontWeight: FontWeight.w600, color: AppColor.black, fontSize: 22);

  late num portfolioTotal;
  late List<num> todayChange;
  late List<num> allTimeChange;

  @override
  void initState() {
    super.initState();
    portfolioTotal = calculateTotal();
    todayChange = calculateTodayChange();
    allTimeChange = calculalteAllTimeChange();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AmountRow(headerStyle: headerStyle, portfolioTotal: portfolioTotal),
              Operations(),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              amountChangedCard(context),
              ColumnFilterIcon(),
            ],
          ),
        ],
      ),
    );
  }

  Container amountChangedCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColor.grey,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          changeCardColumn('Cегодня: ', todayChange),
          SizedBox(width: AppResponsive.isMobile(context) ? 20 : 85),
          changeCardColumn('За все время: ', allTimeChange),
        ],
      ),
    );
  }

  Widget changeCardColumn(String title, List<num> value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: AppColor.darkGrey, fontSize: 17)),
        SizedBox(height: 10),
        Text("${MyFormatter.numFormat(value[0])} ₽", style: changeTextStyle(value[0])),
        Text("${value[1]}%", style: changeTextStyle(value[1])),
      ],
    );
  }

  num calculateTotal() {
    // ! round to 2 decimal
    return 154880.20;
  }

  List<num> calculateTodayChange() {
    return [-5387, -0.5];
  }

  List<num> calculalteAllTimeChange() {
    return [22854, 12.3];
  }

  TextStyle changeTextStyle(num change) {
    return TextStyle(
      color: change >= 0 ? AppColor.green : AppColor.red,
      fontSize: 18,
    );
  }
}

class AmountRow extends StatelessWidget {
  const AmountRow({
    required this.headerStyle,
    required this.portfolioTotal,
  });

  final TextStyle headerStyle;
  final num portfolioTotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (!AppResponsive.isDesktop(context))
          IconButton(
            icon: Icon(Icons.menu),
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onPressed: context.read<DrawerState>().controlMenu,
          ),
        if (!AppResponsive.isMobile(context)) ...{
          Text('Стоимость портфеля:', style: headerStyle),
          SizedBox(width: 20),
        },
        Text(
          "${MyFormatter.numFormat(portfolioTotal)} ₽",
          textAlign: TextAlign.end,
          style: headerStyle,
        ),
      ],
    );
  }
}
