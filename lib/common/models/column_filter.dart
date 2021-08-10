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
