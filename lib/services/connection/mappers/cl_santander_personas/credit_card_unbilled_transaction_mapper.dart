import 'package:pan_scrapper/entities/currency.dart';
import 'package:pan_scrapper/entities/index.dart';
import 'package:pan_scrapper/helpers/date_helpers.dart';
import 'package:pan_scrapper/helpers/string_helpers.dart';
import 'package:pan_scrapper/services/connection/models/cl_santander_personas/index.dart';

class ClSantanderPersonasCreditCardUnbilledTransactionMapper {
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

  static List<ExtractedTransactionWithoutProviderId>
  fromUnbilledTransactionResponseModel(
    ClSantanderPersonasCreditCardUnbilledTransactionResponseModel model,
  ) {
    final matriz = model
        .data
        .conMovimientosPorFacturarResponse
        .output
        .matrizMovimientosPorFacturar;

    if (matriz.isEmpty) {
      return [];
    }

    final transactions = <ExtractedTransactionWithoutProviderId>[];

    for (final tx in matriz) {
      try {
        // Get currency from ISO number
        final codigoMoneda = tx.codigoMoneda;
        if (codigoMoneda == null || codigoMoneda.isEmpty) {
          continue;
        }

        final isoNumber = int.tryParse(codigoMoneda) ?? 152;
        final currency = Currency.fromIsoNum(isoNumber.toString());

        final billingCurrencyType = currency == Currency.clp
            ? CurrencyType.national
            : CurrencyType.international;

        // Parse description
        final description = nullIfEmpty(tx.descripcion) ?? '';

        if (description.trim().toUpperCase() == 'SALDO INICIAL') {
          continue;
        }

        // Parse amount - for national divide by 100, for international use as is
        final importe = tx.importe;

        if (importe == null || importe.isEmpty) {
          continue;
        }

        final amountParseOptions = billingCurrencyType == CurrencyType.national
            ? AmountParseOptions()
            : AmountParseOptions(factor: 100);

        final amount = Amount.tryParse(
          importe,
          currency,
          options: amountParseOptions,
        );

        if (amount == null) {
          continue;
        }

        // Parse date
        final fecha = tx.fecha;
        if (fecha == null || fecha.isEmpty) {
          continue;
        }

        final transactionDate = tryGetIsoDateFromNoSeparatorYYMMDD(fecha);
        if (transactionDate == null) {
          continue;
        }

        final pais = tx.pais;
        String? country;
        if (pais != null && pais.isNotEmpty) {
          country = _get2LetterCountryFrom3LetterCountry(pais);
        }

        final city = nullIfEmpty(tx.ciudad);

        transactions.add(
          ExtractedTransactionWithoutProviderId(
            description: description,
            amount: amount,
            billingCurrencyType: billingCurrencyType,
            transactionDate: transactionDate,
            transactionTime: null,
            processingDate: null,
            originalAmount: amount,
            city: city,
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
