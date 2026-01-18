import 'dart:typed_data';

import 'package:pan_scrapper/entities/index.dart';

abstract class ConnectionService {
  Future<String> auth(String username, String password);
  Future<List<ExtractedProductModel>> getProducts(String credentials);
  Future<List<ExtractedTransaction>> getDepositaryAccountTransactions(
    String credentials,
    String productId,
  );
  Future<List<ExtractedCreditCardBillPeriod>> getCreditCardBillPeriods(
    String credentials,
    String productId,
  );
  Future<List<ExtractedTransaction>> getCreditCardUnbilledTransactions(
    String credentials,
    String productId,
    CurrencyType transactionType,
  );
  Future<ExtractedCreditCardBill> getCreditCardBill(
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
