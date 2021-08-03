import 'package:auto_size_text_pk/auto_size_text_pk.dart';
import 'package:flutter/material.dart';
import 'package:track_wealth/common/constants.dart';
import 'package:track_wealth/common/app_responsive.dart';
import 'columns_filter.dart';
import 'operations/operations.dart';

class Header extends StatefulWidget {
  final GlobalKey<ScaffoldState> drawerKey;
  final num portfolioTotal;

  const Header({required this.drawerKey, required this.portfolioTotal});

  @override
  _HeaderState createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  late List<num> todayChange;
  late List<num> allTimeChange;

  @override
  void initState() {
    super.initState();
    todayChange = getTodayChange();
    allTimeChange = calculalteAllTimeChange();
  }

  List<num> getTodayChange() {
    return [-5387, -0.5];
  }

  void openDrawer() => widget.drawerKey.currentState!.openDrawer();

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
              if (!AppResponsive.isDesktop(context)) drawerIcon(),
              Expanded(
                child: AmountRow(portfolioTotal: widget.portfolioTotal),
              ),
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

  Widget drawerIcon() {
    return IconButton(
      icon: Icon(Icons.menu),
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onPressed: openDrawer,
    );
  }

  Container amountChangedCard(BuildContext context) {
    Color bgColor = Theme.of(context).brightness == Brightness.dark ? AppColor.bgDark : AppColor.grey;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
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
    Color textColor = Theme.of(context).brightness == Brightness.dark ? Colors.grey : AppColor.darkGrey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: textColor, fontSize: 17)),
        SizedBox(height: 10),
        Text("${MyFormatter.numFormat(value[0])} ₽", style: changeTextStyle(value[0])),
        Text("${value[1]}%", style: changeTextStyle(value[1])),
      ],
    );
  }

  List<num> calculalteAllTimeChange() {
    return [122854, 12.3];
  }

  TextStyle changeTextStyle(num change) {
    return TextStyle(
      color: change >= 0 ? AppColor.green : AppColor.red,
      fontSize: 18,
    );
  }
}

class AmountRow extends StatelessWidget {
  const AmountRow({required this.portfolioTotal});

  final num portfolioTotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: AutoSizeText(
        "${!AppResponsive.isMobile(context) ? 'Стоимость портфеля:    ' : ''}" + "${MyFormatter.numFormat(portfolioTotal)} ₽",
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 200),
        maxLines: 1,
        maxFontSize: 23,
      ),
    );
  }
}
