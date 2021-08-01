import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_wealth/common/app_responsive.dart';
import 'package:track_wealth/common/constants.dart';
import 'package:track_wealth/common/portfolio_state.dart';

class ColumnFilterIcon extends StatefulWidget {
  @override
  _ColumnFilterIconState createState() => _ColumnFilterIconState();
}

class _ColumnFilterIconState extends State<ColumnFilterIcon> {
  late Map<String, bool> colFilter;

  List<PopupMenuItem> getPopUpMenuItems() {
    return colFilter.keys
        .map(
          (String column) => PopupMenuItem(
            child: StatefulBuilder(
              builder: (_context, _setState) => SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                title: Text(column, style: TextStyle(fontSize: 14)),
                value: colFilter[column]!,
                onChanged: (bool newValue) => filterColumn(column, newValue, _setState),
                dense: true,
              ),
            ),
          ),
        )
        .toList();
  }

  void filterColumn(String columnName, bool newValue, Function _setState) {
    context.read<PortfolioState>().updateFilter(columnName, newValue, AppResponsive.isMobile(context));
    _setState(() => colFilter[columnName] = newValue);
  }

  @override
  Widget build(BuildContext context) {
    colFilter = AppResponsive.isMobile(context) ? context.watch<PortfolioState>().mobileColumnFilter : context.watch<PortfolioState>().columnFilter;

    return PopupMenuButton(
      icon: Icon(Icons.view_week_rounded, color: Colors.black87),
      itemBuilder: (BuildContext context) => getPopUpMenuItems(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.all(0),
      tooltip: 'Фильтр',
      color: AppColor.grey,
      offset: Offset(0, 40),
    );
  }
}
