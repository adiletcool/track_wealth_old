import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_wealth/common/models/column_filter.dart';
import 'package:track_wealth/common/models/portfolio.dart';
import 'package:track_wealth/common/models/portfolio_currency.dart';
import 'package:track_wealth/common/static/portfolio_helpers.dart';

import '../models/portfolio_asset.dart';

class PortfolioState extends ChangeNotifier {
  late List<Portfolio> portfolios;
  late Portfolio selectedPortfolio;
  DocumentReference? userData;

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
      addUserPortfolio(name: 'Основной портфель', currency: 'RUB', stocks: sampleUserAssets);
      return portfolios.firstWhere((portfolio) => portfolio.isSelected); // выбранный портфель (для него запрашиваем акции по имени)
      */

      return null;
    } else {
      Map<String, List<dynamic>> portfolioData = Map<String, List<dynamic>>.from(data.data() as Map<String, dynamic>);

      portfolios = Portfolio.fromList(List<Map<String, dynamic>>.from(portfolioData['portfolios']!)); // список портфелей (без акций)

      // т.к. при удалении последнего портфеля сохраняется док с portfolios = []
      if (portfolios.length != 0)
        return portfolios.firstWhere((portfolio) => portfolio.isSelected); // выбранный портфель (для него запрашиваем акции по имени)
      else
        return null;
    }
  }

  /// Добавление полей assets и currencies у selectedPortfolio
  Future<void> loadSelectedPortfolio() async {
    DocumentReference<Map<String, dynamic>> portfolioDoc = userData!.collection('assets').doc(selectedPortfolio.name);
    print(selectedPortfolio.name);
    Map<String, dynamic> data = (await portfolioDoc.get()).data() as Map<String, dynamic>;

    List<Map<String, dynamic>> assets = List<Map<String, dynamic>>.from(data['stocks']);
    List<Map<String, dynamic>> currencies = List<Map<String, dynamic>>.from(data['currencies']);

    selectedPortfolio.assets = PortfolioAsset.fromJsonsList(assets);
    selectedPortfolio.currencies = PortfolioCurrency.fromJsonsList(currencies);

    // дожидаемся параллельно выполняющися загрузок данных по акциям и валютам
    await Future.wait([
      selectedPortfolio.loadAssetsData(),
      selectedPortfolio.loadCurrenciesData(),
    ]);
  }

  /// Adding user portfolio document and new subcollection with assets = [], currencies = newUserCurrencies, portfolioName = name
  Future<void> addUserPortfolio({required String name, String? broker, required String currency, String? desc}) async {
    portfolios.forEach((portfolio) => portfolio.isSelected = false);

    // добавляем портфель в список
    portfolios.add(Portfolio(name: name, description: desc, currency: currency, broker: broker, isSelected: true, openDate: Timestamp.now()));

    // форматируем список с портфелями в Json
    List<Map<String, dynamic>> updatedPortfolios = portfolios.map((portfolio) => portfolio.toJson()).toList();

    userData!.set({'portfolios': updatedPortfolios}); // переписываем весь док, поскольку поменять поле у элемента списка нельзя

    // добавляем коллекцию с пустым списком акций по нему
    userData!.collection('assets').doc(name).set({'stocks': [], 'currencies': newUserCurrencies});

    // добавляем коллекцию с пустым списком сделок
    // userData!.collection('tradeHistory').doc(name)
  }

  // TODO
  Future<void> addOperation() async {
    // апдейтить список с акциями выбранного портфеля _updatePortfolioAssets
    // апдейтить список с трейдами выбранного портфеля
  }

  Future<void> changeSelectedPortfolio(String portfolioName) async {
    if (portfolioName != selectedPortfolio.name) {
      portfolios.firstWhere((portfolio) => portfolio.isSelected == true).isSelected = false; // isSelected = false у выбранного ранее портфеля
      portfolios.firstWhere((portfolio) => portfolio.name == portfolioName).isSelected = true; // isSelected = false у портфеля c указанным именем

      await _updatePortfolios();
      reloadData();
    }
  }

  // Future<void> changeSelectedPortfolioCurrency(String newCurrency) async {
  //   if (newCurrency != selectedPortfolio.currency) {
  //     portfolios.firstWhere((portfolio) => portfolio.isSelected == true).currency = newCurrency;
  //   }
  //   _updatePortfolios();
  // }

  /// updating portfolios to Firestore
  Future<void> _updatePortfolios() async {
    /// апдейтится только коллекция portfolios,  не assets!
    // форматируем список с портфелями в Json
    List<Map<String, dynamic>> updatedPortfolios = portfolios.map((portfolio) => portfolio.toJson()).toList();

    userData!.set({'portfolios': updatedPortfolios}); // переписываем док
  }

  /// Удаляем портфель в документе portfolios, а также в документах (2) коллекций assets и tradeHistory
  Future<void> deletePortfolio(String portfolioName) async {
    // Если удаляемый портфель был выбран, то меняем выбранный портфель на другой, если есть
    if (portfolios.firstWhere((p) => p.name == portfolioName).isSelected && (portfolios.length != 0)) portfolios.first.isSelected = true;

    portfolios.removeWhere((portfolio) => portfolio.name == portfolioName);

    // параллельно обновляем доки коллекций portfolios, assets, tradeHistory
    await Future.wait([
      _updatePortfolios(),
      _deleteDocumentFromCollection('assets', portfolioName),
      _deleteDocumentFromCollection('tradeHistory', portfolioName),
    ]);

    reloadData();
  }

  Future<void> changePortfolioSettings(String portfolioName, {required String? newDesc, required String? newBroker}) async {
    portfolios.firstWhere((p) => p.name == portfolioName).updateSettings(newDesc, newBroker);

    // изменяет поля дока
    await _updatePortfolios();

    reloadData();
  }

  Future<void> _updateDocumentPortfolioName(String collection, String portfolioName, String newName) async {
    print(selectedPortfolio.currencies!.map((currency) => currency.toJson()).toList());

    /// Изменить название документа нельзя, поэтому надо удалить старый документ, создать новый с новым названием
    await userData!.collection(collection).doc(portfolioName).update({'portfolioName': newName});
  }

  // TODO
  Future<void> _updatePortfolioAssets() async {
    // var foundDoc = await
  }

  Future<void> _deleteDocumentFromCollection(String collection, String portfolioName) async {
    await userData!.collection(collection).doc(portfolioName).delete();
  }

  /// Сортировка портфеля по выбранному столбцу
  void sortPortfolio(int index, bool ascending, Map<String, bool> colFilter) {
    selectedPortfolio.assets!.sort((asset1, asset2) {
      return (ascending ? asset1 : asset2).getColumnValue(index, filter: colFilter).compareTo(
            (ascending ? asset2 : asset1).getColumnValue(index, filter: colFilter),
          );
    });
    // ХЗ почему, но работает без notifyListeners()  ^_^
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
