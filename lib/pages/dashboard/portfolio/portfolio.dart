import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_wealth/common/app_responsive.dart';
import 'package:track_wealth/common/constants.dart';
import 'package:track_wealth/common/models/portfolio_asset.dart';
import 'package:track_wealth/common/portfolio_state.dart';

class Portfolio extends StatefulWidget {
  final List<PortfolioAsset> portfolioAssets;
  const Portfolio({required this.portfolioAssets});

  @override
  _PortfolioState createState() => _PortfolioState(portfolioAssets);
}

class _PortfolioState extends State<Portfolio> {
  final List<PortfolioAsset> portfolioAssets;

  late Map<String, bool> colFilter;

  late List<Map<String, dynamic>> myColumns;
  late Map<String, dynamic> sortedColumn;
  int? sortedColumnIndex;

  ScrollController tableScrollController = ScrollController();

  _PortfolioState(this.portfolioAssets);

  final List<Map<String, dynamic>> allColumns = ColumnFilter.getAllColumns();

  @override
  Widget build(BuildContext context) {
    colFilter = AppResponsive.isMobile(context) ? context.watch<PortfolioState>().mobileColumnFilter : context.watch<PortfolioState>().columnFilter;

    myColumns = getFilteredColumns();
    sortedColumn = context.read<PortfolioState>().sortedColumn;

    if ((sortedColumn['title'] != null)) {
      sortedColumnIndex = myColumns.map((e) => e['title']).toList().indexOf(sortedColumn['title']);

      // ! Если меняется AppResposive и убирается отсортированная колонка, то ее уже не будет в myColumns
      if (sortedColumnIndex == -1) sortedColumnIndex = null;
    } else {
      sortedColumnIndex = null;
    }

    Color bgColor = Theme.of(context).brightness == Brightness.dark ? AppColor.bgDark : AppColor.grey;

    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: buildTable(),
    );
  }

  Widget buildTable() {
    return DataTable2(
      scrollController: tableScrollController,
      sortAscending: sortedColumn['ascending'],
      sortColumnIndex: sortedColumnIndex,
      columns: getColumns(myColumns),
      rows: getRows(),
      minWidth: (myColumns.length / 7) * 800,
      columnSpacing: 10,
      horizontalMargin: AppResponsive.isMobile(context) ? 5 : null,
    );
  }

  List<Map<String, dynamic>> getFilteredColumns() {
    return allColumns.where((Map<String, dynamic> el) {
      return colFilter[el['title']] ?? true;
    }).toList();
  }

  List<DataColumn> getColumns(List<Map<String, dynamic>> colNames) {
    return colNames.map((column) {
      return DataColumn2(
        label: Text(column['title'], maxLines: 1, overflow: TextOverflow.visible),
        numeric: column['type'] == num,
        onSort: sortColumn,
        tooltip: column['tooltip'],
      );
    }).toList();
  }

  List<DataRow> getRows() {
    return portfolioAssets.map((asset) {
      final cells = asset.getValues(filter: colFilter);
      return DataRow2(
        cells: getCells(cells),
        onTap: () {
          print(asset);
        },
      );
    }).toList();
  }

  List<DataCell> getCells(List<dynamic> cells) {
    return cells.map((value) {
      return DataCell(
        Text(
          value.runtimeType == String ? value.toString() : MyFormatter.numFormat(value),
          maxLines: 2,
          overflow: TextOverflow.fade,
        ),
      );
    }).toList();
  }

  void sortColumn(int index, bool ascending) {
    print("sorted ${ascending ? 'as' : 'des'}cending by ${myColumns[index]['title']}");

    context.read<PortfolioState>().sortPortfolio(index, ascending, colFilter);
    context.read<PortfolioState>().updateSortedColumn(myColumns[index]['title'], ascending);
    setState(() {});
  }
}
