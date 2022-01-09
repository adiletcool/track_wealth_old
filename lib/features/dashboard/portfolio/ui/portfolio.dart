import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:track_wealth/core/portfolio/portfolio_currency.dart';
import 'package:track_wealth/core/portfolio/portfolio_stock.dart';
import 'package:track_wealth/core/util/app_color.dart';
import 'package:track_wealth/core/util/decorations.dart';
import 'package:track_wealth/core/util/formatters.dart';
import 'package:track_wealth/core/util/orientation.dart';
import 'package:track_wealth/core/util/portfolio_helpers.dart';
import 'package:track_wealth/features/dashboard/portfolio/service/portfolio.dart';
import 'package:track_wealth/features/dashboard/portfolio/service/table_state.dart';

class PortfolioTable extends StatefulWidget {
  final List<PortfolioStock> portfolioStocks;
  final List<PortfolioCurrency> currencies;

  const PortfolioTable({required this.portfolioStocks, required this.currencies});

  @override
  _PortfolioTableState createState() => _PortfolioTableState(portfolioStocks, currencies);
}

class _PortfolioTableState extends State<PortfolioTable> {
  final List<PortfolioStock> portfolioStocks;
  final List<PortfolioCurrency> currencies;

  late TableState tableState;
  late Map<String, bool> colFilter;

  late List<Map<String, dynamic>> myColumns;
  late Map<String, dynamic> sortedColumn;
  int? sortedColumnIndex;

  ScrollController tableScrollController = ScrollController();

  _PortfolioTableState(this.portfolioStocks, this.currencies);

  final List<Map<String, dynamic>> allColumns = ColumnFilter.getAllColumns();

  @override
  Widget build(BuildContext context) {
    tableState = context.watch<TableState>();

    colFilter = AppOrientation.isPortrait(context) ? tableState.mobileColumnFilter : tableState.columnFilter;

    myColumns = getFilteredColumns();
    sortedColumn = tableState.sortedColumn;

    if ((sortedColumn['title'] != null)) {
      sortedColumnIndex = myColumns.map((e) => e['title']).toList().indexOf(sortedColumn['title']);

      // ! Если меняется AppResposive и убирается отсортированная колонка, то ее уже не будет в myColumns
      if (sortedColumnIndex == -1) sortedColumnIndex = null;
    } else {
      sortedColumnIndex = null;
    }

    Color bgColor = AppColor.themeBasedColor(context, AppColor.lightBlue, AppColor.lightGrey);

    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          portfolioStocks.length != 0 ? buildTable() : emptyPortfolioInfo(),
          Divider(
            thickness: 1,
            color: AppColor.greyTitle,
          ),
          ...getCurrencyRows()
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
      horizontalMargin: AppOrientation.isPortrait(context) ? 5 : null,
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
    return portfolioStocks.map((stock) {
      final cells = stock.getColumnValues(filter: colFilter);
      return DataRow2(
        cells: getCells(cells),
        onTap: () {
          print(stock);
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

    context.read<PortfolioState>().sortPortfolio(index, ascending, colFilter);
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
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Center(child: Lottie.asset('assets/animations/search-empty.json', height: MediaQuery.of(context).size.height * .25, reverse: true)),
        Divider(indent: 40, endIndent: 40, height: 40),
        Text('У вас в портфеле нет акций', style: TextStyle(fontSize: 20)),
        SizedBox(height: 40),
        InkWell(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: roundedBoxDecoration.copyWith(
              color: AppColor.selected,
            ),
            child: Text(
              'Добавить сделку',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          ),
          onTap: () => Navigator.pushNamed(context, '/dashboard/add_operation'),
        ),
        SizedBox(height: 20),
      ],
    );
  }
}
