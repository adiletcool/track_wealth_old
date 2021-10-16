import 'package:track_wealth/common/models/portfolio_trade.dart';

class PortfolioStock {
  final String boardId; // TQBR (см search_stock_model)
  final String secId; // тикер (AFLT)
  final String shortName; // название компании (Аэрофлот)
  int quantity; // Количество штук (размер лота * количество лотов)
  num meanPrice; // Средняя цена покупки

  num get exposure => meanPrice * quantity;

  num realizedPnl; // реализованная прибыль

  num? currentPrice; // текущая цена за акцию
  num? todayPriceChange; // изменение цены за сегодня в %
  num? _sharePercent; // Доля в портфеле, %

  num? get unrealizedPnl => (currentPrice! - meanPrice) * quantity; // нереализованная прибыль
  num? get unrealizedPnlPercent => (currentPrice! / meanPrice - 1) * 100; // нереализованная прибыль
  num? get worth => currentPrice! * quantity; // Текущая рыночная стоимость
  num? get sharePercent => _sharePercent;

  void setSharePercent(totalWorth) => _sharePercent = worth! * 100 / totalWorth;

  PortfolioStock({
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
  PortfolioStock.fromJson(Map<String, dynamic> json)
      : boardId = json['boardId'],
        secId = json['secId'],
        shortName = json['shortName'],
        quantity = json['quantity'],
        meanPrice = json['meanPrice'],
        realizedPnl = json['realizedPnl'];

  static List<PortfolioStock> fromJsonsList(List<Map<String, dynamic>> portfolioStocks) {
    return portfolioStocks.map((a) => PortfolioStock.fromJson(a)).toList();
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
    return "PortfolioStock($boardId, $secId, $shortName, $quantity, $meanPrice,"
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
      'realizedPnl': realizedPnl,
    };
  }

  PortfolioStock.fromStockTrade(StockTrade trade)
      : boardId = trade.boardId,
        secId = trade.secId,
        shortName = trade.shortName,
        quantity = trade.quantity,
        meanPrice = trade.operationTotal / trade.quantity,
        realizedPnl = 0;

  void addBuy(StockTrade trade) {
    // считаем средневзвешенную цену покупок
    meanPrice = (exposure + trade.operationTotal) / (quantity + trade.quantity);
    quantity += trade.quantity;
  }

  void editBuy(StockTrade prevTrade, StockTrade newTrade) {
    // чтобы пересчитать среднюю позицию, нужно знать, какой была средняя цена и количество перед трейдом, который нужно удалить, а потом добавить новый изм-ый
    num quantityBeforePrevTrade = quantity - prevTrade.quantity;

    num meanPriceBeforePrevTrade = (exposure - prevTrade.operationTotal) / (quantity - prevTrade.quantity);

    num exposureBeforePrevTrade = quantityBeforePrevTrade * meanPriceBeforePrevTrade;

    meanPrice = (exposureBeforePrevTrade + newTrade.operationTotal) / (quantityBeforePrevTrade + newTrade.quantity);
  }

  void addSell(StockTrade trade) {
    num tradeProfit = (trade.price - meanPrice) * trade.quantity - trade.fee;
    realizedPnl += tradeProfit;
    quantity -= trade.quantity;
  }

  void addDividends(num totalRub) {
    this.realizedPnl += totalRub;
  }
}
