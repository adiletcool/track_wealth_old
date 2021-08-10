import 'package:cloud_firestore/cloud_firestore.dart';

class PortfolioTrade {
  final bool isPurchase;
  final String operation;
  final Timestamp date;
  final String currencyCode;
  final String secId;
  final bool isForeign;
  final num price;
  final int quantity;
  final num fee;
  final String? note;
  final String shortName;

  PortfolioTrade({
    required this.isPurchase,
    required this.operation,
    required this.date,
    required this.currencyCode,
    required this.secId,
    required this.isForeign,
    required this.price,
    required this.quantity,
    required this.fee,
    required this.note,
    required this.shortName,
  });

  factory PortfolioTrade.fromJson(Map<String, dynamic> json) {
    return PortfolioTrade(
      isPurchase: json['isPurchase'],
      operation: json['operation'],
      date: json['date'],
      currencyCode: json['currencyCode'],
      secId: json['secId'],
      isForeign: json['isForeign'],
      price: json['price'],
      quantity: json['quantity'],
      fee: json['fee'],
      note: json['note'],
      shortName: json['shortName'],
    );
  }

  static List<PortfolioTrade> fromJsonsList(List<Map<String, dynamic>> currencies) {
    return currencies.map((p) => PortfolioTrade.fromJson(p)).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'isPurchase': isPurchase,
      'operation': operation,
      'date': date,
      'currencyCode': currencyCode,
      'secId': secId,
      'isForeign': isForeign,
      'price': price,
      'quantity': quantity,
      'fee': fee,
      'note': note,
      'shortName': shortName,
    };
  }
}
