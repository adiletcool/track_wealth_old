import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_wealth/common/models/column_filter.dart';
import 'package:track_wealth/common/models/portfolio.dart';
import 'package:track_wealth/common/models/portfolio_currency.dart';
import 'package:track_wealth/common/models/portfolio_trade.dart';
import 'package:track_wealth/common/static/portfolio_helpers.dart';

import '../models/portfolio_stock.dart';

class PortfolioState extends ChangeNotifier {
  late List<Portfolio> portfolios;
  late Portfolio selectedPortfolio;
  DocumentReference? userData;
  DocumentReference? selectedPortfolioData;

  Future<String>? loadDataState;

  /// LOADING DATA
  Future<String> loadData({
    required bool loadSelected,
    required bool loadAssetsAndCurrencies,
    required bool loadStocksMarketData,
    required bool loadCurrenciesMarketData,
    required bool loadTrades,
  }) async {
    if (loadSelected) {
      var _portfolio = await getSelectedUserPortfolio();
      if (_portfolio != null) {
        selectedPortfolio = _portfolio;
        await loadSelectedPortfolio(
          loadAssetsAndCurrencies: loadAssetsAndCurrencies,
          loadStocksMarketData: loadStocksMarketData,
          loadCurrenciesMarketData: loadCurrenciesMarketData,
          loadTrades: loadTrades,
        );
      }
    } else {
      await loadSelectedPortfolio(
        loadAssetsAndCurrencies: loadAssetsAndCurrencies,
        loadStocksMarketData: loadStocksMarketData,
        loadCurrenciesMarketData: loadCurrenciesMarketData,
        loadTrades: loadTrades,
      );
    }
    return 'OK';
  }

  Future<void> reloadData({
    required bool loadSelected,
    required bool loadAssetsAndCurrencies,
    required bool loadStocksMarketData,
    required bool loadCurrenciesMarketData,
    required bool loadTrades,
  }) async {
    loadDataState = loadData(
      loadSelected: loadSelected,
      loadAssetsAndCurrencies: loadAssetsAndCurrencies,
      loadStocksMarketData: loadStocksMarketData,
      loadCurrenciesMarketData: loadCurrenciesMarketData,
      loadTrades: loadTrades,
    );
    notifyListeners();
  }

  Future<Portfolio?> getSelectedUserPortfolio() async {
    print('LOADGING SELECTED PORTFOLIO');
    FirebaseAuth auth = FirebaseAuth.instance;
    userData = FirebaseFirestore.instance.collection('userData').doc(auth.currentUser!.uid);
    DocumentSnapshot<Object?> data = await userData!.get();

    if (!data.exists) {
      portfolios = [];

      /* // Sample
      addUserPortfolio(name: 'Основной портфель', currency: 'RUB', stocks: sampleUserStocks);
      return portfolios.firstWhere((portfolio) => portfolio.isSelected); // выбранный портфель (для него запрашиваем акции по имени)
      */

      return null;
    } else {
      Map<String, List<dynamic>> portfoliosMap = Map<String, List<dynamic>>.from(data.data() as Map<String, dynamic>);

      portfolios = Portfolio.fromList(List<Map<String, dynamic>>.from(portfoliosMap['portfolios']!)); // список портфелей (без акций)

      // т.к. при удалении последнего портфеля сохраняется док с portfolios = []
      if (portfolios.length != 0)
        return portfolios.firstWhere((portfolio) => portfolio.isSelected); // выбранный портфель (для него запрашиваем акции по имени)
      else
        return null;
    }
  }

  /// Чтение полей stocks и currencies у selectedPortfolio
  Future<void> loadSelectedPortfolio({
    required bool loadAssetsAndCurrencies,
    required bool loadStocksMarketData,
    required bool loadCurrenciesMarketData,
    required bool loadTrades,
  }) async {
    print('LOADING SELECTED PORTFOLIO DATA');

    if (loadAssetsAndCurrencies) {
      print('LOADNIG ASSETS AND CURRENCIES');
      selectedPortfolioData = userData!.collection('portfolioData').doc(selectedPortfolio.name);
      Map<String, dynamic> data = (await selectedPortfolioData!.get()).data() as Map<String, dynamic>;
      List<Map<String, dynamic>> stocks = List<Map<String, dynamic>>.from(data['stocks']);
      List<Map<String, dynamic>> currencies = List<Map<String, dynamic>>.from(data['currencies']);

      selectedPortfolio.stocks = PortfolioStock.fromJsonsList(stocks);
      selectedPortfolio.currencies = PortfolioCurrency.fromJsonsList(currencies);
    }

    if (loadTrades) {
      print('LOADING TRADES');
      selectedPortfolio.trades = await getPortfolioTrades();
    }

    // дожидаемся параллельно выполняющися загрузок данных по акциям и валютам  (цены и курсы валют)
    await Future.wait([
      if (loadStocksMarketData) selectedPortfolio.loadStocksData(),
      if (loadCurrenciesMarketData) selectedPortfolio.loadCurrenciesData(),
    ]);
  }

  Future<List<Trade>> getPortfolioTrades() async {
    var selectedPortfolioTrades = await selectedPortfolioData!.collection('trades').orderBy('date', descending: true).limit(10).get();
    if (selectedPortfolioTrades.docs.length > 0) {
      // TODO: загружать первые 30-40 трейдов, добавить функцию для подгрузки еще трейдов с query where 'date' < selectedPortfolio.trades и limit 30-40
      List<Trade> trades = selectedPortfolioTrades.docs.map<Trade>((t) {
        Map<String, dynamic> trade = t.data();
        switch (t['actionType']) {
          case 'stocks':
            if (t['action'] == 'dividends')
              return DividendsTrade.fromJson(trade);
            else
              return StockTrade.fromJson(trade);
          case 'money':
            return MoneyTrade.fromJson(trade);
          default:
            throw 'Unknown actionType ${t['actionType']}';
        }
      }).toList();
      // TODO эти трейдс потом идут в selectedPortfolio.trades
    }
    return [];
  }

  /// Adding user portfolio document and new subcollection with stocks = [], currencies = newUserCurrencies, portfolioName = name
  Future<void> addUserPortfolio({
    required String name,
    required String? broker,
    required String? desc,
    required bool marginTrading,
  }) async {
    portfolios.forEach((portfolio) => portfolio.isSelected = false);

    // добавляем портфель в список
    portfolios.add(
      Portfolio(
        name: name,
        description: desc,
        broker: broker,
        isSelected: true,
        openDate: Timestamp.now(),
        marginTrading: marginTrading,
      ),
    );

    // форматируем список с портфелями в Json
    List<Map<String, dynamic>> updatedPortfolios = portfolios.map((portfolio) => portfolio.toJson()).toList();

    userData!.set({'portfolios': updatedPortfolios}); // переписываем весь док, поскольку поменять поле у элемента списка нельзя

    // добавляем коллекцию с пустым списком акций, дефолтным списком валют
    userData!.collection('portfolioData').doc(name).set({'stocks': [], 'currencies': availableCurrencies});
  }

  Future<void> changePortfolioSettings() async => await _updatePortfolios(); // изменяет поля дока

  Future<void> changeSelectedPortfolio(String portfolioName) async {
    if (portfolioName != selectedPortfolio.name) {
      portfolios.firstWhere((portfolio) => portfolio.isSelected == true).isSelected = false; // isSelected = false у выбранного ранее портфеля
      portfolios.firstWhere((portfolio) => portfolio.name == portfolioName).isSelected = true; // isSelected = false у портфеля c указанным именем

      await _updatePortfolios();
      reloadData(loadSelected: true, loadAssetsAndCurrencies: true, loadStocksMarketData: true, loadCurrenciesMarketData: true, loadTrades: true);
    }
  }

  /// updating portfolios to Firestore
  Future<void> _updatePortfolios() async {
    /// апдейтится только коллекция portfolios,  не stocks!
    // форматируем список с портфелями в Json
    List<Map<String, dynamic>> updatedPortfolios = portfolios.map((portfolio) => portfolio.toJson()).toList();

    userData!.set({'portfolios': updatedPortfolios}); // переписываем док
  }

  /// Удаляем портфель в документе portfolios, а также документ в portfolioData
  Future<void> deletePortfolio(String portfolioName) async {
    // Если удаляемый портфель был выбран, то меняем выбранный портфель на другой, если есть
    if (portfolios.firstWhere((p) => p.name == portfolioName).isSelected && (portfolios.length != 1))
      portfolios.firstWhere((p) => p.name != portfolioName).isSelected = true;

    portfolios.removeWhere((portfolio) => portfolio.name == portfolioName);

    // параллельно обновляем доки коллекции portfolios и удаляем док в коллекции portfolioData
    await Future.wait([
      _updatePortfolios(),
      _deleteDocumentFromCollection('portfolioData', portfolioName),
    ]);

    reloadData(loadSelected: true, loadTrades: true, loadAssetsAndCurrencies: true, loadStocksMarketData: true, loadCurrenciesMarketData: true);
  }

  Future<void> updatePortfolioData({required bool loadAssetsAndCurrencies, required bool loadStocksMarketData, required bool loadCurrenciesMarketData}) async {
    /// Updates stocks and currencies in portfolio and reloads state
    List<Map<String, dynamic>> newStocks = selectedPortfolio.stocks!.map((a) => a.toJson()).toList();
    List<Map<String, dynamic>> newCurrencies = selectedPortfolio.currencies!.map((c) => c.toJson()).toList();

    await selectedPortfolioData!.update({
      'stocks': newStocks,
      'currencies': newCurrencies,
    });
    // не загужаем трейды, т.к. мы уже добавили трейд в Portfolio
    // reloadData, т.к. если есть новая

    reloadData(
      loadSelected: false,
      loadAssetsAndCurrencies: loadAssetsAndCurrencies,
      loadStocksMarketData: loadStocksMarketData,
      loadCurrenciesMarketData: loadCurrenciesMarketData,
      loadTrades: false,
    );
  }

  Future<void> updateCurrencies({required bool loadAssetsAndCurrencies, required bool loadStocksMarketData, required bool loadCurrenciesMarketData}) async {
    /// updates only currencies without reloading
    List<Map<String, dynamic>> newCurrencies = selectedPortfolio.currencies!.map((c) => c.toJson()).toList();
    await selectedPortfolioData!.update({'currencies': newCurrencies});

    reloadData(
      loadSelected: false,
      loadAssetsAndCurrencies: loadAssetsAndCurrencies,
      loadStocksMarketData: loadStocksMarketData,
      loadCurrenciesMarketData: loadCurrenciesMarketData,
      loadTrades: false,
    );
  }

  Future<void> addTrade(Trade trade) async {
    switch (trade.actionType) {
      case 'stocks':
        if (trade.actionType == 'dividends')
          selectedPortfolioData!.collection('trades').doc(trade.date).set((trade as DividendsTrade).toJson());
        else
          selectedPortfolioData!.collection('trades').doc(trade.date).set((trade as StockTrade).toJson());
        break;
      case 'money':
        selectedPortfolioData!.collection('trades').doc(trade.date).set((trade as MoneyTrade).toJson());
        break;
      default:
        throw 'Unknow actionType ${trade.actionType}';
    }
  }

  Future<void> _deleteDocumentFromCollection(String collection, String portfolioName) async {
    await userData!.collection(collection).doc(portfolioName).delete();
  }

  /// Сортировка портфеля по выбранному столбцу
  void sortPortfolio(int index, bool ascending, Map<String, bool> colFilter) {
    selectedPortfolio.stocks!.sort((stock1, stock2) {
      return (ascending ? stock1 : stock2).getColumnValue(index, filter: colFilter).compareTo(
            (ascending ? stock2 : stock1).getColumnValue(index, filter: colFilter),
          );
    });
    // ХЗ почему, но работает без notifyListeners()  ^_^
  }
}

class TableState extends ChangeNotifier {
  Map<String, bool> columnFilter = ColumnFilter(isPortrait: false).filter;
  Map<String, bool> mobileColumnFilter = ColumnFilter(isPortrait: true).filter;
  Map<String, dynamic> sortedColumn = {'title': null, 'ascending': false};

  // * FILTER
  void updateFilter(String colName, bool newValue, bool isPortrait) {
    (isPortrait ? mobileColumnFilter : columnFilter).update(colName, (value) => newValue);

    if (sortedColumn['title'] != null) {
      // * Случай, если убрали отсортированный столбик
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
  }
}
