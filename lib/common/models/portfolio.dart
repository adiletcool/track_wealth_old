import 'package:track_wealth/common/models/portfolio_asset.dart';

class Portfolio {
  final String name;
  final String? broker;
  final String currency;
  final String? description;
  bool isSelected;
  final List<PortfolioAsset> assets;

  Portfolio({
    required this.name,
    required this.broker,
    required this.currency,
    required this.description,
    required this.isSelected,
    required this.assets,
  });

  factory Portfolio.fromJson(Map<String, dynamic> json) {
    return Portfolio(
      name: json['name'],
      broker: json['broker'],
      currency: json['currency'],
      description: json['description'],
      isSelected: json['isSelected'],
      assets: PortfolioAsset.fromList(List<Map<String, dynamic>>.from(json['assets'])),
    );
  }

  static List<Portfolio> fromList(List<Map<String, dynamic>> portfolios) {
    return portfolios.map((p) => Portfolio.fromJson(p)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'currency': currency,
      'broker': broker,
      'isSelected': isSelected,
      'assets': assets.map((a) => a.toJson()).toList(),
    };
  }
}
