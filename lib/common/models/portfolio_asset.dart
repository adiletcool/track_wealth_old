import 'package:track_wealth/common/models/portfolio.dart';

class PortfolioAsset {
  final String boardId; // TQBR (см search_asset_model)
  final String secId; // тикер (AFLT)
  final String shortName; // название компании (Аэрофлот)
  int quantity; // Количество штук (размер лота * количество лотов)
  num meanPrice; // Средняя цена покупки
  num realizedPnl; // реализованная прибыль

  num? currentPrice; // текущая цена за акцию
  num? todayPriceChange; // изменение цены за сегодня в %
  num? _sharePercent; // Доля в портфеле, %

  num? get unrealizedPnl => (currentPrice! - meanPrice) * quantity; // нереализованная прибыль
  num? get unrealizedPnlPercent => (currentPrice! / meanPrice - 1) * 100; // нереализованная прибыль
  num? get worth => currentPrice! * quantity; // Текущая рыночная стоимость
  num? get sharePercent => _sharePercent;

  void setSharePercent(totalWorth) => _sharePercent = worth! * 100 / totalWorth;

  PortfolioAsset({
    required this.boardId,
    required this.secId,
    required this.shortName,
    required this.quantity,
    required this.meanPrice,
    required this.realizedPnl,
    this.currentPrice,
    this.todayPriceChange,
  });

  // Named constructor
  PortfolioAsset.fromJson(Map<String, dynamic> json)
      : boardId = json['boardId'],
        secId = json['secId'],
        shortName = json['shortName'],
        quantity = json['quantity'],
        meanPrice = json['meanPrice'],
        realizedPnl = json['realizedPnl'];

  static List<PortfolioAsset> fromJsonsList(List<Map<String, dynamic>> portfolioAssets) {
    return portfolioAssets.map((a) => PortfolioAsset.fromJson(a)).toList();
  }

  dynamic getColumnValue(int index, {required Map<String, bool> filter}) {
    return getColumnValues(filter: filter)[index];
  }

  List<dynamic> getColumnValues({required Map<String, bool> filter}) {
    return [
      shortName,
      if (filter['Тикер']!) secId,
      if (filter['Количество']!) quantity,
      if (filter['Ср. Цена, ₽']!) meanPrice,
      if (filter['Тек. Цена, ₽']!) currentPrice,
      if (filter['Изм. сегодня, %']!) todayPriceChange,
      if (filter['Прибыль, ₽']!) unrealizedPnl,
      if (filter['Прибыль, %']!) unrealizedPnlPercent,
      if (filter['Доля, %']!) sharePercent,
      worth,
    ];
  }

  @override
  String toString() {
    return "PortfolioAsset($boardId, $secId, $shortName, $quantity, $meanPrice,"
        "$currentPrice, $todayPriceChange, $unrealizedPnl, $unrealizedPnlPercent,"
        "$sharePercent, $worth)";
  }

  Map<String, dynamic> toJson() {
    return {
      'boardId': boardId,
      'secId': secId,
      'shortName': shortName,
      'quantity': quantity,
      'meanPrice': meanPrice,
      'tradesProfit': realizedPnl,
    };
  }

  void addTrade(OperationType type, num oPrice, int oQuantity, num oFee) {
    switch (type) {
      case OperationType.sell:
        num oTradeProfit = (oPrice - meanPrice) * oQuantity;
        this.realizedPnl += oTradeProfit;
        break;
      case OperationType.buy:
        // считаем средневзвешенную цену покупок
        this.meanPrice = (meanPrice * quantity + oPrice * oQuantity - oFee) / (quantity + oQuantity);
        this.quantity = quantity + oQuantity;
        break;
      default:
        break;
    }
  }

  void addDividend(num totalRub) {
    this.realizedPnl += totalRub;
  }
}
