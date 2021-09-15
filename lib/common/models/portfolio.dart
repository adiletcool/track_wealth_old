import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:dio/dio.dart';
import 'package:track_wealth/common/models/portfolio_asset.dart';
import 'package:track_wealth/common/models/portfolio_currency.dart';
import 'package:collection/collection.dart';
import 'package:track_wealth/common/models/search_asset_model.dart';

enum OperationType {
  sell,
  buy,
}

enum ResultType {
  ok,
  notEnoughAssets,
  notImplemented,
}

class AddOperationResult {
  late ResultType type;
  int? assetsAvailable;
  String? notImplementedError;

  Map<String, dynamic>? get data => getResultData(type);

  AddOperationResult(this.type, {this.assetsAvailable, this.notImplementedError});

  Map<String, dynamic>? getResultData(ResultType type) {
    switch (type) {
      case ResultType.ok:
        return {};
      case ResultType.notEnoughAssets:
        return {'assetsAvailable': assetsAvailable};
      default:
        return {};
    }
  }
}

class Portfolio {
  String name;
  String? broker;
  String currency; // Валюта, в которой считается total worth по assets
  String? description;
  final Timestamp openDate; // не изм
  bool isSelected;
  List<PortfolioAsset>? assets; // Акции, торгующиеся только на МосБирже
  List<PortfolioCurrency>? currencies;

  num? get assetsTotal => assets?.map((asset) => asset.worth!).sum;
  num? get currenciesTotal => currencies?.map((currency) => currency.totalRub!).sum;
  num? get total => assetsTotal! + currenciesTotal!; // активы + кэш

  Portfolio({
    required this.name,
    required this.broker,
    required this.currency,
    required this.description,
    required this.isSelected,
    required this.openDate,
    this.assets,
    this.currencies,
  });

  @override
  String toString() => 'Portfolio($name)';

  // named constructor
  Portfolio.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        broker = json['broker'],
        currency = json['currency'],
        description = json['description'],
        isSelected = json['isSelected'],
        openDate = json['openDate'];

  static List<Portfolio> fromList(List<Map<String, dynamic>> portfolios) {
    return portfolios.map((p) => Portfolio.fromJson(p)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'currency': currency,
      'broker': broker,
      'isSelected': isSelected,
      'openDate': openDate,
    };
  }

  void updateSettings(String? newDesc, String? newBroker) {
    description = newDesc;
    broker = newBroker;
  }

  AddOperationResult addOperation(OperationType type, SearchAsset asset, num price, int quantity, num fee) {
    //* поскольку в поиске можно найти только акции, торгующиеся на мосбирже, то купить их можно только за рубли, поэтому проверяем, хватает ли рублей

    PortfolioAsset? found = assets!.firstWhereOrNull((a) => a.secId == asset.secId); // смотрим, есть ли эти акции в портфеле

    switch (type) {
      case OperationType.buy:
        // проверяем, есть ли asset в портфеле. Если есть, то меняем количество и среднюю цену.
        // Если акции когда-то были, но сейчас их нет (0), то устанавливается новая средняя цену
        // проверка на достаточность денег уже сделана в confirmOperation
        if (found != null) {
          found.addTrade(type, price, quantity, fee);
        } else {
          PortfolioAsset newAsset = PortfolioAsset(
            boardId: asset.primaryBoardId,
            secId: asset.secId,
            shortName: asset.shortName,
            quantity: quantity,
            meanPrice: price,
            realizedPnl: 0,
          );
          assets!.add(newAsset);
        }
        // добавить в trades, обновить assets
        return AddOperationResult(ResultType.ok);

      case OperationType.sell:
        //* проверяем, есть ли эти акции и хватает ли имеющегося количества для продажи
        if (found == null || found.quantity < quantity) {
          return AddOperationResult(ResultType.notEnoughAssets, assetsAvailable: found?.quantity ?? 0);
        } else {
          //TODO если хватает акций, то продать, посчитать и добавить tradesProfit

          // добавить в trades, обновить assets
          return AddOperationResult(ResultType.ok);
        }
      default:
        return AddOperationResult(ResultType.notImplemented, notImplementedError: 'Unknown operation type $type');
    }
  }

  /// Получаем рыночные данные по акциям:
  /// currentPrice, todayPriceChange, unrealizedPnl, unrealizedPnlPercent, worth, sharePercent
  Future<void> loadAssetsData() async {
    Iterable<PortfolioAsset> russianAssets = assets!.where((asset) => asset.boardId == 'TQBR');
    Iterable<PortfolioAsset> foreignAssets = assets!.where((asset) => asset.boardId == 'FQBR');

    russianAssets = await _getAssetsMarketData(assets: russianAssets);
    foreignAssets = await _getAssetsMarketData(assets: foreignAssets, isForeign: true);

    assets = russianAssets.toList() + foreignAssets.toList();
    setAssetsSharePercent();

    assets!.sort((a1, a2) => a2.worth!.compareTo(a1.worth!)); // сортируем по рыночной стоимости
    assets = assets!.where((asset) => asset.quantity != 0).toList(); // фильтруем qunatity != 0
  }

  void setAssetsSharePercent() {
    num totalWorth = assets!.map((asset) => asset.worth!).sum;
    assets!.forEach((asset) => asset.setSharePercent(totalWorth));
  }

  Future<Iterable<PortfolioAsset>> _getAssetsMarketData({required Iterable<PortfolioAsset> assets, isForeign = false}) async {
    if (assets.length > 0) {
      Iterable<String> queries = assets.map((a) => '${a.boardId}:${a.secId}');
      String securities = queries.reduce((a, b) => '$a,$b');

      String url = "https://iss.moex.com/iss/engines/stock/markets/${isForeign ? 'foreign' : ''}shares/securities.jsonp";
      List<Map<String, dynamic>> marketDataMaps = await _getMoexMarketData(url, securities);

      assets.forEach((asset) {
        Map<String, dynamic>? foundAsset = marketDataMaps.firstWhere(
          (found) => found['SECID'] == asset.secId,
          orElse: () => {'LAST': 0, 'LASTTOPREVPRICE': 0},
        );

        asset.currentPrice = foundAsset['LAST'] ?? foundAsset['MARKETPRICE'];
        asset.todayPriceChange = foundAsset['LASTTOPREVPRICE'];
      });
    }
    return assets;
  }

  /// Получаем рыночные данные по валютам портфеля
  Future<void> loadCurrenciesData() async {
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

  /// Loading assets and currencies market data from moex
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
}
