import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_wealth/common/app_responsive.dart';
import 'package:track_wealth/common/constants.dart';
import 'package:track_wealth/common/models/column_filter.dart';
import 'package:track_wealth/common/models/portfolio_asset.dart';
import 'package:track_wealth/common/models/portfolio_currency.dart';
import 'package:track_wealth/common/services/dashboard.dart';
import 'package:track_wealth/pages/dashboard/header/operations/add_operation_dialog/add_operation_dialog.dart';

class PortfolioTable extends StatefulWidget {
  final List<PortfolioAsset> portfolioAssets;
  final List<PortfolioCurrency> currencies;

  const PortfolioTable({required this.portfolioAssets, required this.currencies});

  @override
  _PortfolioTableState createState() => _PortfolioTableState(portfolioAssets, currencies);
}

class _PortfolioTableState extends State<PortfolioTable> {
  final List<PortfolioAsset> portfolioAssets;
  final List<PortfolioCurrency> currencies;

  late TableState tableState;
  late Map<String, bool> colFilter;

  late List<Map<String, dynamic>> myColumns;
  late Map<String, dynamic> sortedColumn;
  int? sortedColumnIndex;

  ScrollController tableScrollController = ScrollController();

  _PortfolioTableState(this.portfolioAssets, this.currencies);

  final List<Map<String, dynamic>> allColumns = ColumnFilter.getAllColumns();

  @override
  Widget build(BuildContext context) {
    tableState = context.watch<TableState>();
    colFilter = AppResponsive.isMobile(context) ? tableState.mobileColumnFilter : tableState.columnFilter;

    myColumns = getFilteredColumns();
    sortedColumn = tableState.sortedColumn;

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
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          portfolioAssets.length != 0 ? buildTable() : emptyPortfolioInfo(),
          if (currencies.length > 0) ...getCurrencyRows(),
        ],
      ),
    );
  }

  Widget buildTable() {
    return DataTable2(
      scrollController: tableScrollController,
      sortAscending: sortedColumn['ascending'],
      sortColumnIndex: sortedColumnIndex,
      columns: getColumns(myColumns),
      rows: getRows(),
      minWidth: myColumns.length * 800 / 7,
      columnSpacing: 10,
      horizontalMargin: AppResponsive.isMobile(context) ? 5 : null,
      showBottomBorder: true,
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
        tooltip: tooltips[column['title']],
      );
    }).toList();
  }

  List<DataRow> getRows() {
    return portfolioAssets.map((asset) {
      final cells = asset.getColumnValues(filter: colFilter);
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
    print("sorted column ${myColumns[index]['title']}: ${ascending ? 'as' : 'des'}cending");

    context.read<DashboardState>().sortPortfolio(index, ascending, colFilter);
    tableState.updateSortedColumn(myColumns[index]['title'], ascending);
    setState(() {});
  }

  List<Widget> getCurrencyRows() {
    return currencies
        .map(
          (currency) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(currency.name),
                Text(MyFormatter.currencyFormat(currency.value, currency.locale, currency.symbol)),
              ],
            ),
          ),
        )
        .toList();
  }

  Widget emptyPortfolioInfo() {
    return Column(
      children: [
        SizedBox(height: 5),
        Text('В портфеле нет акций', style: TextStyle(fontSize: 20)),
        SizedBox(height: 40),
        InkWell(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: roundedBoxDecoration.copyWith(
              color: Color(0xff008a86),
            ),
            child: Text(
              'Добавить сделку',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          ),
          onTap: addOperation,
        ),
        SizedBox(height: 40),
      ],
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
}
