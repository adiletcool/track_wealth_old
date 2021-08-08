import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/portfolio_asset.dart';

class DashboardState extends ChangeNotifier {
  List<PortfolioAsset>? portfolioAssets;
  Future<String>? loadDataState;

  Map<String, Map<String, dynamic>>? currencies;

  // LOADING DATA
  Future<String> loadData() async {
    await Future.wait([
      getPortfolioAssets(),
      getCurrencies(),
    ]);

    return 'OK';
  }

  Future<void> reloadData() async {
    loadDataState = loadData();
    notifyListeners();
  }

  Future<Map<String, Map<String, dynamic>>> getCurrencies() async {
    print('Load currencies data');

    FirebaseAuth auth = FirebaseAuth.instance;
    DocumentReference userCurrencies = FirebaseFirestore.instance.collection('currencies').doc(auth.currentUser!.uid);
    DocumentSnapshot<Object?> data = await userCurrencies.get();

    if (!data.exists)
      currencies = createCurrencyUserData(userCurrencies); // создаем дефолтный мап из валют
    else
      currencies = Map<String, Map<String, dynamic>>.from(data.data() as Map<String, dynamic>);

    currencies = Map.fromEntries(currencies!.entries.where((entry) => entry.value['value'] != 0));

    currencies!.forEach((key, value) {
      if (key == 'RUB') value['totalRub'] = value['value']; // Для рублей totalRub = value
    });

    currencies = await getCurrenciesMarketData(currencies!);

    return currencies!;
  }

  Future<Map<String, Map<String, dynamic>>> getCurrenciesMarketData(Map<String, Map<String, dynamic>> currenciesData) async {
    // convert all currencies to rubles by adding key value 'totalRub'
    Iterable<String> codes = currenciesData.keys.where((code) => code != 'RUB'); // рубли не смотрим

    if (codes.length > 0) {
      String securities = codes.reduce((a, b) => '$a,$b');

      String url = 'https://iss.moex.com/iss/engines/currency/markets/selt/boards/CETS/securities.json';
      List<Map<String, dynamic>> marketDataMaps = await getMoexMarketData(url, securities, isCurrencies: true);

      currenciesData.forEach((key, value) {
        if (key != 'RUB') {
          Map<String, dynamic>? foundCurrency = marketDataMaps.firstWhere(
            (c) => c['SECID'] == key,
            orElse: () => {'LAST': 0},
          );
          num lastPrice = foundCurrency['LAST'] ?? foundCurrency['MARKETPRICE'];
          value['totalRub'] = value['value'] * lastPrice;
        }
      });
    }

    return currenciesData;
  }

  Future<List<PortfolioAsset>> getPortfolioAssets({bool hideSold = false}) async {
    print('Load asset data');
    FirebaseAuth auth = FirebaseAuth.instance;
    DocumentReference userAssets = FirebaseFirestore.instance.collection('assets').doc(auth.currentUser!.uid);
    DocumentSnapshot<Object?> data = await userAssets.get();

    if (!data.exists) {
      portfolioAssets = [];
    } else {
      Map<String, Map<String, dynamic>> assetData = Map<String, Map<String, dynamic>>.from(data.data() as Map<String, dynamic>);
      Map<String, Map<String, dynamic>> russianAssets = Map.fromEntries(assetData.entries.where((entry) => entry.value['boardId'] == 'TQBR'));
      Map<String, Map<String, dynamic>> foreignAssets = Map.fromEntries(assetData.entries.where((entry) => entry.value['boardId'] == 'FQBR'));

      russianAssets = await getAssetsMarketData(assetData: russianAssets);
      foreignAssets = await getAssetsMarketData(assetData: foreignAssets, isForeign: true);

      assetData = {
        ...russianAssets,
        ...foreignAssets,
      };

      portfolioAssets = assetData.entries
          .map((e) => PortfolioAsset(
                boardId: e.value['boardId'],
                secId: e.key,
                shortName: e.value["shortName"],
                quantity: e.value["quantity"],
                meanPrice: e.value["meanPrice"],
                currentPrice: e.value["currentPrice"],
                todayPriceChange: e.value["todayPriceChange"],
                profit: e.value["profit"],
                profitPercent: e.value["profitPercent"],
                sharePercent: e.value["sharePercent"],
                worth: e.value["worth"],
              ))
          .toList();
      portfolioAssets!.sort((a1, a2) => a2.worth.compareTo(a1.worth));
    }

    if (hideSold) return portfolioAssets!.where((element) => element.quantity != 0).toList();
    return portfolioAssets!;
  }

  Future<Map<String, Map<String, dynamic>>> getAssetsMarketData({required Map<String, Map<String, dynamic>> assetData, bool isForeign = false}) async {
    if (assetData.length > 0) {
      Iterable<String> assets = assetData.entries.map<String>((e) => "${e.value['boardId']}:${e.key}"); // ["TQBR:SBER", "TQBR:GAZP", ...]
      String securities = assets.reduce((a, b) => '$a,$b');

      String url = "https://iss.moex.com/iss/engines/stock/markets/${isForeign ? 'foreign' : ''}shares/securities.jsonp";
      List<Map<String, dynamic>> marketDataMaps = await getMoexMarketData(url, securities);

      assetData.forEach((secId, asset) {
        Map<String, dynamic>? foundAsset = marketDataMaps.firstWhere(
          (found) => found['SECID'] == secId,
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

      num totalWorth = assetData.values.map((a) => a['worth'] as num).sum;
      assetData.values.forEach((asset) {
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

  Map<String, Map<String, dynamic>> createCurrencyUserData(DocumentReference userCurrencies) {
    Map<String, Map<String, dynamic>> initialData = {
      'RUB': {'name': 'Рубли', 'value': 0, 'locale': 'ru', 'symbol': '₽'},
      'USD000UTSTOM': {'name': 'Доллары', 'value': 0, 'locale': 'en_US', 'symbol': '\$'},
      'EUR_RUB__TOM': {'name': 'Евро', 'value': 0, 'locale': 'eu', 'symbol': '€'},
    };

    userCurrencies.set(initialData);
    return initialData;
  }

  void updateCurrencyUserData(String code, num newValue) {
    // data = {'name': 'Рубли', 'value': 0, 'locale': 'ru', 'symbol': '₽'}
    FirebaseAuth auth = FirebaseAuth.instance;
    DocumentReference userCurrencies = FirebaseFirestore.instance.collection('currencies').doc(auth.currentUser!.uid);

    userCurrencies.update({'$code.value': newValue});
    reloadData();
  }

  void sortPortfolio(int index, bool ascending, Map<String, bool> colFilter) {
    portfolioAssets!.sort((asset1, asset2) {
      return (ascending ? asset1 : asset2).getColumnValue(index, filter: colFilter).compareTo(
            (ascending ? asset2 : asset1).getColumnValue(index, filter: colFilter),
          );
    });
  }
}

class TableState extends ChangeNotifier {
  Map<String, bool> columnFilter = ColumnFilter(isMobile: false).filter;
  Map<String, bool> mobileColumnFilter = ColumnFilter(isMobile: true).filter;
  Map<String, dynamic> sortedColumn = {'title': null, 'ascending': false};

  // * FILTER
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

  // * SORT
  void updateSortedColumn(String columnName, bool isAscending) {
    sortedColumn.update('title', (value) => columnName);
    sortedColumn.update('ascending', (value) => isAscending);
    notifyListeners();
  }
}
