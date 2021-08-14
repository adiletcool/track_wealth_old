import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_wealth/common/models/portfolio_asset.dart';
import 'package:track_wealth/common/models/portfolio_currency.dart';

class Portfolio {
  String name;
  String? broker;
  String currency; // Валюта, в которой считается total worth по assets
  String? description;
  final Timestamp openDate; // не изм
  bool isSelected;
  List<PortfolioAsset>? assets; // Акции, торгующиеся только на МосБирже
  List<PortfolioCurrency>? currencies;
  num? assetsTotal;
  num? currenciesTotal;

  Portfolio({
    required this.name,
    required this.broker,
    required this.currency,
    required this.description,
    required this.isSelected,
    required this.openDate,
    // required this.datetime,
    this.assets,
    this.currencies,
    this.assetsTotal,
    this.currenciesTotal,
  });

  factory Portfolio.fromJson(Map<String, dynamic> json) {
    return Portfolio(
      name: json['name'],
      broker: json['broker'],
      currency: json['currency'],
      description: json['description'],
      isSelected: json['isSelected'],
      openDate: json['openDate'],
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
      'openDate': openDate,
    };
  }

  @override
  String toString() => 'Portfolio($name)';
}
