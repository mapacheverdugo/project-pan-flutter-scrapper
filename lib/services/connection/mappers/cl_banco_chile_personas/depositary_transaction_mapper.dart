import 'package:pan_scrapper/entities/amount.dart';
import 'package:pan_scrapper/entities/currency.dart';
import 'package:pan_scrapper/entities/index.dart';
import 'package:pan_scrapper/helpers/date_helpers.dart';
import 'package:pan_scrapper/helpers/string_helpers.dart';
import 'package:pan_scrapper/services/connection/models/cl_banco_chile_personas/cartola_model.dart';

class ClBancoChilePersonasDepositaryTransactionMapper {
  static List<ExtractedTransactionWithoutProviderId> fromCartolaModel(
    ClBancoChilePersonasCartolaModel model,
  ) {
    if (model.movimientos.isEmpty) {
      return [];
    }

    // Parse currency from moneda field
    final currency = model.moneda == r'$'
        ? Currency.clp
        : Currency.fromIsoLetters(model.moneda ?? 'CLP');

    final transactions = <ExtractedTransactionWithoutProviderId>[];

    for (final movimiento in model.movimientos) {
      try {
        final fecha = movimiento.fecha;
        if (fecha == null || fecha.isEmpty) {
          continue; // Skip transactions without date
        }

        // Parse transaction date and time from fecha (YYYYMMDDHHmmSS format)
        final fechaDatePart = fecha.length >= 8 ? fecha.substring(0, 8) : fecha;
        final transactionDate = tryGetIsoDateFromNoSeparatorYYYYMMDD(fechaDatePart);
        if (transactionDate == null) {
          continue; // Skip transactions with invalid date
        }

        // Extract time from YYYYMMDDHHmmSS format (if available)
        String? transactionTime;
        if (fecha.length >= 14) {
          // Extract HHmmSS from position 8-13
          final timePart = fecha.substring(8, 14);
          if (timePart.length == 6) {
            transactionTime = '${timePart.substring(0, 2)}:${timePart.substring(2, 4)}:${timePart.substring(4, 6)}';
          }
        }

        // Parse processing date from fechaContable (DD/MM/YYYY format)
        final fechaContable = movimiento.fechaContable;
        String? processingDate;
        if (fechaContable != null && fechaContable.isNotEmpty) {
          try {
            processingDate = getIsoDateFromSlashSeparatedDDMMYYYYDate(fechaContable);
          } catch (e) {
            // Skip if date parsing fails
            processingDate = null;
          }
        }

        final description = nullIfEmpty(movimiento.descripcion) ?? '';

        // Parse amount: positive if tipo is 'abono', negative otherwise
        final monto = movimiento.monto;
        if (monto == null || monto.isEmpty) {
          continue; // Skip transactions without amount
        }

        // Parse amount value
        final amountValue = int.tryParse(monto);
        if (amountValue == null) {
          continue; // Skip transactions with invalid amount
        }

        // Apply sign based on tipo: 'abono' = positive, otherwise negative
        final signedAmount = movimiento.tipo == 'abono' ? amountValue : -amountValue;

        // Create Amount object - CLP uses factor 1, other currencies might need different handling
        final amount = Amount(
          currency: currency,
          value: signedAmount,
        );

        transactions.add(
          ExtractedTransactionWithoutProviderId(
            description: description,
            amount: amount,
            transactionDate: transactionDate,
            transactionTime: transactionTime,
            processingDate: processingDate,
            originalAmount: amount,
            city: null,
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
