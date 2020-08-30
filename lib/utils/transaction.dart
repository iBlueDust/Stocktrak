import 'package:stocktrak/utils/money.dart';

enum TransactionType { Buy, Sell }

class Transaction {
  static const stocksPerLot = 100;

  final DateTime date;
  final String stock;
  final Money pricePerStock;
  final int lots;
  final String notes;
  final TransactionType type;

  Transaction({
    DateTime date,
    this.stock,
    this.pricePerStock,
    this.lots,
    this.notes,
    this.type,
  })  : assert(stock != null),
        assert(pricePerStock != null),
        assert(lots > 0),
        assert(type != null),
        // I can't find a way to declare DateTime.now() as a separate variable while making this.date final
        this.date = date ?? DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  Money get totalPrice => pricePerStock * lots * stocksPerLot;

  Transaction.fromJson(Map json)
      : this(
          date: DateTime.tryParse(json['date']),
          stock: json['stock'],
          pricePerStock: Money(json['pricePerStock']),
          lots: json['lots'],
          notes: json['notes'],
          type: json['type'] == "Sell" ? TransactionType.Sell : TransactionType.Buy,
        );

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'stock': stock,
        'pricePerStock': pricePerStock.value,
        'lots': lots,
        'notes': notes,
        'type': type.toString(),
      };
}
