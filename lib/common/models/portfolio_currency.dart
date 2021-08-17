class PortfolioCurrency {
  final String code;
  final String name;
  final num value;
  final String locale;
  final String symbol;
  num? totalRub;

  PortfolioCurrency({
    required this.code,
    required this.name,
    required this.value,
    required this.locale,
    required this.symbol,
    this.totalRub,
  });

  // Named constructor
  PortfolioCurrency.fromJson(Map<String, dynamic> json)
      : code = json['code'],
        name = json['name'],
        value = json['value'],
        locale = json['locale'],
        symbol = json['symbol'];

  static List<PortfolioCurrency> fromJsonsList(List<Map<String, dynamic>> currencies) {
    return currencies.map((p) => PortfolioCurrency.fromJson(p)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'value': value,
      'locale': locale,
      'symbol': symbol,
    };
  }
}
