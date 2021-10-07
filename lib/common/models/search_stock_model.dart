import 'dart:convert';
import 'package:dio/dio.dart';

class SearchStock {
  final int id; // 2700
  final String secId; // "AFLT"  -- тикер
  final String shortName; // "Аэрофлот"
  final String regNumber; // "1-01-00010-A"
  final String name; // "Аэрофлот-росс.авиалин(ПАО)ао"
  final String isin; // "RU0009062285"
  final int isTraded; // 1
  final int emitentId; // 1300
  final String emitentTitle; // "публичное акционерное общество \"Аэрофлот – российские авиалинии\""
  final String emitentInn; // "7712040126"
  final String emitentOkpo; // "29063984"
  final String gosreg; // "1-01-00010-A"
  final String type; // "common_share"
  final String group; // "stock_shares"
  final String primaryBoardId; // "TQBR" (russian) / "FQBR" (Foreign)
  final String marketPriceBoardId; // "TQBR"

  num? price;
  int? priceDecimals;
  int? lotSize;

  SearchStock({
    required this.id,
    required this.secId,
    required this.shortName,
    required this.regNumber,
    required this.name,
    required this.isin,
    required this.isTraded,
    required this.emitentId,
    required this.emitentTitle,
    required this.emitentInn,
    required this.emitentOkpo,
    required this.gosreg,
    required this.type,
    required this.group,
    required this.primaryBoardId,
    required this.marketPriceBoardId,
    this.price,
    this.priceDecimals,
    this.lotSize,
  });

  SearchStock.fromList(List<dynamic> list)
      : assert(list.length >= 16),
        id = list[0] ?? -1,
        secId = list[1] ?? "-1",
        shortName = list[2] ?? "-1",
        regNumber = list[3] ?? "-1",
        name = list[4] ?? "-1",
        isin = list[5] ?? "-1",
        isTraded = list[6] ?? -1,
        emitentId = list[7] ?? -1,
        emitentTitle = list[8] ?? "-1",
        emitentInn = list[9] ?? "-1",
        emitentOkpo = list[10] ?? "-1",
        gosreg = list[11] ?? "-1",
        type = list[12] ?? "-1",
        group = list[13] ?? "-1",
        primaryBoardId = list[14] ?? "-1",
        marketPriceBoardId = list[15] ?? "-1";

  static List<SearchStock> fromListOfLists(List listOfLists) {
    var onlyStocks = listOfLists.where((e) {
      return ["stock_shares", "stock_dr"].contains(e[13]); // только акции или деп расписки
    }).toList();
    return onlyStocks.map((item) => SearchStock.fromList(item)).toList();
  }

  Future<void> getStockData() async {
    // загружаем цену по одной конкретной акции
    String securityName = "${this.primaryBoardId}:${this.secId}";

    String shares = primaryBoardId == "TQBR" ? "shares" : "foreignshares";
    String url = "https://iss.moex.com/iss/engines/stock/markets/$shares/securities.jsonp";
    Map<String, String> params = {
      'iss.meta': 'off',
      'iss.only': 'securities,marketdata',
      'securities': securityName,
      'lang': 'ru', // TODO: localize to en
    };

    var response = await Dio().get(url, queryParameters: params);

    Map<String, dynamic> result = Map<String, dynamic>.from(json.decode(response.data));
    Map<String, dynamic> marketdata = result['marketdata']!;
    Map<String, dynamic> securities = result['securities']!;

    if (marketdata['data']!.length != 0) {
      Map marketdataAsMap = Map.fromIterables(marketdata['columns']!, marketdata['data']!.first);
      Map seceurities = Map.fromIterables(securities['columns']!, securities['data']!.first);
      this.price = marketdataAsMap['LAST'] ?? marketdataAsMap['MARKETPRICE'];
      this.lotSize = seceurities['LOTSIZE'];
      this.priceDecimals = seceurities['DECIMALS'];
    }
  }

  @override
  String toString() => "Stock($name, $emitentTitle)";

  // @override
  // bool operator ==(SearchStock other) {
  //   return false;
  // }
}
