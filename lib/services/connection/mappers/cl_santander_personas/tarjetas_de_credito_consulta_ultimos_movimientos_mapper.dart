import 'dart:developer';

import 'package:pan_scrapper/entities/currency.dart';
import 'package:pan_scrapper/entities/index.dart';
import 'package:pan_scrapper/helpers/date_helpers.dart';
import 'package:pan_scrapper/helpers/string_helpers.dart';
import 'package:pan_scrapper/services/connection/models/cl_santander_personas/index.dart';

class ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosMapper {
  static List<ExtractedTransaction> fromResponseModel(
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
    final transactions = <ExtractedTransaction>[];

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
          decimalSeparator: ',',
          thousandSeparator: '.',
        );

        log(
          'TarjetasDeCreditoConsultaUltimosMovimientosMapper importe: $importe',
        );

        log(
          'TarjetasDeCreditoConsultaUltimosMovimientosMapper movimiento.indicadorDebeHaber: ${movimiento.indicadorDebeHaber}',
        );

        final symbol = movimiento.indicadorDebeHaber == 'D' ? '-' : '+';
        final amountText = symbol + importe;

        log(
          'TarjetasDeCreditoConsultaUltimosMovimientosMapper amountText: $amountText',
        );

        final amount = Amount.tryParse(
          amountText,
          currency,
          options: amountOptions,
        );

        log(
          'TarjetasDeCreditoConsultaUltimosMovimientosMapper amount: ${amount?.value}',
        );

        if (amount == null) {
          continue;
        }

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

        transactions.add(
          ExtractedTransaction(
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
        log('TarjetasDeCreditoConsultaUltimosMovimientosMapper error: $e');
        // Skip transactions that fail to parse
        continue;
      }
    }

    return transactions;
  }
}
