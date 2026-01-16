import 'package:pan_scrapper/entities/currency.dart';
import 'package:pan_scrapper/entities/index.dart';
import 'package:pan_scrapper/helpers/date_helpers.dart';
import 'package:pan_scrapper/helpers/string_helpers.dart';
import 'package:pan_scrapper/services/connection/models/cl_banco_chile_personas/movimientos_no_facturados_model.dart';

class ClBancoChilePersonasCreditCardUnbilledTransactionMapper {
  static List<ExtractedTransactionWithoutProviderId>
  fromUnbilledTransactionModel(
    ClBancoChilePersonasMovimientosNoFacturadosModel model,
  ) {
    if (model.listaMovNoFactur.isEmpty) {
      return [];
    }

    final transactions = <ExtractedTransactionWithoutProviderId>[];

    for (final tx in model.listaMovNoFactur) {
      try {
        final billingCurrencyType = tx.origenTransaccion == 'INT'
            ? CurrencyType.international
            : CurrencyType.national;

        final currency = billingCurrencyType == CurrencyType.national
            ? Currency.clp
            : Currency.usd;

        final amountParseOptions = AmountParseOptions(
          decimalSeparator: '.',
          thousandSeparator: null,
          invertSign: true,
        );

        final transactionAmount = Amount.tryParse(
          tx.montoCompra.toString(),
          currency,
          options: amountParseOptions,
        );

        if (transactionAmount == null) {
          continue;
        }

        final originalAmountCurrency = Currency.fromIsoNum(
          tx.codigoMonedaOrigen.toString(),
        );
        final originalAmount = Amount.tryParse(
          tx.montoMonedaOrigen.toString(),
          originalAmountCurrency,
          options: amountParseOptions,
        );

        // Parse transaction date from fechaTransaccion (milliseconds)
        final fechaTransaccion = tx.fechaTransaccion;
        if (fechaTransaccion == null) {
          continue; // Skip transactions without date
        }

        final transactionDate = getIsoDateFromMilliseconds(fechaTransaccion);

        // Parse processing date from fechaAutorizacion (string that needs to be parsed as int)
        String? processingDate;
        final fechaAutorizacion = tx.fechaAutorizacion;
        if (fechaAutorizacion != null && fechaAutorizacion.isNotEmpty) {
          final fechaAutorizacionInt = int.tryParse(fechaAutorizacion);
          if (fechaAutorizacionInt != null) {
            processingDate = getIsoDateFromMilliseconds(fechaAutorizacionInt);
          }
        }

        final description = nullIfEmpty(tx.glosaTransaccion) ?? '';
        final country = tx.codigoPaisComercio;
        final city = nullIfEmpty(tx.ciudad);

        transactions.add(
          ExtractedTransactionWithoutProviderId(
            description: description,
            amount: transactionAmount,
            transactionDate: transactionDate,
            transactionTime: null,
            processingDate: processingDate,
            originalAmount: originalAmount,
            billingCurrencyType: billingCurrencyType,
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
