import 'package:intl/intl.dart' as intl;
import 'package:path/path.dart';

formatMoney(var money, {isBalance = false}) {
  // check if up to six decimal is greater than 0

  double actualMoney;
  if (money is String) {
    actualMoney = double.parse(money);
  } else {
    actualMoney = double.parse(money.toString());
  }

  // actualmoney have eight decimal place significant digit
  if (actualMoney.abs() < 0.00000001) {
    return intl.NumberFormat.decimalPattern().format(0);
  }

  if (isBalance) {
    if (actualMoney.abs() < 1 && actualMoney.abs() != 0) {
      return intl.NumberFormat('0.00000000').format(actualMoney);
    } else {
      return intl.NumberFormat.decimalPattern().format(actualMoney);
    }
  } else {
    return intl.NumberFormat.decimalPattern().format(actualMoney);
  }
}
