class PortfolioAsset {
  final String boardId; // TQBR (см search_asset_model)
  final String secId; // тикер (AFLT)
  final String shortName; // название компании (Аэрофлот)
  final int quantity; // Количество штук (размер лота * количество лотов)
  final num meanPrice; // Средняя цена покупки
  num? currentPrice; // текущая цена за акцию
  num? todayPriceChange; // изменение цены за сегодня в %
  num? profit; // Доход (Руб) с момента покупки
  num? profitPercent; // Доход (%) с момента покупки
  num? sharePercent; // Доля в портфеле
  num? worth; // Текущая рыночная стоимость

  PortfolioAsset({
    required this.boardId,
    required this.secId,
    required this.shortName,
    required this.quantity,
    required this.meanPrice,
    this.currentPrice,
    this.todayPriceChange,
    this.profit,
    this.profitPercent,
    this.sharePercent,
    this.worth,
  });

  factory PortfolioAsset.fromJson(Map<String, dynamic> json) {
    return PortfolioAsset(
      boardId: json['boardId'],
      secId: json['secId'],
      shortName: json['shortName'],
      quantity: json['quantity'],
      meanPrice: json['meanPrice'],
    );
  }

  static List<PortfolioAsset> fromList(List<Map<String, dynamic>> portfolioAssets) {
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
      if (filter['Прибыль, ₽']!) profit,
      if (filter['Прибыль, %']!) profitPercent,
      if (filter['Доля, %']!) sharePercent,
      worth,
    ];
  }

  @override
  String toString() {
    return "PortfolioAsset($boardId, $secId, $shortName, $quantity, $meanPrice,"
        "$currentPrice, $todayPriceChange, $profit, $profitPercent,"
        "$sharePercent, $worth)";
  }

  Map<String, dynamic> toJson() {
    return {
      'boardId': boardId,
      'secId': secId,
      'shortName': shortName,
      'quantity': quantity,
      'meanPrice': meanPrice,
    };
  }
}

class ColumnFilter {
  late Map<String, bool> filter;
  final bool isMobile;

  ColumnFilter({required this.isMobile})
      : filter = {
          'Тикер': false,
          'Количество': !isMobile,
          'Ср. Цена, ₽': !isMobile,
          'Тек. Цена, ₽': !isMobile,
          'Изм. сегодня, %': false,
          'Прибыль, ₽': isMobile,
          'Прибыль, %': !isMobile,
          'Доля, %': !isMobile
        };

  static List<Map<String, dynamic>> getAllColumns() {
    return [
      {'title': 'Актив', 'type': String},
      {'title': 'Тикер', 'type': String},
      {'title': 'Количество', 'type': num},
      {'title': 'Ср. Цена, ₽', 'type': num},
      {'title': 'Тек. Цена, ₽', 'type': num},
      {'title': 'Изм. сегодня, %', 'type': num},
      {'title': 'Прибыль, ₽', 'type': num},
      {'title': 'Прибыль, %', 'type': num},
      {'title': 'Доля, %', 'type': num},
      {'title': 'Стоимость, ₽', 'type': num},
    ];
  }
}
