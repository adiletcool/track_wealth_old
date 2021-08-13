import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_wealth/common/constants.dart';
import 'package:track_wealth/common/models/column_filter.dart';
import 'package:track_wealth/common/models/portfolio.dart';
import 'package:track_wealth/common/models/portfolio_currency.dart';

import '../models/portfolio_asset.dart';

class DashboardState extends ChangeNotifier {
  late List<Portfolio> portfolios;
  late Portfolio selectedPortfolio;
  DocumentReference? userAssets;

  Future<String>? loadDataState;

  /// LOADING DATA
  Future<String> loadData() async {
    print('LOADING DATA');
    await getSelectedUserPortfolio().then((value) async {
      if (value != null) {
        selectedPortfolio = value;
        await loadSelectedPortfolio();
      }
    });

    return 'OK';
  }

  Future<void> reloadData() async {
    loadDataState = loadData();
    notifyListeners();
  }

  Future<Portfolio?> getSelectedUserPortfolio() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    userAssets = FirebaseFirestore.instance.collection('portfolios').doc(auth.currentUser!.uid);
    DocumentSnapshot<Object?> data = await userAssets!.get();

    if (!data.exists) {
      portfolios = [];

      /* // Sample
      addUserPortfolio(name: 'Основной портфель', currency: 'RUB', stocks: sampleUserAssets);
      return portfolios.firstWhere((portfolio) => portfolio.isSelected); // выбранный портфель (для него запрашиваем акции по имени)
      */

      return null;
    } else {
      Map<String, List<dynamic>> portfolioData = Map<String, List<dynamic>>.from(data.data() as Map<String, dynamic>);

      portfolios = Portfolio.fromList(List<Map<String, dynamic>>.from(portfolioData['portfolios']!)); // список портфелей (без акций)
      return portfolios.firstWhere((portfolio) => portfolio.isSelected); // выбранный портфель (для него запрашиваем акции по имени)
    }
  }

  /// Добавление полей assets и currencies у selectedPortfolio
  Future<void> loadSelectedPortfolio() async {
    QuerySnapshot assetsQuery = await userAssets!.collection('assets').where('portfolioName', isEqualTo: selectedPortfolio.name).limit(1).get();

    Map<String, dynamic> assetsCurrencies = assetsQuery.docs.first.data() as Map<String, dynamic>;

    List<Map<String, dynamic>> assets = List<Map<String, dynamic>>.from(assetsCurrencies['stocks']);
    List<Map<String, dynamic>> currencies = List<Map<String, dynamic>>.from(assetsCurrencies['currencies']);

    selectedPortfolio.assets = PortfolioAsset.fromJsonsList(assets);
    selectedPortfolio.curercies = PortfolioCurrency.fromJsonsList(currencies);

    // дожидаемся параллельно выполняющися загрузок данных по акциям и валютам
    await Future.wait([
      loadSelectedPortfolioAssets(),
      loadSelectedPortfolioCurrencies(),
    ]);
  }

  /// Получаем рыночные данные по акциям выбранного портфеля
  Future<void> loadSelectedPortfolioAssets() async {
    // Делим рос и зарубежные акции, делаем отдельные запросы, потом снова соединяем
    Iterable<PortfolioAsset> russianAssets = selectedPortfolio.assets!.where((asset) => asset.boardId == 'TQBR');
    Iterable<PortfolioAsset> foreignAssets = selectedPortfolio.assets!.where((asset) => asset.boardId == 'FQBR');

    russianAssets = await getAssetsMarketData(assets: russianAssets);
    foreignAssets = await getAssetsMarketData(assets: foreignAssets, isForeign: true);

    selectedPortfolio.assets = russianAssets.toList() + foreignAssets.toList();

    selectedPortfolio.assets!.sort((a1, a2) => a2.worth!.compareTo(a1.worth!)); // сортируем по рыночной стоимости
    selectedPortfolio.assets = selectedPortfolio.assets!.where((asset) => asset.quantity != 0).toList(); // фильтруем qunatity != 0
  }

  /// Получаем рыночные данные по валютам выбранного портфеля
  Future<void> loadSelectedPortfolioCurrencies() async {
    selectedPortfolio.curercies = (await getCurrenciesMarketData(selectedPortfolio.curercies!)).toList();
    selectedPortfolio.curercies = selectedPortfolio.curercies!.where((c) => c.value != 0).toList(); // фильтруем value != 0
  }

  /// Aadd currentPrice, todayPriceChange, profit, profitPercent, worth, sharePercent to selectedPortfolio.assets
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

  /// Convert all currencies to rubles by adding key value 'totalRub'
  Future<Iterable<PortfolioCurrency>> getCurrenciesMarketData(Iterable<PortfolioCurrency> currencies) async {
    Iterable<String> foreignCodes = currencies.where((c) => c.code != 'RUB').map((c) => c.code); // рубли не смотрим

    if (foreignCodes.length > 0) {
      Iterable<String> codes = currencies.map((c) => c.code);
      String securities = codes.reduce((a, b) => '$a,$b');

      String url = 'https://iss.moex.com/iss/engines/currency/markets/selt/boards/CETS/securities.json';
      List<Map<String, dynamic>> marketDataMaps = await getMoexMarketData(url, securities, isCurrencies: true);

      currencies.forEach((c) {
        if (c.code != 'RUB') {
          Map<String, dynamic>? foundCurrency = marketDataMaps.firstWhere(
            (found) => found['SECID'] == c.code,
            orElse: () => {'LAST': 0},
          );
          num lastPrice = foundCurrency['LAST'] ?? foundCurrency['MARKETPRICE'];
          c.totalRub = c.value * lastPrice;
        } else {
          c.totalRub = c.value;
        }
      });
    }
    return currencies;
  }

  /// Loading assets and currencies market data from moex
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

  /// Adding user portfolio document and new subcollection with assets = [], currencies = newUserCurrencies, portfolioName = name
  Future<void> addUserPortfolio({required String name, String? broker, required String currency, String? desc, List<Map<String, dynamic>>? stocks}) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    DocumentReference userAssets = FirebaseFirestore.instance.collection('portfolios').doc(auth.currentUser!.uid);

    portfolios.forEach((portfolio) => portfolio.isSelected = false);

    // добавляем портфель в список
    portfolios.add(Portfolio(name: name, description: desc, currency: currency, broker: broker, isSelected: true, openDate: Timestamp.now()));

    // форматируем список с портфелями в Json
    List<Map<String, dynamic>> updatedPortfolios = portfolios.map((portfolio) => portfolio.toJson()).toList();

    userAssets.set({'portfolios': updatedPortfolios}); // переписываем весь док, поскольку поменять поле у элемента списка нельзя

    // добавляем коллекцию с пустым списком акций по нему
    userAssets.collection('assets').add({'portfolioName': name, 'stocks': stocks ?? [], 'currencies': newUserCurrencies});

    // добавляем коллекцию с пустым списком сделок
    userAssets.collection('tradeHistory').add({'portfolioName': name, 'trades': []});
  }

  Future<void> changeSelectedPortfolio(String portfolioName) async {
    if (portfolioName != selectedPortfolio.name) {
      FirebaseAuth auth = FirebaseAuth.instance;
      DocumentReference userAssets = FirebaseFirestore.instance.collection('portfolios').doc(auth.currentUser!.uid);

      portfolios.firstWhere((portfolio) => portfolio.isSelected == true).isSelected = false; // isSelected = false у выбранного портфеля
      portfolios.firstWhere((portfolio) => portfolio.name == portfolioName).isSelected = true; // isSelected = false у портфеля c указанным именем

      // форматируем список с портфелями в Json
      List<Map<String, dynamic>> updatedPortfolios = portfolios.map((portfolio) => portfolio.toJson()).toList();

      userAssets.set({'portfolios': updatedPortfolios}); // переписываем док
      reloadData();
    }
  }

  void sortPortfolio(int index, bool ascending, Map<String, bool> colFilter) {
    selectedPortfolio.assets!.sort((asset1, asset2) {
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
    // notifyListeners();
  }
}
