class PortfolioCurrency {
  final String _code; // 'RUB' 'USD000UTSTOM' 'EUR_RUB__TOM'
  final String _name;
  num _value;

  String get code => _code;
  String get name => _name;
  num get value => _value;

  final String locale;
  final String symbol;
  num? exchangeRate;

  num? get totalRub => code == 'RUB' ? value : value * exchangeRate!;

  PortfolioCurrency({
    required code,
    required name,
    required value,
    required this.locale,
    required this.symbol,
    this.exchangeRate,
  })  : _code = code,
        _name = name,
        _value = value;

  // Named constructor
  PortfolioCurrency.fromJson(Map<String, dynamic> json)
      : _code = json['code'],
        _name = json['name'],
        _value = json['value'],
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

  @override
  String toString() {
    return '\n$code: {exchangeRate: $exchangeRate, value: $value}';
  }

  void addExpense(num amount) {
    _value -= amount;
  }

  void addRevenue(num amount) {
    _value += amount;
  }
}
