import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:track_wealth/common/models/portfolio.dart';
import 'package:track_wealth/common/orientation.dart';
import 'package:track_wealth/common/services/portfolio.dart';
import 'package:track_wealth/common/static/app_color.dart';
import 'package:track_wealth/pages/dashboard/portfolio/settings.dart';

class Operations extends StatefulWidget {
  @override
  _OperationsState createState() => _OperationsState();
}

class _OperationsState extends State<Operations> {
  late Iterable<Portfolio> portfolios;
  late Portfolio selectedPortfolio;
  late Iterable<String> portfolioNames;
  @override
  void initState() {
    super.initState();
    portfolios = context.read<PortfolioState>().portfolios;
    selectedPortfolio = context.read<PortfolioState>().selectedPortfolio;
    portfolioNames = portfolios.map((p) => p.name);
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColor.themeBasedColor(context, AppColor.lightBlue, AppColor.lightGrey);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: bgColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              child: Icon(Icons.add_circle_rounded, size: 26),
            ),
            onTap: () => Navigator.pushNamed(context, '/dashboard/add_operation').then((v) => setOrientationMode(canLandscape: true)),
          ),
          SizedBox(width: 10),
          InkWell(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              child: Icon(Icons.settings, size: 26),
            ),
            onTap: () => Navigator.pushNamed(context, '/dashboard/settings', arguments: PortfolioSettingsAgrs(selectedPortfolio.name)),
          ),
        ],
      ),
    );
  }
}
