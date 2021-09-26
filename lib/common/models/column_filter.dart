class ColumnFilter {
  late Map<String, bool> filter;
  final bool isPortrait;

  ColumnFilter({required this.isPortrait})
      : filter = {
          'Тикер': false,
          'Количество': !isPortrait,
          'Ср. Цена, ₽': !isPortrait,
          'Тек. Цена, ₽': !isPortrait,
          'Изм. сегодня, %': false,
          'Прибыль, ₽': isPortrait,
          'Прибыль, %': !isPortrait,
          'Доля, %': !isPortrait
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
