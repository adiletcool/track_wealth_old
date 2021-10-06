import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_wealth/common/models/column_filter.dart';
import 'package:track_wealth/common/models/portfolio.dart';
import 'package:track_wealth/common/models/portfolio_currency.dart';
import 'package:track_wealth/common/models/portfolio_trade.dart';
import 'package:track_wealth/common/static/portfolio_helpers.dart';

import '../models/portfolio_asset.dart';

class PortfolioState extends ChangeNotifier {
  late List<Portfolio> portfolios;
  late Portfolio selectedPortfolio;
  DocumentReference? userData;
  DocumentReference? selectedPortfolioData;

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
    loadDataState = loadData(); // TODO await'ить?
    notifyListeners();
  }

  Future<Portfolio?> getSelectedUserPortfolio() async {
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
  Future<void> loadSelectedPortfolio() async {
    selectedPortfolioData = userData!.collection('portfolioData').doc(selectedPortfolio.name);

    // var selectedPortfolioTrades = await selectedPortfolioData!.collection('trades').limit(10).get();

    // List<Trade> trades = selectedPortfolioTrades.docs.map<Trade>((t) {
    //   Map<String, dynamic> trade = t.data();
    //   switch (t['actionType']) {
    //     case 'stocks':
    // if t['action'] == ''

    //       break;
    //     default:
    //   }
    // }).toList();
    // print(selectedPortfolioTrades.docs[0].data());

    Map<String, dynamic> data = (await selectedPortfolioData!.get()).data() as Map<String, dynamic>;

    List<Map<String, dynamic>> stocks = List<Map<String, dynamic>>.from(data['stocks']);
    List<Map<String, dynamic>> currencies = List<Map<String, dynamic>>.from(data['currencies']);

    selectedPortfolio.stocks = PortfolioStock.fromJsonsList(stocks);
    selectedPortfolio.currencies = PortfolioCurrency.fromJsonsList(currencies);

    // дожидаемся параллельно выполняющися загрузок данных по акциям и валютам  (цены и курсы валют)
    await Future.wait([
      selectedPortfolio.loadStocksData(),
      selectedPortfolio.loadCurrenciesData(),
    ]);
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
    userData!.collection('portfolioData').doc(name).set({'stocks': [], 'currencies': newUserCurrencies});

    // userData!.collection('tradeHistory').doc(name).collection('trades').orderBy(field).limit(100).get();
  }

  Future<void> changeSelectedPortfolio(String portfolioName) async {
    if (portfolioName != selectedPortfolio.name) {
      portfolios.firstWhere((portfolio) => portfolio.isSelected == true).isSelected = false; // isSelected = false у выбранного ранее портфеля
      portfolios.firstWhere((portfolio) => portfolio.name == portfolioName).isSelected = true; // isSelected = false у портфеля c указанным именем

      await _updatePortfolios();
      reloadData();
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
    if (portfolios.firstWhere((p) => p.name == portfolioName).isSelected && (portfolios.length != 0)) portfolios.first.isSelected = true;

    portfolios.removeWhere((portfolio) => portfolio.name == portfolioName);

    // параллельно обновляем доки коллекции portfolios и удаляем док в коллекции portfolioData
    await Future.wait([
      _updatePortfolios(),
      _deleteDocumentFromCollection('portfolioData', portfolioName),
    ]);

    reloadData();
  }

  Future<void> changePortfolioSettings() async {
    await _updatePortfolios(); // изменяет поля дока
  }

  Future<void> updatePortfolioData() async {
    /// Updates stocks and currencies in portfolio and reloads state
    List<Map<String, dynamic>> newStocks = selectedPortfolio.stocks!.map((a) => a.toJson()).toList();
    List<Map<String, dynamic>> newCurrencies = selectedPortfolio.currencies!.map((c) => c.toJson()).toList();

    await selectedPortfolioData!.update({
      'stocks': newStocks,
      'currencies': newCurrencies,
    });
    reloadData();
  }

  Future<void> updateCurrencies() async {
    /// updates only currencies without reloading
    List<Map<String, dynamic>> newCurrencies = selectedPortfolio.currencies!.map((c) => c.toJson()).toList();
    await selectedPortfolioData!.update({'currencies': newCurrencies});
  }

  Future<void> addTrade(Trade trade) async {
    switch (trade.actionType) {
      case 'stocks':
        if (trade.actionType == 'dividends')
          selectedPortfolioData!.collection('trades').doc(trade.date).set((trade as DividendsTrade).toJson());
        else
          selectedPortfolioData!.collection('trades').doc(trade.date).set((trade as AssetTrade).toJson());
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
    selectedPortfolio.stocks!.sort((asset1, asset2) {
      return (ascending ? asset1 : asset2).getColumnValue(index, filter: colFilter).compareTo(
            (ascending ? asset2 : asset1).getColumnValue(index, filter: colFilter),
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
