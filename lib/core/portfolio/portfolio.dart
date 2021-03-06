import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:track_wealth/core/portfolio/portfolio_stock.dart';
import 'package:track_wealth/core/portfolio/portfolio_currency.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';
import 'package:track_wealth/core/portfolio/portfolio_trade.dart';
import 'package:track_wealth/features/dashboard/portfolio/service/portfolio.dart';

import 'portfolio_stock.dart';

enum ResultType {
  ok,
  notEnoughStocks,
  notEnoughCash,
}

class AddOperationResult {
  late ResultType type;
  // buy operation data
  num? cashAvailable;
  num? opeartionTotal;

  // sell operation
  int? stocksAvailable;

  AddOperationResult(this.type, {this.stocksAvailable, this.cashAvailable, this.opeartionTotal});
}

class Portfolio {
  final String name;
  String? broker;
  String? description;
  bool isSelected;
  bool marginTrading;
  List<Trade>? trades; // TODO добавить метод loadMore для подгрузки еще трейдов с query where 'date' < selectedPortfolio.trades и limit 30-40

  final Timestamp openDate; // не изм

  List<PortfolioStock>? stocks; // Акции, торгующиеся только на МосБирже
  List<PortfolioCurrency>? currencies;

  num? get stocksTotal => stocks?.map((stock) => stock.worth!).sum;
  num? get currenciesTotal => currencies?.map((currency) => currency.totalRub!).sum;
  num? get total => stocksTotal! + currenciesTotal!; // активы + кэш

  Portfolio({
    required this.name,
    required this.broker,
    required this.description,
    required this.isSelected,
    required this.openDate,
    required this.marginTrading,
    this.stocks,
    this.currencies,
    this.trades,
  });
  // TODO: добавить поле trades. В service будут загружаться первые n трейдов.
  // * На странице с трейдами добавить кнопку для загрузки большего количества трейдов

  @override
  String toString() => 'Portfolio($name)';

  // named constructor
  Portfolio.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        broker = json['broker'],
        description = json['description'],
        isSelected = json['isSelected'],
        openDate = json['openDate'],
        marginTrading = json['marginTrading'];

  static List<Portfolio> fromList(List<Map<String, dynamic>> portfolios) {
    return portfolios.map((p) => Portfolio.fromJson(p)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'broker': broker,
      'isSelected': isSelected,
      'openDate': openDate,
      'marginTrading': marginTrading,
    };
  }

  Future<void> updateSettings(
    BuildContext context, {
    required String? newDesc,
    required String? newBroker,
    required bool newMarginTrading,
  }) async {
    description = newDesc;
    broker = newBroker;
    marginTrading = newMarginTrading;

    await context.read<PortfolioState>().changePortfolioSettings();
  }

  void _setStocksSharePercent() {
    num totalWorth = stocks!.map((stock) => stock.worth!).sum;
    stocks!.forEach((stock) => stock.setSharePercent(totalWorth));
  }

  /// Получаем рыночные данные по акциям:
  /// currentPrice, todayPriceChange, unrealizedPnl, unrealizedPnlPercent, worth, sharePercent
  Future<void> loadStocksData() async {
    print('LOADING STOCKS MARKET DATA');
    Iterable<PortfolioStock> russianStocks = stocks!.where((stock) => stock.boardId == 'TQBR');
    Iterable<PortfolioStock> foreignStocks = stocks!.where((stock) => stock.boardId == 'FQBR');

    russianStocks = await _getStocksMarketData(stocks: russianStocks);
    foreignStocks = await _getStocksMarketData(stocks: foreignStocks, isForeign: true);

    stocks = russianStocks.toList() + foreignStocks.toList();
    _setStocksSharePercent();

    stocks!.sort((a1, a2) => a2.worth!.compareTo(a1.worth!)); // сортируем по рыночной стоимости
    stocks = stocks!.where((stock) => stock.quantity != 0).toList(); // фильтруем qunatity != 0
  }

  Future<Iterable<PortfolioStock>> _getStocksMarketData({required Iterable<PortfolioStock> stocks, isForeign = false}) async {
    // загружаем цены сразу на все акции
    if (stocks.length > 0) {
      Iterable<String> queries = stocks.map((a) => '${a.boardId}:${a.secId}');
      String securities = queries.reduce((a, b) => '$a,$b');

      String url = "https://iss.moex.com/iss/engines/stock/markets/${isForeign ? 'foreign' : ''}shares/securities.jsonp";
      List<Map<String, dynamic>> marketDataMaps = await _getMoexMarketData(url, securities);

      stocks.forEach((stock) {
        Map<String, dynamic>? foundStock = marketDataMaps.firstWhere(
          (found) => found['SECID'] == stock.secId,
          orElse: () => {'LAST': 0, 'LASTTOPREVPRICE': 0},
        );

        stock.currentPrice = foundStock['LAST'] ?? foundStock['MARKETPRICE'];
        stock.todayPriceChange = foundStock['LASTTOPREVPRICE'];
      });
    }
    return stocks;
  }

  /// Получаем рыночные данные по валютам портфеля
  Future<void> loadCurrenciesData() async {
    print('LOADING CURRENCIES MARKET DATA');
    currencies = (await _getCurrenciesMarketData(currencies: currencies!)).toList(); // получаем курсы валют
  }

  /// Convert all currencies to rubles by adding key value 'totalRub'
  Future<Iterable<PortfolioCurrency>> _getCurrenciesMarketData({required List<PortfolioCurrency> currencies}) async {
    if (currencies.length > 0) {
      Iterable<String> foreignCodes = currencies.where((c) => c.code != 'RUB').map((c) => c.code); // рубли не смотрим

      if (foreignCodes.length > 0) {
        String securities = foreignCodes.reduce((a, b) => '$a,$b');

        String url = 'https://iss.moex.com/iss/engines/currency/markets/selt/boards/CETS/securities.json';
        List<Map<String, dynamic>> marketDataMaps = await _getMoexMarketData(url, securities, isCurrencies: true);

        currencies.forEach((c) {
          Map<String, dynamic>? foundCurrency = marketDataMaps.firstWhere(
            (found) => found['SECID'] == c.code,
            orElse: () => {'LAST': 0},
          );

          c.exchangeRate = foundCurrency['LAST'] ?? foundCurrency['MARKETPRICE'];
        });
      }
    }
    return currencies;
  }

  /// Loading stocks and currencies market data from moex
  Future<List<Map<String, dynamic>>> _getMoexMarketData(String url, String securities, {bool isCurrencies = false}) async {
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

  // ! Trades

  Future<AddOperationResult> buyOperation(BuildContext context, StockTrade trade) async {
    //* поскольку в поиске можно найти только акции, торгующиеся на мосбирже, то купить их можно только за рубли, поэтому проверяем, хватает ли рублей

    PortfolioStock? found = stocks!.firstWhereOrNull((a) => a.secId == trade.secId); // смотрим, есть ли эти акции в портфеле

    // Проверяем, хватает ли денег для покупки
    // Если хватает, проверяем, есть ли stocks в портфеле. Если есть, то меняем количество и среднюю цену.
    // * Если акции когда-то были, но сейчас их нет (0), то устанавливается новая средняя цену

    num rubAvailable = currencies!.firstWhere((c) => c.code == 'RUB').value;

    if (trade.operationTotal > rubAvailable) {
      return AddOperationResult(ResultType.notEnoughCash, cashAvailable: rubAvailable, opeartionTotal: trade.operationTotal);
    } else {
      if (found != null)
        found.addBuy(trade); // добавляем акции, которые уже были в портфеле и пересчитываем meanPrice
      else
        stocks!.add(PortfolioStock.fromStockTrade(trade)); // добавляем новую акцию

      await updateDocsAndAddTrade(
        context,
        trade,
        updatePortfolioData: true,
        loadAssetsAndCurrencies: false,
        loadStocksMarketData: true, // т.к. если новая акция, то нужны ее котировки
        loadCurrenciesMarketData: false,
      );
      currencies!.firstWhere((c) => c.code == 'RUB').addExpense(trade.operationTotal); // снимаем purchaseAmount

      return AddOperationResult(ResultType.ok);
    }
  }

  Future<AddOperationResult> sellOperation(BuildContext context, StockTrade trade) async {
    PortfolioStock? found = stocks!.firstWhereOrNull((a) => a.secId == trade.secId); // смотрим, есть ли эти акции в портфеле

    // проверяем, есть ли stock в портфеле. Если есть, то проверяем, хватает ли для продажи (шт)
    // Если хватает, меняем количество и realizedPnl. Добавляем в трейды

    if (found == null) {
      return AddOperationResult(ResultType.notEnoughStocks, stocksAvailable: 0);
    } else {
      if (found.quantity < trade.quantity) {
        return AddOperationResult(ResultType.notEnoughStocks, stocksAvailable: found.quantity);
      } else {
        found.addSell(trade);
        currencies!.firstWhere((c) => c.code == 'RUB').addRevenue(trade.operationTotal);
        await updateDocsAndAddTrade(
          context,
          trade,
          updatePortfolioData: true,
          loadAssetsAndCurrencies: false,
          loadStocksMarketData: true, // можно и false
          loadCurrenciesMarketData: false,
        );
        return AddOperationResult(ResultType.ok);
      }
    }
  }

  Future<void> revenueOperation(BuildContext context, PortfolioCurrency currency, MoneyTrade trade) async {
    currency.addRevenue(trade.operationTotal);

    await updateDocsAndAddTrade(
      context,
      trade,
      updateCurrencies: true,
      loadAssetsAndCurrencies: false,
      loadStocksMarketData: false,
      loadCurrenciesMarketData: false,
    );
  }

  Future<AddOperationResult> expenseOperation(BuildContext context, PortfolioCurrency currency, MoneyTrade trade) async {
    if (currency.value < trade.operationTotal) return AddOperationResult(ResultType.notEnoughCash);

    currency.addExpense(trade.operationTotal);

    await updateDocsAndAddTrade(
      context,
      trade,
      updateCurrencies: true,
      loadAssetsAndCurrencies: false,
      loadStocksMarketData: false,
      loadCurrenciesMarketData: false,
    );
    return AddOperationResult(ResultType.ok);
  }

  Future<void> updateDocsAndAddTrade(
    BuildContext context,
    Trade trade, {
    bool updatePortfolioData = false,
    bool updateCurrencies = false,
    required bool loadAssetsAndCurrencies,
    required bool loadStocksMarketData,
    required bool loadCurrenciesMarketData,
  }) async {
    trades!.add(trade);

    await Future.wait([
      if (updatePortfolioData)
        context.read<PortfolioState>().updatePortfolioData(
              loadAssetsAndCurrencies: loadAssetsAndCurrencies,
              loadStocksMarketData: loadStocksMarketData,
              loadCurrenciesMarketData: loadCurrenciesMarketData,
            ),
      if (updateCurrencies)
        context.read<PortfolioState>().updateCurrencies(
              loadAssetsAndCurrencies: loadAssetsAndCurrencies,
              loadStocksMarketData: loadStocksMarketData,
              loadCurrenciesMarketData: loadCurrenciesMarketData,
            ),
      context.read<PortfolioState>().addTrade(trade),
    ]);
  }
}
