import 'package:flutter/material.dart';
import 'package:track_wealth/pages/dashboard/portfolio/portfolio.dart';

class PortfolioState extends ChangeNotifier {
  List<PortfolioAsset>? portfolioAssets;

  Map<String, dynamic> sortedColumn = {'title': null, 'ascending': false};

  Map<String, bool> columnFilter = {
    'Количество': true,
    'Ср. Цена, ₽': true,
    'Прибыль, ₽': true,
    'Прибыль, %': true,
    'Доля, %': true,
  };

  Map<String, bool> mobileColumnFilter = {
    'Количество': false,
    'Ср. Цена, ₽': false,
    'Прибыль, ₽': true,
    'Прибыль, %': false,
    'Доля, %': false,
  };

  void updateFilter(String colName, bool newValue, bool isMobile) {
    (isMobile ? mobileColumnFilter : columnFilter).update(colName, (value) => newValue);

    if (sortedColumn['title'] != null) {
      // ! Случай, если убрали отсортированный столбик
      if ((colName == sortedColumn['title']) && (newValue == false)) {
        sortedColumn.update('title', (value) => null);
      }
    }
    notifyListeners();
  }

  void updateSortedColumn(String columnName, bool isAscending) {
    sortedColumn.update('title', (value) => columnName);
    sortedColumn.update('ascending', (value) => isAscending);
  }

  Future<List<PortfolioAsset>> getPortfolioAssets() async {
    if ((portfolioAssets == null)) {
      await Future.delayed(const Duration(seconds: 1));
      // await data from server...
      List<List<dynamic>> assetData = [
        ["ГМКНорНик", 15, 22160.00, 59930.10, 33.25, 25.82, 377070.00],
        ["ЛУКОЙЛ", 30, 4751.50, 55815.00, 39.24, 12.96, 189225.00],
        ["Сбербанк", 610, 191.37, 83733.30, 72.64, 12.37, 180621.00],
        ["Yandex clA", 33, 4177.80, 30280.34, 43.99, 11.51, 168148.20],
        ["AGRO-гдр", 100, 896.00, 17160.00, 19.15, 7.31, 106760.00],
        ["ДетскийМир", 400, 143.29, -973.60, -1.70, 3.86, 56344.00],
        ["Татнфт 3ао", 116, 540.20, -5790.30, -9.80, 3.83, 55923.60],
        ["Ростел-ао", 560, 81.78, 8761.20, 19.36, 3.57, 52119.20],
        ["MAIL-гдр", 32, 2042.40, -16268.80, -24.89, 3.36, 49088.00],
        ["Macy's", 38, 1200.00, 2188.90, 4.80, 3.27, 47804.00],
        ["FIVE-гдр", 16, 2420.00, 11807.38, 27.03, 2.60, 38008.00],
        ["FIXP-гдр", 40, 745.20, -5732.00, -19.23, 1.65, 24076.00],
        ["Лента др", 70, 252.10, -1055.22, -5.98, 1.13, 16590.00],
        ["АЛРОСА ао", 120, 69.97, 7048.60, 83.99, 1.06, 15445.20],
        ["М.видео", 22, 728.60, -1875.60, -11.70, 0.92, 13426.60],
        ["Магнит ао", 2, 5486.00, -352.38, -3.21, 0.70, 10193.00],
        ["Россети ао", 45000, 1.70, -19327.50, -25.25, 3.92, 5704.00],
        ["ВТБ ао", 50000, 0.05, 240.78, 15.24, 0.16, 2312.50],
      ];
      portfolioAssets = assetData.map((e) => PortfolioAsset(e[0], e[1], e[2], e[3], e[4], e[5], e[6])).toList();
    }
    return portfolioAssets!;
  }

  void sortPortfolio(int index, bool ascending, Map<String, bool> colFilter) {
    portfolioAssets!.sort((asset1, asset2) {
      return ascending
          ? asset1.getParam(index, filter: colFilter).compareTo(asset2.getParam(index, filter: colFilter))
          : asset2.getParam(index, filter: colFilter).compareTo(asset1.getParam(index, filter: colFilter));
    });
    notifyListeners();
  }
}
