import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';

import 'models/portfolio_asset.dart';

class DashboardState extends ChangeNotifier {
  List<PortfolioAsset>? portfolioAssets;
  List<Map<String, dynamic>>? currencies;

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

  Future<List<Map<String, dynamic>>> getCurrencies() async {
    if (currencies == null) {
      // await currencies
      await Future.delayed(const Duration(seconds: 1));
      currencies = [
        {'name': 'Рубли', 'locale': 'ru', 'value': 2300.256, 'symbol': '\₽'},
        {'name': 'Доллары', 'locale': 'en_US', 'value': 354.26, 'symbol': '\$'},
      ];
    }
    return currencies!;
  }

  Future<List<PortfolioAsset>> getPortfolioAssets() async {
    if (portfolioAssets == null) {
      await Future.delayed(const Duration(seconds: 1));
      // await assetData from server...
      List<Map<String, dynamic>> assetData = [
        {"boardId": "TQBR", "secId": "GMKN", "shortName": "ГМКНорНик", "quantity": 15, "meanPrice": 22160.00},
        {"boardId": "TQBR", "secId": "LKOH", "shortName": "Лукойл", "quantity": 30, "meanPrice": 4750},
        {"boardId": "TQBR", "secId": "SBER", "shortName": "Сбербанк", "quantity": 610, "meanPrice": 192},
      ];

      if (assetData.length > 0) {
        assetData = await getAssetsMarketData(assetData);

        portfolioAssets = assetData
            .map((e) => PortfolioAsset(
                  boardId: e['boardId'],
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
      } else {
        portfolioAssets = [];
      }
    }
    return portfolioAssets!;
  }

  Future<List<Map<String, dynamic>>> getAssetsMarketData(List<Map<String, dynamic>> assetData) async {
    Iterable<String> assets = assetData.map((m) => "${m['boardId']}:${m['secId']}"); // ["TQBR:SBER", "TQBR:GAZP", ...]
    String securities = assets.reduce((a, b) => '$a,$b');

    String url = "https://iss.moex.com/iss/engines/stock/markets/shares/securities.jsonp";
    Map<String, String> params = {
      'iss.meta': 'off',
      'iss.only': 'marketdata',
      'securities': securities,
      'lang': 'ru',
    };
    var response = await Dio().get(url, queryParameters: params);

    Map<String, dynamic> result = Map<String, dynamic>.from(json.decode(response.data));
    Map<String, dynamic> marketData = result['marketdata']!;

    List<String> columns = List<String>.from(marketData['columns']);

    // [{SECID: LKOH, BOARDID: TQBR, ...},
    List<Map<String, dynamic>> marketDataMaps = List.generate(
      marketData['data']!.length,
      (i) => Map.fromIterables(columns, marketData['data']![i]),
    );

    assetData.forEach((asset) {
      Map<String, dynamic>? foundAsset = marketDataMaps.firstWhere((a) => a['SECID'] == asset['secId'], orElse: () => {'LAST': 0, 'LASTTOPREVPRICE': 0});
      num lastPrice = foundAsset['LAST'] ?? foundAsset['MARKETPRICE'];
      num todayPriceChange = foundAsset['LASTTOPREVPRICE'];

      asset['currentPrice'] = lastPrice;
      asset['todayPriceChange'] = todayPriceChange;

      asset['profit'] = (asset['currentPrice'] - asset['meanPrice']) * asset['quantity'];
      asset['profitPercent'] = (asset['currentPrice'] / asset['meanPrice'] - 1) * 100;
      asset['worth'] = asset['currentPrice'] * asset['quantity'];
    });

    num totalWorth = assetData.map((a) => a['worth'] as num).sum;
    assetData.forEach((asset) {
      asset['sharePercent'] = asset['worth'] * 100 / totalWorth;
    });

    return assetData;
  }

  void sortPortfolio(int index, bool ascending, Map<String, bool> colFilter) {
    portfolioAssets!.sort((asset1, asset2) {
      return ascending
          ? asset1.getColumnValue(index, filter: colFilter).compareTo(asset2.getColumnValue(index, filter: colFilter))
          : asset2.getColumnValue(index, filter: colFilter).compareTo(asset1.getColumnValue(index, filter: colFilter));
    });
    notifyListeners();
  }
}
