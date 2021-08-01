import 'package:flutter/material.dart';

class Asset {
  final int id;
  final String secId;
  final String shortName;
  final String regNumber;
  final String name;
  final String isin;
  final int isTraded;
  final int emitentId;
  final String emitentTitle;
  final String emitentInn;
  final String emitentOkpo;
  final String gosreg;
  final String type;
  final String group;
  final String primaryBoardId;
  final String marketPriceBoardId;

  num price;
  int priceDecimals;
  int lotSize;

  Asset({
    @required this.id, // 2700
    @required this.secId, // "AFLT"
    @required this.shortName, // "Аэрофлот"
    @required this.regNumber, // "1-01-00010-A"
    @required this.name, // "Аэрофлот-росс.авиалин(ПАО)ао"
    @required this.isin, // "RU0009062285"
    @required this.isTraded, // 1
    @required this.emitentId, // 1300
    @required this.emitentTitle, // "публичное акционерное общество \"Аэрофлот – российские авиалинии\""
    @required this.emitentInn, // "7712040126"
    @required this.emitentOkpo, // "29063984"
    @required this.gosreg, // "1-01-00010-A"
    @required this.type, // "common_share"
    @required this.group, // "stock_shares"
    @required this.primaryBoardId, // "TQBR"
    @required this.marketPriceBoardId, // "TQBR"
    this.price,
    this.priceDecimals,
    this.lotSize,
  });

  factory Asset.fromList(List<dynamic> list) {
    assert(list.length >= 16);

    return Asset(
      id: list[0] ?? -1,
      secId: list[1] ?? "-1",
      shortName: list[2] ?? "-1",
      regNumber: list[3] ?? "-1",
      name: list[4] ?? "-1",
      isin: list[5] ?? "-1",
      isTraded: list[6] ?? -1,
      emitentId: list[7] ?? -1,
      emitentTitle: list[8] ?? "-1",
      emitentInn: list[9] ?? "-1",
      emitentOkpo: list[10] ?? "-1",
      gosreg: list[11] ?? "-1",
      type: list[12] ?? "-1",
      group: list[13] ?? "-1",
      primaryBoardId: list[14] ?? "-1",
      marketPriceBoardId: list[15] ?? "-1",
    );
  }

  static List<Asset> fromListOfLists(List listOfLists) {
    var onlyStocks = listOfLists.where((e) {
      return ["stock_shares", "stock_dr"].contains(e[13]); // только акции или деп расписки
    }).toList();
    print(onlyStocks.runtimeType);
    return onlyStocks.map((item) => Asset.fromList(item)).toList();
  }

  @override
  String toString() => "Asset($name, $emitentTitle)";
}
