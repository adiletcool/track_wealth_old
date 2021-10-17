import 'package:flutter/material.dart';

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

class TableState extends ChangeNotifier {
  Map<String, bool> columnFilter = ColumnFilter(isPortrait: false).filter;
  Map<String, bool> mobileColumnFilter = ColumnFilter(isPortrait: true).filter;
  Map<String, dynamic> sortedColumn = {'title': null, 'ascending': false};

  // * FILTER
  void updateFilter(String colName, bool newValue, bool isPortrait) {
    (isPortrait ? mobileColumnFilter : columnFilter).update(colName, (value) => newValue);

    if (sortedColumn['title'] != null) {
      // * Случай, если убрали отсортированный столбик
      if ((colName == sortedColumn['title']) && (newValue == false)) {
        sortedColumn.update('title', (value) => null);
      }
    }
    notifyListeners();
  }

  // * SORT
  void updateSortedColumn(String columnName, bool isAscending) {
    sortedColumn.update('title', (value) => columnName);
    sortedColumn.update('ascending', (value) => isAscending);
  }
}
