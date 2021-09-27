import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:dio/dio.dart';
import 'package:track_wealth/common/models/portfolio_asset.dart';
import 'package:track_wealth/common/models/portfolio_currency.dart';
import 'package:collection/collection.dart';
import 'package:track_wealth/common/models/search_asset_model.dart';

enum ResultType {
  ok,
  notEnoughAssets,
  notEnoughRubles,
}

class AddOperationResult {
  late ResultType type;
  // buy operation data
  num? rublesAvailable;
  num? purchaseAmount;

  // sell operation
  int? assetsAvailable;

  Map<String, dynamic>? get data => getResultData(type);

  AddOperationResult(this.type, {this.assetsAvailable, this.rublesAvailable, this.purchaseAmount});

  Map<String, dynamic>? getResultData(ResultType type) {
    switch (type) {
      case ResultType.ok:
        return {};
      case ResultType.notEnoughAssets:
        return {'assetsAvailable': assetsAvailable};
      case ResultType.notEnoughRubles:
        return {'rublesAvailable': rublesAvailable, 'purchaseAmount': purchaseAmount};
      default:
        return {};
    }
  }
}

class Portfolio {
  final String name;
  String? broker;
  String? description;
  bool isSelected;
  bool marginTrading;

  final Timestamp openDate; // не изм

  List<PortfolioAsset>? assets; // Акции, торгующиеся только на МосБирже
  List<PortfolioCurrency>? currencies;

  num? get assetsTotal => assets?.map((asset) => asset.worth!).sum;
  num? get currenciesTotal => currencies?.map((currency) => currency.totalRub!).sum;
  num? get total => assetsTotal! + currenciesTotal!; // активы + кэш

  Portfolio({
    required this.name,
    required this.broker,
    required this.description,
    required this.isSelected,
    required this.openDate,
    required this.marginTrading,
    this.assets,
    this.currencies,
  });

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

  void updateSettings(String? newDesc, String? newBroker, bool newMarginTrading) {
    description = newDesc;
    broker = newBroker;
    marginTrading = newMarginTrading;
  }

  void setAssetsSharePercent() {
    num totalWorth = assets!.map((asset) => asset.worth!).sum;
    assets!.forEach((asset) => asset.setSharePercent(totalWorth));
  }

  AddOperationResult buyOperation(SearchAsset asset, num price, int quantity, num fee) {
    //* поскольку в поиске можно найти только акции, торгующиеся на мосбирже, то купить их можно только за рубли, поэтому проверяем, хватает ли рублей

    PortfolioAsset? found = assets!.firstWhereOrNull((a) => a.secId == asset.secId); // смотрим, есть ли эти акции в портфеле

    // Проверяем, хватает ли денег для покупки
    // Если хватает, проверяем, есть ли asset в портфеле. Если есть, то меняем количество и среднюю цену.
    // * Если акции когда-то были, но сейчас их нет (0), то устанавливается новая средняя цену

    num purchaseAmount = price * quantity + fee;
    num rubAvailable = currencies!.firstWhere((c) => c.code == 'RUB').value;
    print(currencies); // отнимаем сумму покупки из денег

    if (purchaseAmount > rubAvailable) {
      return AddOperationResult(ResultType.notEnoughRubles, rublesAvailable: rubAvailable, purchaseAmount: purchaseAmount);
    } else {
      if (found != null) {
        found.addBuy(price, quantity, fee); // добавляем акции и пересчитываем meanPrice
      } else {
        PortfolioAsset newAsset = PortfolioAsset(
          boardId: asset.primaryBoardId,
          secId: asset.secId,
          shortName: asset.shortName,
          quantity: quantity,
          meanPrice: price,
          realizedPnl: 0,
        );
        assets!.add(newAsset); // добавляем акции
      }
      // добавить в trades, reload assets
      return AddOperationResult(ResultType.ok);
    }
  }

  AddOperationResult sellOperation(SearchAsset asset, num price, int quantity, num fee) {
    PortfolioAsset? found = assets!.firstWhereOrNull((a) => a.secId == asset.secId); // смотрим, есть ли эти акции в портфеле

    // проверяем, есть ли asset в портфеле. Если есть, то проверяем, хватает ли для продажи (шт)
    // Если хватает, меняем количество и realizedPnl. Добавляем в трейды

    if (found == null) {
      return AddOperationResult(ResultType.notEnoughAssets, assetsAvailable: 0);
    } else {
      if (found.quantity < quantity) {
        return AddOperationResult(ResultType.notEnoughAssets, assetsAvailable: found.quantity);
      } else {
        found.addSell(price, quantity, fee);

        // добавить в trades, reload assets
        return AddOperationResult(ResultType.ok);
      }
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
