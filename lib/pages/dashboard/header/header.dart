import 'package:auto_size_text_pk/auto_size_text_pk.dart';
import 'package:flutter/material.dart';
import 'package:track_wealth/common/orientation.dart';
import 'package:track_wealth/common/models/portfolio.dart';
import 'package:track_wealth/common/services/portfolio.dart';
import 'package:track_wealth/common/static/formatters.dart';
import 'package:track_wealth/common/static/portfolio_helpers.dart';
import 'package:track_wealth/pages/shimmers/shimmers.dart';
import 'operations.dart';
import 'package:provider/provider.dart';

class Header extends StatefulWidget {
  final GlobalKey<ScaffoldState> drawerKey;

  // * Рыночная стоимость всех активов вместе + рубли + валюта, переведенная в рубли по текущему курсу

  const Header({required this.drawerKey});

  @override
  _HeaderState createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
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
          drawerIcon(),
          Expanded(child: AmountRow()),
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

class AmountRow extends StatefulWidget {
  @override
  _AmountRowState createState() => _AmountRowState();
}

class _AmountRowState extends State<AmountRow> {
  late Portfolio portfolio;
  late num total;
  late String symbol;
  String currency = 'RUB'; // 'RUB' | 'USD000UTSTOM' | 'EUR_RUB__TOM'

  @override
  void initState() {
    super.initState();
    portfolio = context.read<PortfolioState>().selectedPortfolio;
  }

  @override
  Widget build(BuildContext context) {
    symbol = newUserCurrencies.firstWhere((c) => c['code'] == currency)['symbol'];

    return FutureBuilder(
      future: getConvertedTotal(currency),
      builder: (BuildContext context, AsyncSnapshot<num> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AmountRowShimmer();
        } else if (snapshot.hasData) {
          total = snapshot.data!;
          return GestureDetector(
            onTap: changePortfolioCurrency,
            child: Tooltip(
              message: tooltips['totalWorth']!,
              showDuration: const Duration(seconds: 6),
              child: AutoSizeText(
                "${!AppOrientation.isPortrait(context) ? 'Стоимость портфеля:    ' : ''}" + "${MyFormatter.numFormat(total)} $symbol",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 200),
                maxLines: 1,
                maxFontSize: 23,
              ),
            ),
          );
        } else {
          return Text(snapshot.error.toString());
        }
      },
    );
  }

  Future<num> getConvertedTotal(String currency) async {
    if (currency == 'RUB')
      return portfolio.total!;
    else {
      num exchangeRate = portfolio.currencies!.firstWhere((c) => c.code == currency).exchangeRate!;
      return portfolio.total! / exchangeRate;
    }
  }

  void changePortfolioCurrency() {
    String newCurrency = newCurrencies[currency]!;
    print('Set currency: $newCurrency');
    // context.read<DashboardState>().changeSelectedPortfolioCurrency(newCurrency);

    setState(() => currency = newCurrency);
  }

  static const Map<String, String> newCurrencies = {
    'RUB': 'USD000UTSTOM',
    'USD000UTSTOM': 'EUR_RUB__TOM',
    'EUR_RUB__TOM': 'RUB',
  };
}
