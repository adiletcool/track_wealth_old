class Asset {
  final int id;
  final String secid;
  final String shortname;
  final String regnumber;
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
  final String primaryBoardid;
  final String marketpriceBoardid;

  Asset({
    this.id, // 2700
    this.secid, // "AFLT"
    this.shortname, // "Аэрофлот"
    this.regnumber, // "1-01-00010-A"
    this.name, // "Аэрофлот-росс.авиалин(ПАО)ао"
    this.isin, // "RU0009062285"
    this.isTraded, // 1
    this.emitentId, // 1300
    this.emitentTitle, // "публичное акционерное общество \"Аэрофлот – российские авиалинии\""
    this.emitentInn, // "7712040126"
    this.emitentOkpo, // "29063984"
    this.gosreg, // "1-01-00010-A"
    this.type, // "common_share"
    this.group, // "stock_shares"
    this.primaryBoardid, // "TQBR"
    this.marketpriceBoardid, // "TQBR"
  });

  factory Asset.fromList(List<dynamic> list) {
    return Asset(
      id: list[0],
      secid: list[1],
      shortname: list[2],
      regnumber: list[3],
      name: list[4],
      isin: list[5],
      isTraded: list[6],
      emitentId: list[7],
      emitentTitle: list[8],
      emitentInn: list[9],
      emitentOkpo: list[10],
      gosreg: list[11],
      type: list[12],
      group: list[13],
      primaryBoardid: list[14],
      marketpriceBoardid: list[15],
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
