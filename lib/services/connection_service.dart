import 'dart:typed_data';

import 'package:pan_scrapper/models/index.dart';

abstract class ConnectionService {
  Future<String> auth(String username, String password);
  Future<List<Product>> getProducts(String credentials);
  Future<List<Transaction>> getDepositaryAccountTransactions(
    String credentials,
    String productId,
  );
  Future<List<CreditCardBillPeriod>> getCreditCardBillPeriods(
    String credentials,
    String productId,
  );
  Future<CreditCardBill> getCreditCardBill(
    String credentials,
    String productId,
    String periodId,
  );
  Future<Uint8List> getCreditCardBillPdf(
    String credentials,
    String productId,
    String periodId,
  );
}
