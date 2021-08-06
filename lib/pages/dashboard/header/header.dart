import 'package:auto_size_text_pk/auto_size_text_pk.dart';
import 'package:flutter/material.dart';
import 'package:track_wealth/common/constants.dart';
import 'package:track_wealth/common/app_responsive.dart';
import 'operations/operations.dart';

class Header extends StatefulWidget {
  final GlobalKey<ScaffoldState> drawerKey;

  // * Рыночная стоимость всех активов вместе + рубли + валюта, переведенная в рубли по текущему курсу
  final num portfolioTotal;

  const Header({
    required this.drawerKey,
    required this.portfolioTotal,
  });

  @override
  _HeaderState createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  late num portfolioTotal;

  @override
  void initState() {
    super.initState();
    portfolioTotal = widget.portfolioTotal;
  }

  void openDrawer() => widget.drawerKey.currentState!.openDrawer();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!AppResponsive.isDesktop(context)) drawerIcon(),
          Expanded(
            child: AmountRow(portfolioTotal: portfolioTotal),
          ),
          Operations(),
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
}

class AmountRow extends StatelessWidget {
  const AmountRow({required this.portfolioTotal});

  final num portfolioTotal;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Рыночная стоимость всех активов, а также денежные средства, конвертированные в рубли по текущему курсу.',
      showDuration: const Duration(seconds: 6),
      child: AutoSizeText(
        "${!AppResponsive.isMobile(context) ? 'Стоимость портфеля:    ' : ''}" + "${MyFormatter.numFormat(portfolioTotal)} ₽",
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 200),
        maxLines: 1,
        maxFontSize: 23,
      ),
    );
  }
}
