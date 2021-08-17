import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:dio/dio.dart';
import 'package:track_wealth/common/models/portfolio_asset.dart';
import 'package:track_wealth/common/models/portfolio_currency.dart';
import 'package:collection/collection.dart';

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

  void updateSettings(String? newName, String? newDesc, String? newBroker) {
    if (newName != null) name = newName;
    description = newDesc;
    broker = newBroker;
  }

  @override
  String toString() => 'Portfolio($name)';

  void setAssetsSharePercent() {
    num totalWorth = assets!.map((asset) => asset.worth!).sum;
    assets!.forEach((asset) => asset.setSharePercent(totalWorth));
  }

  /// Получаем рыночные данные по акциям:
  /// currentPrice, todayPriceChange, profit, profitPercent, worth, sharePercent
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
    currencies = currencies!.where((c) => c.value != 0).toList(); // фильтруем value != 0
    currencies = (await _getCurrenciesMarketData(currencies: currencies!)).toList();
  }

  /// Convert all currencies to rubles by adding key value 'totalRub'
  Future<Iterable<PortfolioCurrency>> _getCurrenciesMarketData({required List<PortfolioCurrency> currencies}) async {
    if (currencies.length > 0) {
      currencies.forEach((c) {
        if (c.code == 'RUB') c.totalRub = c.value;
      });
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

          num lastPrice = foundCurrency['LAST'] ?? foundCurrency['MARKETPRICE'];
          c.totalRub ??= c.value * lastPrice;
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
