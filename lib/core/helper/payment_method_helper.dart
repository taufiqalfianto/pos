class PaymentMethodHelper {
  static const cash = 'cash';
  static const qris = 'qris';

  static const methods = [cash, qris];

  static String label(String method) {
    switch (method.toLowerCase()) {
      case qris:
        return 'QRIS';
      case cash:
        return 'Cash';
      default:
        return method.isEmpty ? '-' : method;
    }
  }
}
