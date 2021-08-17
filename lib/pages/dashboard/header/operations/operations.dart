import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:track_wealth/common/constants.dart';
import 'package:provider/provider.dart';
import 'package:track_wealth/common/models/portfolio.dart';
import 'package:track_wealth/common/services/dashboard.dart';
import 'package:track_wealth/pages/dashboard/portfolio/settings.dart';

import 'add_operation_dialog/add_operation_dialog.dart';

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
    portfolios = context.read<DashboardState>().portfolios;
    selectedPortfolio = context.read<DashboardState>().selectedPortfolio;
    portfolioNames = portfolios.map((p) => p.name);
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColor.themeBasedColor(context, AppColor.bgDark, AppColor.grey);
    Color popupBgColor = AppColor.themeBasedColor(context, Color(0xff292929), AppColor.grey);

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
            // radius: ,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              child: Icon(Icons.add_circle_rounded, size: 26),
            ),
            onTap: addOperation,
          ),
          SizedBox(width: 10),
          PopupMenuButton(
            color: popupBgColor,
            tooltip: 'Выбрать портфель',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            offset: Offset(0, 35),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              child: Icon(Icons.cases_rounded, size: 26),
            ),
            itemBuilder: (context) => getPortfolioNames(portfolioNames),
          ),
        ],
      ),
    );
  }

  void addOperation() {
    showDialog(
      context: context,
      builder: (context) {
        return AddOperationDialog();
      },
    );
  }

  List<PopupMenuEntry> getPortfolioNames(Iterable<String> names) {
    Color _color = Color(0xff4093f2);
    List<PopupMenuEntry> nameItems = [];
    nameItems.addAll(
      names.map(
        (name) => PopupMenuItem(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ListTile(
            horizontalTitleGap: 0,
            minVerticalPadding: 0,
            contentPadding: const EdgeInsets.all(0),
            title: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: name == selectedPortfolio.name ? _color : null),
            ),
            trailing: name != selectedPortfolio.name
                ? null
                : IconButton(
                    icon: Icon(Icons.settings),
                    onPressed: () => Navigator.pushNamed(context, '/dashboard/settings', arguments: PortfolioSettingsAgrs(name)),
                  ),
            onTap: () {
              context.read<DashboardState>().changeSelectedPortfolio(name);
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );

    nameItems.add(PopupMenuDivider());
    nameItems.add(
      PopupMenuItem(
        padding: const EdgeInsets.all(0),
        child: ListTile(
          contentPadding: const EdgeInsets.all(0),
          horizontalTitleGap: 0,
          minVerticalPadding: 0,
          title: Text(
            'Добавить портфель',
            style: TextStyle(color: _color),
            textAlign: TextAlign.center,
          ),
          onTap: () => Navigator.pushNamed(context, '/dashboard/add'),
        ),
      ),
    );

    return nameItems;
  }
}
