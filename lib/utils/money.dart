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
      return Money((this.value * other.value) ~/ 100); // Divide by 100 to remove the extra two decimal places
    else
      return Money(this.value * other);
  }

  Money operator /(dynamic other) {
    if (other is Money)
      return Money((this.value * other.value) * 100); // Multiply by 100 to add the removed two decimal places
    else
      return Money((this.value / other).round());
  }

  bool operator <(dynamic other) => (other is Money && this.value < other.value) || this.value / 100 < other;
  bool operator >(dynamic other) => (other is Money && this.value > other.value) || this.value / 100 > other;
  bool operator <=(dynamic other) => (other is Money && this.value <= other.value) || this.value / 100 <= other;
  bool operator >=(dynamic other) => (other is Money && this.value >= other.value) || this.value / 100 >= other;
  bool operator ==(dynamic other) => (other is Money && this.value == other.value) || this.value / 100 == other;

  @override
  int get hashCode => value;

  double toDouble() => this.value / 100;

  static final currencyFormat = NumberFormat("Rp #,##0.00", "en_US");
  String toString() {
    return currencyFormat.format(this.value / 100);
  }
}
