import 'package:pan_scrapper/entities/amount.dart';
import 'package:pan_scrapper/entities/currency.dart';
import 'package:pan_scrapper/entities/extracted_transaction.dart';
import 'package:pan_scrapper/helpers/date_helpers.dart';
import 'package:pan_scrapper/helpers/string_helpers.dart';
import 'package:pan_scrapper/services/connection/mappers/common.dart';

class ClScotiabankPersonasDepositaryTransactionMapper {
  static List<ExtractedTransaction> fromResponse(String data) {
    return CommonsMapper.processTransactions(
      _parseDepositaryTransactionsData(data),
    );
  }

  static List<ExtractedTransactionWithoutProviderId?>
  _parseDepositaryTransactionsData(String data) {
    final lines = data.split('\n').where((line) => line.trim().isNotEmpty);

    final transactions = <ExtractedTransactionWithoutProviderId?>[];

    bool isTransactionSection = false;

    for (final line in lines) {
      final trimmedLine = line.trim();

      if (isTransactionSection) {
        final parts = trimmedLine.split(';');
        if (parts.length >= 6) {
          final rawDate = nullIfEmpty(parts[0]);
          final rawDescription = nullIfEmpty(parts[1]);
          final rawCargos = nullIfEmpty(parts[3]);
          final rawAbonos = nullIfEmpty(parts[4]);
          final rawSaldo = nullIfEmpty(parts[5]);

          if (rawDate == null ||
              (rawCargos == null && rawAbonos == null) ||
              rawDescription == null ||
              rawSaldo == null) {
            continue;
          }

          final amount = rawCargos != null
              ? Amount.tryParse(
                  rawCargos,
                  Currency.clp,
                  options: AmountParseOptions(
                    decimalSeparator: ",",
                    factor: 100,
                    invertSign: true,
                  ),
                )
              : (rawAbonos != null
                    ? Amount.tryParse(
                        rawAbonos,
                        Currency.clp,

                        options: AmountParseOptions(
                          decimalSeparator: ",",
                          factor: 100,
                        ),
                      )
                    : null);

          if (amount == null) {
            continue;
          }

          // Parse date from DDMMYYYY format
          final transactionDate = tryGetIsoDateFromNoSeparatorDDMMYYYY(rawDate);
          if (transactionDate == null) {
            continue; // Skip transactions with invalid date
          }

          transactions.add(
            ExtractedTransactionWithoutProviderId(
              description: rawDescription,
              amount: amount,
              transactionDate: transactionDate,
              transactionTime: null,
              processingDate: transactionDate,
              originalAmount: amount,
              city: null,
              country: null,
            ),
          );
        }
      } else if (trimmedLine.startsWith(
        'Fecha;Descripcion;NroDoc.;Cargos;Abonos;Saldo',
      )) {
        isTransactionSection = true;
        continue;
      }
    }

    return transactions;
  }
}
