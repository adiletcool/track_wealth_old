import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_wealth/common/models/portfolio.dart';

import '../models/portfolio_asset.dart';

class DashboardState extends ChangeNotifier {
  List<Portfolio>? portfolios;
  List<PortfolioAsset>? selectedPortfolioAssets;
  Map<String, Map<String, dynamic>>? currencies;

  Future<String>? loadDataState;

  // LOADING DATA
  Future<String> loadData() async {
    await Future.wait([
      getUserCurrencies(),
      getUserAssets(),
    ]);

    return 'OK';
  }

  Future<void> reloadData() async {
    loadDataState = loadData();
    notifyListeners();
  }

  Future<Map<String, Map<String, dynamic>>> getUserCurrencies() async {
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

  Future<List<PortfolioAsset>> getUserAssets() async {
    print('Load asset data');
    FirebaseAuth auth = FirebaseAuth.instance;
    DocumentReference userAssets = FirebaseFirestore.instance.collection('portfolios').doc(auth.currentUser!.uid);
    DocumentSnapshot<Object?> data = await userAssets.get();

    if (!data.exists) {
      portfolios = [];
      selectedPortfolioAssets = [];
    } else {
      Map<String, List<dynamic>> portfolioData = Map<String, List<dynamic>>.from(data.data() as Map<String, dynamic>);

      portfolios = Portfolio.fromList(List<Map<String, dynamic>>.from(portfolioData['portfolios']!));
      selectedPortfolioAssets = portfolios!.firstWhere((portfolio) => portfolio.isSelected).assets;

      // Делим рос и зарубежные акции, делаем отдельные запросы, потом снова соединяем
      Iterable<PortfolioAsset> russianAssets = selectedPortfolioAssets!.where((asset) => asset.boardId == 'TQBR');
      Iterable<PortfolioAsset> foreignAssets = selectedPortfolioAssets!.where((asset) => asset.boardId == 'FQBR');

      russianAssets = await getAssetsMarketData(assets: russianAssets);
      foreignAssets = await getAssetsMarketData(assets: foreignAssets, isForeign: true);

      selectedPortfolioAssets = russianAssets.toList() + foreignAssets.toList();

      selectedPortfolioAssets!.sort((a1, a2) => a2.worth!.compareTo(a1.worth!)); // сортируем по рыночной стоимости
    }

    return selectedPortfolioAssets!.where((asset) => asset.quantity != 0).toList(); // фильтруем qunatity != 0
  }

  Future<Iterable<PortfolioAsset>> getAssetsMarketData({required Iterable<PortfolioAsset> assets, isForeign = false}) async {
    if (assets.length > 0) {
      Iterable<String> queries = assets.map((a) => '${a.boardId}:${a.secId}');
      String securities = queries.reduce((a, b) => '$a,$b');

      String url = "https://iss.moex.com/iss/engines/stock/markets/${isForeign ? 'foreign' : ''}shares/securities.jsonp";
      List<Map<String, dynamic>> marketDataMaps = await getMoexMarketData(url, securities);

      assets.forEach((asset) {
        Map<String, dynamic>? foundAsset = marketDataMaps.firstWhere(
          (found) => found['SECID'] == asset.secId,
          orElse: () => {'LAST': 0, 'LASTTOPREVPRICE': 0},
        );

        num lastPrice = foundAsset['LAST'] ?? foundAsset['MARKETPRICE'];
        num todayPriceChange = foundAsset['LASTTOPREVPRICE'];

        asset.currentPrice = lastPrice;
        asset.todayPriceChange = todayPriceChange;

        asset.profit = (asset.currentPrice! - asset.meanPrice) * asset.quantity;
        asset.profitPercent = (asset.currentPrice! / asset.meanPrice - 1) * 100;
        asset.worth = asset.currentPrice! * asset.quantity;
      });

      num totalWorth = assets.map((asset) => asset.worth!).sum;
      assets.forEach((asset) {
        asset.sharePercent = asset.worth! * 100 / totalWorth;
      });
    }
    return assets;
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

  Future<void> addUserPortfolio(String name, String? broker, String currency, String? description) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    DocumentReference userAssets = FirebaseFirestore.instance.collection('portfolios').doc(auth.currentUser!.uid);

    portfolios!.forEach((portfolio) => portfolio.isSelected = false);
    portfolios!.add(
      Portfolio(
        name: name,
        description: description,
        currency: currency,
        broker: broker,
        isSelected: true,
        assets: [],
      ),
    );

    List<Map<String, dynamic>> updatedPortfolios = portfolios!.map((portfolio) => portfolio.toJson()).toList();
    print(updatedPortfolios);
    await userAssets.set({'portfolios': updatedPortfolios});
  }

  void sortPortfolio(int index, bool ascending, Map<String, bool> colFilter) {
    selectedPortfolioAssets!.sort((asset1, asset2) {
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
