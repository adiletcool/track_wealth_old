class PortfolioAsset {
  final String boardId; // TQBR (см search_asset_model)
  final String secId; // тикер (AFLT)
  final String shortName; // название компании (Аэрофлот)
  final int quantity; // Количество штук (размер лота * количество лотов)
  final num meanPrice; // Средняя цена покупки
  final num currentPrice; // текущая цена за акцию
  final num todayPriceChange; // изменение цены за сегодня в %
  final num profit; // Доход (Руб) с момента покупки
  final num profitPercent; // Доход (%) с момента покупки
  final num sharePercent; // Доля в портфеле
  final num worth; // Текущая рыночная стоимость

  PortfolioAsset({
    required this.boardId,
    required this.secId,
    required this.shortName,
    required this.quantity,
    required this.meanPrice,
    required this.currentPrice,
    required this.todayPriceChange,
    required this.profit,
    required this.profitPercent,
    required this.sharePercent,
    required this.worth,
  });

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
    return "PortfolioAsset($shortName, $quantity, $meanPrice, $profit, $profitPercent, $sharePercent, $worth)";
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
