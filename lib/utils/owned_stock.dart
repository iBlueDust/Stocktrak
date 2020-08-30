import 'package:stocktrak/utils/money.dart';

class OwnedStock {
  int lots;
  Money nettCost;

  OwnedStock({this.lots, this.nettCost});

  OwnedStock.fromJson(Map<String, dynamic> json)
      : this(
          lots: json['lots'],
          nettCost: Money(json['nettCost']),
        );

  Map<String, dynamic> toJson() => {
        'lots': lots,
        'nettCost': nettCost.value,
      };
}
