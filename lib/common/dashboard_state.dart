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

  Future<List<Map<String, dynamic>>> getCurrencies({bool forced = false}) async {
    if ((currencies == null) || forced) {
      // await currencies
      await Future.delayed(const Duration(seconds: 1));
      currencies = [
        {'name': 'Рубли', 'code': 'RUB', 'value': 10, 'locale': 'ru', 'symbol': '₽'},
        {'name': 'Доллары', 'code': 'USD000UTSTOM', 'value': 1, 'locale': 'en_US', 'symbol': '\$'},
        {'name': 'Евро', 'code': 'EUR_RUB__TOM', 'value': 0, 'locale': 'eu', 'symbol': '€'},
      ];
      currencies = currencies!.where((c) => c['value'] != 0).toList();

      // Для рублей totalRub = value
      currencies!.forEach((currency) {
        if (currency['code'] == 'RUB') currency['totalRub'] = currency['value'];
      });
      currencies = await getCurrenciesMarketData(currencies!);
    }
    return currencies!;
  }

  Future<List<Map<String, dynamic>>> getCurrenciesMarketData(List<Map<String, dynamic>> currenciesData) async {
    // convert all currencies to rubles by adding key value 'totalRub'
    Iterable<String> codes = currenciesData.where((c) => (c['code'] != 'RUB')).map((c) => c['code']!); // рубли не смотрим

    if (codes.length > 0) {
      String securities = codes.reduce((a, b) => '$a,$b');

      String url = 'https://iss.moex.com/iss/engines/currency/markets/selt/boards/CETS/securities.json';
      List<Map<String, dynamic>> marketDataMaps = await getMoexMarketData(url, securities, isCurrencies: true);

      currenciesData.forEach((currency) {
        // для иностранной валюты находим значения LAST и умножая на ключ 'value' получаем сумму в рублях
        if (currency['code'] != 'RUB') {
          Map<String, dynamic>? foundCurrency = marketDataMaps.firstWhere(
            (found) => found['SECID'] == currency['code'],
            orElse: () => {'LAST': 0},
          );
          num lastPrice = foundCurrency['LAST'] ?? foundCurrency['MARKETPRICE'];
          currency['totalRub'] = currency['value'] * lastPrice;
        } else {
          currency['totalRub'] = currency['value'];
        }
      });
    }

    return currenciesData;
  }

  Future<List<PortfolioAsset>> getPortfolioAssets({bool forced = false, bool hideSold = false}) async {
    if ((portfolioAssets == null) || forced) {
      await Future.delayed(const Duration(seconds: 1));
      // await assetData from server...
      List<Map<String, dynamic>> assetData = [
        {"boardId": "TQBR", "secId": "GMKN", "shortName": "ГМКНорНик", "quantity": 15, "meanPrice": 22160.00},
        {"boardId": "TQBR", "secId": "LKOH", "shortName": "Лукойл", "quantity": 30, "meanPrice": 4751.5},
        {"boardId": "TQBR", "secId": "SBER", "shortName": "Сбербанк", "quantity": 610, "meanPrice": 191.37},
        {"boardId": "TQBR", "secId": "YNDX", "shortName": "Yandex clA", "quantity": 33, "meanPrice": 4177.80},
        {"boardId": "TQBR", "secId": "AGRO", "shortName": "AGRO-гдр", "quantity": 100, "meanPrice": 896.00},
        {"boardId": "TQBR", "secId": "RTKM", "shortName": "Ростел -ао", "quantity": 560, "meanPrice": 81.78},
        {"boardId": "TQBR", "secId": "FIVE", "shortName": "FIVE-гдр", "quantity": 16, "meanPrice": 2420.00},
        {"boardId": "TQBR", "secId": "ALRS", "shortName": "АЛРОСА ао", "quantity": 120, "meanPrice": 69.97},
        {"boardId": "FQBR", "secId": "M-RM", "shortName": "Macy's", "quantity": 38, "meanPrice": 1200.00},
        {"boardId": "TQBR", "secId": "VTBR", "shortName": "ВТБ ао", "quantity": 60000, "meanPrice": 0.046069},
        {"boardId": "TQBR", "secId": "MGNT", "shortName": "Магнит ао", "quantity": 2, "meanPrice": 5486.00},
        {"boardId": "TQBR", "secId": "MTLRP", "shortName": "Мечел ап", "quantity": 30, "meanPrice": 132.38},
        {"boardId": "FQBR", "secId": "OXY-RM", "shortName": "Occidental", "quantity": 4, "meanPrice": 1993.00},
        {"boardId": "TQBR", "secId": "DSKY", "shortName": "ДетскийМир", "quantity": 400, "meanPrice": 143.29},
        {"boardId": "TQBR", "secId": "MVID", "shortName": "М.видео", "quantity": 22, "meanPrice": 728.60},
        {"boardId": "TQBR", "secId": "LNTA", "shortName": "Лента др", "quantity": 70, "meanPrice": 252.10},
        {"boardId": "TQBR", "secId": "TATN", "shortName": "Татнфт 3ао", "quantity": 116, "meanPrice": 540.20},
        {"boardId": "TQBR", "secId": "FIXP", "shortName": "FIXP-гдр", "quantity": 40, "meanPrice": 745.20},
        {"boardId": "TQBR", "secId": "MAIL", "shortName": "MAIL-гдр", "quantity": 32, "meanPrice": 2042.40},
        {"boardId": "TQBR", "secId": "RSTI", "shortName": "Россети ао", "quantity": 45000, "meanPrice": 1.70},
      ];

      if (assetData.length > 0) {
        List<Map<String, dynamic>> russianAssets = assetData.where((a) => a['boardId'] == 'TQBR').toList();
        List<Map<String, dynamic>> foreignAssets = assetData.where((a) => a['boardId'] == 'FQBR').toList();

        russianAssets = await getAssetsMarketData(assetData: russianAssets);
        foreignAssets = await getAssetsMarketData(assetData: foreignAssets, isForeign: true);

        assetData = russianAssets + foreignAssets;

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
    if (hideSold) return portfolioAssets!.where((element) => element.quantity != 0).toList();
    return portfolioAssets!;
  }

  Future<List<Map<String, dynamic>>> getAssetsMarketData({required List<Map<String, dynamic>> assetData, bool isForeign = false}) async {
    if (assetData.length > 0) {
      Iterable<String> assets = assetData.map((m) => "${m['boardId']}:${m['secId']}"); // ["TQBR:SBER", "TQBR:GAZP", ...]
      String securities = assets.reduce((a, b) => '$a,$b');

      String url = "https://iss.moex.com/iss/engines/stock/markets/${isForeign ? 'foreign' : ''}shares/securities.jsonp";
      List<Map<String, dynamic>> marketDataMaps = await getMoexMarketData(url, securities);

      assetData.forEach((asset) {
        Map<String, dynamic>? foundAsset = marketDataMaps.firstWhere(
          (found) => found['SECID'] == asset['secId'],
          orElse: () => {'LAST': 0, 'LASTTOPREVPRICE': 0},
        );
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
    }

    return assetData;
  }

  Future<List<Map<String, dynamic>>> getMoexMarketData(String url, String securities, {bool isCurrencies = false}) async {
    Map<String, dynamic> result;

    Map<String, String> params = {
      'iss.meta': 'off',
      'iss.only': 'marketdata',
      'securities': securities,
      'lang': 'ru',
    };
    var response = await Dio().get(url, queryParameters: params);

    if (isCurrencies)
      result = Map<String, dynamic>.from(response.data);
    else
      result = Map<String, dynamic>.from(json.decode(response.data));
    Map<String, dynamic> marketData = result['marketdata']!;

    List<String> columns = List<String>.from(marketData['columns']);

    // [{SECID: LKOH, BOARDID: TQBR, ...},
    return List.generate(
      marketData['data']!.length,
      (i) => Map.fromIterables(columns, marketData['data']![i]),
    );
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
