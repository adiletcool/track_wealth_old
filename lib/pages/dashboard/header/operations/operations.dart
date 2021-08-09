import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:track_wealth/common/constants.dart';
import 'package:provider/provider.dart';
import 'package:track_wealth/common/services/dashboard.dart';

import 'add_operation_dialog/add_operation_dialog.dart';

class Operations extends StatefulWidget {
  @override
  _OperationsState createState() => _OperationsState();
}

class _OperationsState extends State<Operations> {
  @override
  Widget build(BuildContext context) {
    Color bgColor = Theme.of(context).brightness == Brightness.dark ? AppColor.bgDark : AppColor.grey;
    Iterable<String>? portfolioNames = context.read<DashboardState>().portfolios!.map((p) => p.name);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: bgColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.add_circle_rounded, size: 28),
            ),
            onTap: addOperation,
          ),
          SizedBox(width: 10),
          PopupMenuButton(
            tooltip: 'Выбрать портфель',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            offset: Offset(0, 35),
            icon: Icon(Icons.cases_rounded, size: 28),
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
    List<PopupMenuEntry> nameItems = [];
    nameItems.addAll(names.map((name) => PopupMenuItem(
          child: ListTile(
            horizontalTitleGap: 0,
            minVerticalPadding: 0,
            contentPadding: const EdgeInsets.all(0),
            title: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {},
            ),
          ),
        )));

    nameItems.add(PopupMenuDivider());
    nameItems.add(PopupMenuItem(
      child: ListTile(
        contentPadding: const EdgeInsets.all(0),
        horizontalTitleGap: 0,
        minVerticalPadding: 0,
        title: Text(
          'Добавить портфель',
          style: TextStyle(color: AppColor.selected),
          textAlign: TextAlign.center,
        ),
        onTap: () => Navigator.pushNamed(context, '/dashboard/add'),
      ),
    ));

    return nameItems;
  }
}
