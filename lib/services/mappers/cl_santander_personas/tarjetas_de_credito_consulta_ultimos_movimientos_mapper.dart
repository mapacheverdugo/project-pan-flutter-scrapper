import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:pan_scrapper/entities/currency.dart';
import 'package:pan_scrapper/entities/index.dart';
import 'package:pan_scrapper/helpers/date_helpers.dart';
import 'package:pan_scrapper/helpers/string_helpers.dart';
import 'package:pan_scrapper/services/models/cl_santander_personas/index.dart';

class ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosMapper {
  /// Generates a unique transaction ID from transaction data
  static String _generateTransactionId(
    String transactionDate,
    String importe,
    String description,
  ) {
    final combined = '$transactionDate|$importe|$description';
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  static List<Transaction> fromResponseModel(
    ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosResponseModel
    model,
    CurrencyType transactionType,
  ) {
    final matriz = model.data?.matrizMovimientos ?? [];

    if (matriz.isEmpty) {
      return [];
    }

    final currency = transactionType == CurrencyType.national
        ? Currency.clp
        : Currency.usd;
    final transactions = <Transaction>[];

    for (final movimiento in matriz) {
      try {
        // Parse description
        final description =
            nullIfEmpty(movimiento.comercio) ??
            nullIfEmpty(movimiento.descripcion) ??
            '';

        // Parse amount
        final importe = movimiento.importe;
        if (importe == null || importe.isEmpty) {
          continue;
        }

        final amountOptions = AmountParseOptions(
          factor: transactionType == CurrencyType.national ? 100 : 100,
          decimalSeparator: ',',
          thousandSeparator: '.',
        );

        final symbol = movimiento.indicadorDebeHaber == 'D' ? '-' : '+';
        final amount = Amount.tryParse(
          symbol + importe,
          currency,
          options: amountOptions,
        );

        if (amount == null) {
          continue;
        }

        final amountValue = amount.value;

        // Parse date - format might be YYMMDD or YYYYMMDD
        final fecha = movimiento.fecha;
        if (fecha == null || fecha.isEmpty) {
          continue;
        }

        String transactionDate = getIsoDateFromSlashSeparatedDDMMYYYYDate(
          fecha,
        );

        // Get city
        final ciudad = nullIfEmpty(movimiento.ciudad);

        // Generate transaction ID
        final transactionId = _generateTransactionId(
          transactionDate,
          importe,
          description,
        );

        // Convert amount to integer (amounts are stored as integers in cents)
        final amountInt = (amountValue * 100).round();

        transactions.add(
          Transaction(
            id: transactionId,
            type: TransactionType.default_,
            description: description,
            amount: amount,
            billingCurrencyType: transactionType,
            transactionDate: transactionDate,
            transactionTime: null,
            processingDate: null,
            originalAmount: amount,
            city: ciudad,
            country: null,
          ),
        );
      } catch (e) {
        // Skip transactions that fail to parse
        continue;
      }
    }

    return transactions;
  }
}
