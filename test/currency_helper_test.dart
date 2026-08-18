import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/helper/currency_helper.dart';

void main() {
  group('CurrencyHelper.formatIdr', () {
    test('formats whole number without decimal', () {
      expect(CurrencyHelper.formatIdr(15000), 'Rp 15.000');
    });

    test('formats number with decimal correctly', () {
      expect(CurrencyHelper.formatIdr(12345.67), 'Rp 12.346');
    });

    test('formats zero', () {
      expect(CurrencyHelper.formatIdr(0), 'Rp 0');
    });

    test('formats large number', () {
      expect(CurrencyHelper.formatIdr(1000000000), 'Rp 1.000.000.000');
    });
  });
}