import 'package:intl/intl.dart';

class Money {
  final int value;

  Money(this.value);
  Money.fromDouble(double value) : this((value * 100).round());

  Money operator +(Money other) {
    return Money(this.value + other.value);
  }

  Money operator -(Money other) {
    return Money(this.value - other.value);
  }

  Money operator *(dynamic other) {
    if (other is Money)
      return Money(((this.value * other.value) / 100).round()); // Divide by 100 to remove the extra two decimal places
    else
      return Money(this.value * other);
  }

  Money operator /(dynamic other) {
    if (other is Money)
      return Money(((this.value / other.value) * 100).round()); // Multiply by 100 to add the removed two decimal places
    else
      return Money((this.value / other).round());
  }

  Money operator -() => Money(-this.value);

  bool operator <(dynamic other) =>
      (other is Money && this.value < other.value) || (!(other is Money) && this.value / 100 < other);
  bool operator >(dynamic other) =>
      (other is Money && this.value > other.value) || (!(other is Money) && this.value / 100 > other);
  bool operator <=(dynamic other) =>
      (other is Money && this.value <= other.value) || (!(other is Money) && this.value / 100 <= other);
  bool operator >=(dynamic other) =>
      (other is Money && this.value >= other.value) || (!(other is Money) && this.value / 100 >= other);
  bool operator ==(dynamic other) =>
      (other is Money && this.value == other.value) || (!(other is Money) && this.value / 100 == other);

  @override
  int get hashCode => value;

  double toDouble() => this.value / 100;

  static final currencyFormat = NumberFormat("Rp#,##0", "id_ID");
  String toString() {
    return currencyFormat.format(this.value / 100);
  }
}
