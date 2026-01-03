import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:pan_scrapper/helpers/date_helpers.dart';
import 'package:pan_scrapper/helpers/string_helpers.dart';
import 'package:pan_scrapper/models/index.dart';
import 'package:pan_scrapper/services/models/cl_santander_personas/index.dart';

class ClSantanderPersonasCreditCardUnbilledTransactionMapper {
  /// Generates a unique transaction ID from transaction data
  static String _generateTransactionId(
    String transactionDate,
    String movementNumber,
    String amount,
    String description,
  ) {
    final combined = '$transactionDate|$movementNumber|$amount|$description';
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  /// Get ISO currency code from ISO number
  static String _getIsoLettersCurrencyFromIsoNumber(int isoNumber) {
    // ISO 4217 currency codes
    // 152 = CLP, 840 = USD
    switch (isoNumber) {
      case 152:
        return 'CLP';
      case 840:
        return 'USD';
      default:
        return 'CLP'; // Default to CLP
    }
  }

  /// Get 2-letter country code from 3-letter ISO country code
  static String? _get2LetterCountryFrom3LetterCountry(String iso3Letter) {
    // Common country mappings
    final countryMap = {
      'CHL': 'CL', // Chile
      'USA': 'US', // United States
      'ARG': 'AR', // Argentina
      'PER': 'PE', // Peru
      'COL': 'CO', // Colombia
      'BRA': 'BR', // Brazil
      'MEX': 'MX', // Mexico
      'ESP': 'ES', // Spain
    };
    return countryMap[iso3Letter.toUpperCase()];
  }

  static List<Transaction> fromUnbilledTransactionResponseModel(
    ClSantanderPersonasCreditCardUnbilledTransactionResponseModel model,
  ) {
    final matriz = model.data.conMovimientosPorFacturarResponse.output
        .matrizMovimientosPorFacturar;

    if (matriz.isEmpty) {
      return [];
    }

    final transactions = <Transaction>[];

    for (final tx in matriz) {
      try {
        // Get currency from ISO number
        final codigoMoneda = tx.codigoMoneda;
        if (codigoMoneda == null || codigoMoneda.isEmpty) {
          continue;
        }

        final isoNumber = int.tryParse(codigoMoneda) ?? 152;
        final currency = _getIsoLettersCurrencyFromIsoNumber(isoNumber);

        final billingCurrencyType = currency == 'CLP'
            ? CurrencyType.national
            : CurrencyType.international;

        // Parse description
        final description = nullIfEmpty(tx.descripcion) ?? '';

        // Parse amount - for national divide by 100, for international use as is
        final importe = tx.importe;
        if (importe == null || importe.isEmpty) {
          continue;
        }

        final importeInt = int.tryParse(importe) ?? 0;
        final amount = billingCurrencyType == CurrencyType.national
            ? importeInt / 100
            : importeInt.toDouble();

        // Parse date
        final fecha = tx.fecha;
        if (fecha == null || fecha.isEmpty) {
          continue;
        }

        final transactionDate = tryGetIsoDateFromNoSeparatorYYMMDD(fecha);
        if (transactionDate == null) {
          continue;
        }

        // Get country
        final pais = tx.pais;
        String? country;
        if (pais != null && pais.isNotEmpty) {
          country = _get2LetterCountryFrom3LetterCountry(pais);
        }

        // Get city
        final ciudad = nullIfEmpty(tx.ciudad);

        // Generate transaction ID
        final movementNumber = tx.numeroMovimientoExtracto ?? '';
        final transactionId = _generateTransactionId(
          transactionDate,
          movementNumber,
          amount.toString(),
          description,
        );

        // Convert amount to integer (amounts are stored as integers in cents)
        final amountInt = (amount * 100).round();

        transactions.add(
          Transaction(
            id: transactionId,
            type: TransactionType.default_,
            description: description,
            amount: TransactionAmountRequired(
              amount: amountInt,
              currency: currency,
            ),
            billingCurrencyType: billingCurrencyType,
            transactionDate: transactionDate,
            transactionTime: null,
            processingDate: null,
            originalAmount: TransactionAmountOptional(
              amount: amountInt,
              currency: currency,
            ),
            city: ciudad,
            country: country,
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

