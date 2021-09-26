import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_wealth/common/orientation.dart';
import 'package:track_wealth/common/services/portfolio.dart';
import 'package:track_wealth/common/static/app_color.dart';

class ColumnFilterButton extends StatefulWidget {
  @override
  _ColumnFilterButtonState createState() => _ColumnFilterButtonState();
}

class _ColumnFilterButtonState extends State<ColumnFilterButton> {
  late Map<String, bool> colFilter;

  @override
  Widget build(BuildContext context) {
    colFilter = AppOrientation.isPortrait(context) ? context.read<TableState>().mobileColumnFilter : context.read<TableState>().columnFilter;

    return PopupMenuButton(
      icon: Icon(Icons.view_week_rounded),
      itemBuilder: (BuildContext context) => getPopUpMenuItems(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.all(0),
      tooltip: 'Фильтр',
      offset: Offset(0, 40),
    );
  }

  void filterColumn(String columnName, bool newValue, Function _setState) {
    print('Filter column $columnName: $newValue');
    context.read<TableState>().updateFilter(columnName, newValue, AppOrientation.isPortrait(context));
    _setState(() {});
  }

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
                activeColor: AppColor.selected,
              ),
            ),
          ),
        )
        .toList();
  }
}
