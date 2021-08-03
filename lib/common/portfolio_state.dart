import 'package:flutter/material.dart';

import 'models/portfolio_asset.dart';

class PortfolioState extends ChangeNotifier {
  List<PortfolioAsset>? portfolioAssets;

  Map<String, dynamic> sortedColumn = {'title': null, 'ascending': false};

  Map<String, bool> columnFilter = ColumnFilter(isMobile: false).filter;
  Map<String, bool> mobileColumnFilter = ColumnFilter(isMobile: true).filter;

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
      // ! С сервера мы получаем только тикер, название, цену покупки, количество
      // ! загружаем по каждому тикеру текущую цену, процентное изменение цены
      // ! считаем profit, profitPercent, sharePercent, worth
      // ! Сортируем по worth
      List<Map<String, dynamic>> assetData = [
        {
          "secId": "GMKN",
          "shortName": "ГМКНорНик",
          "quantity": 15,
          "meanPrice": 22160.00,
          "currentPrice": 25300,
          "todayPriceChange": 0.40,
          "profit": 47100, // (22300 - 22160) * 15
          "profitPercent": 14.17, // (25300 - 22160) * 100 / 22160
          "sharePercent": 53.25, // 379500 * 100 / (379500 + 150000 + 183000)
          "worth": 379500, // 25300 * 15
        },
        {
          "secId": "LKOH",
          "shortName": "Лукойл",
          "quantity": 30,
          "meanPrice": 4750,
          "currentPrice": 5000,
          "todayPriceChange": 0.21,
          "profit": 75000,
          "profitPercent": 5.26,
          "sharePercent": 21.05,
          "worth": 150000,
        },
        {
          "secId": "SBER",
          "shortName": "Сбербанк",
          "quantity": 610,
          "meanPrice": 192,
          "currentPrice": 300,
          "todayPriceChange": 1.5,
          "profit": 65880,
          "profitPercent": 56.25,
          "sharePercent": 25.68,
          "worth": 183000,
        },
      ];
      portfolioAssets = assetData
          .map((e) => PortfolioAsset(
                secId: e["secId"],
                shortName: e["shortName"],
                quantity: e["quantity"],
                meanPrice: e["meanPrice"],
                currentPrice: e["currentPrice"],
                todayPriceChange: e["todayPriceChange"],
                profit: e["profit"],
                profitPercent: e["profitPercent"],
                sharePercent: e["sharePercent"],
                worth: e["worth"],
              ))
          .toList();
      portfolioAssets!.sort((a1, a2) => a2.worth.compareTo(a1.worth));
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
