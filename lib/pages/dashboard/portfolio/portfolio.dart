import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_wealth/common/app_responsive.dart';
import 'package:track_wealth/common/constants.dart';
import 'package:track_wealth/common/portfolio_state.dart';

class Portfolio extends StatefulWidget {
  @override
  _PortfolioState createState() => _PortfolioState();
}

class _PortfolioState extends State<Portfolio> {
  Map<String, bool> colFilter;
  Map<String, dynamic> sortedColumn;
  int sortedColumnIndex;
  List<Map<String, dynamic>> myColumns;
  ScrollController tableScrollController = ScrollController();
  List<PortfolioAsset> portfolioAssets;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    colFilter = AppResponsive.isMobile(context) ? context.watch<PortfolioState>().mobileColumnFilter : context.watch<PortfolioState>().columnFilter;
    myColumns = getFilteredColumns();
  }

  final List<Map<String, dynamic>> allColumns = [
    {'title': 'Актив', 'type': String},
    {'title': 'Количество', 'type': num, 'tooltip': 'Размер лота * Количество лотов'},
    {'title': 'Ср. Цена, ₽', 'type': num, 'tooltip': 'Средняя цена открытой позиции'},
    {'title': 'Прибыль, ₽', 'type': num, 'tooltip': 'Суммарная прибыль по инструменту за все время, включающая дивиденды и комиссию'},
    {'title': 'Прибыль, %', 'type': num, 'tooltip': 'Средневзвешенная процентная прибыль по инструменту за все время, включающая дивиденды и комиссию'},
    {'title': 'Доля, %', 'type': num, 'tooltip': 'Доля инструмента, относительно стоимость портфеля'},
    {'title': 'Стоимость, ₽', 'type': num, 'tooltip': 'Рыночная стоимость позиции по инструменту в портфеле'}
  ];

  Future<List<PortfolioAsset>> getPortfolioAssets() async {
    portfolioAssets = await context.read<PortfolioState>().getPortfolioAssets();
    return portfolioAssets;
  }

  @override
  Widget build(BuildContext context) {
    sortedColumn = Provider.of<PortfolioState>(context, listen: false).sortedColumn;

    if ((sortedColumn['title'] != null)) {
      sortedColumnIndex = myColumns.map((e) => e['title']).toList().indexOf(sortedColumn['title']);

      // ! Если меняется AppResposive и убирается отсортированная колонка, то ее уже не будет в myColumns
      if (sortedColumnIndex == -1) sortedColumnIndex = null;
    } else {
      sortedColumnIndex = null;
    }

    return FutureBuilder(
      future: getPortfolioAssets(),
      builder: (BuildContext context, AsyncSnapshot<List<PortfolioAsset>> snapshot) {
        // Если данные не были загружены и еще загружаются
        if (!snapshot.hasData) {
          return Container(
            height: 400,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        return Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColor.grey,
            borderRadius: BorderRadius.circular(10),
          ),
          child: buildTable(),
        );
      },
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

class PortfolioAsset {
  final String name; // Актив
  final num quantity; // Количество штук (размер лота * количество лотов)
  final num meanPrice; // Средняя цена покупки
  final num profit; // Доход (Руб) с момента покупки
  final num yield; // Доход (%) с момента покупки
  final num share; // Доля в портфеле
  final num worth; // Текущая рыночная стоимость

  PortfolioAsset(this.name, this.quantity, this.meanPrice, this.profit, this.yield, this.share, this.worth);

  dynamic getParam(int index, {@required Map<String, bool> filter}) {
    return [
      name,
      if (filter['Количество']) quantity,
      if (filter['Ср. Цена, ₽']) meanPrice,
      if (filter['Прибыль, ₽']) profit,
      if (filter['Прибыль, %']) yield,
      if (filter['Доля, %']) share,
      worth,
    ][index];
  }

  List<dynamic> getValues({@required Map<String, bool> filter}) {
    return [
      name,
      if (filter['Количество']) MyFormatter.intFormat(quantity),
      if (filter['Ср. Цена, ₽']) meanPrice,
      if (filter['Прибыль, ₽']) profit,
      if (filter['Прибыль, %']) yield,
      if (filter['Доля, %']) share,
      worth,
    ];
  }

  @override
  String toString() {
    return "PortfolioAsset($name, $quantity, $meanPrice, $profit, $yield, $share, $worth)";
  }
}
