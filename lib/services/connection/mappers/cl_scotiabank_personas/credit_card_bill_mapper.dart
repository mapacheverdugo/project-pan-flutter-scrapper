import 'package:pan_scrapper/entities/amount.dart';
import 'package:pan_scrapper/entities/currency.dart';
import 'package:pan_scrapper/entities/currency_type.dart';
import 'package:pan_scrapper/entities/extracted_credit_card_bill_summary.dart';
import 'package:pan_scrapper/helpers/date_helpers.dart';
import 'package:pan_scrapper/services/connection/models/cl_scotiabank_personas/get_simple_account_statement_response.dart';

class ClScotiabankPersonasCreditCardBillMapper {
  static ExtractedCreditCardBillSummary fromResponseModel(
    ClScotiabankPersonasGetSimpleAccountStatementResponse model,
    String periodId,
    CurrencyType currencyType,
  ) {
    final resumen = model.informacionPeriodoResumen;
    final detalle = model.informacionPeriodoDetalle;
    final proximoResumen = model.proximoPeriodoResumen;
    final proximoDetalle = model.proximoPeriodoDetalle;

    // Determine currency based on currencyType
    final currency = currencyType == CurrencyType.international
        ? Currency.usd
        : Currency.clp;

    // Map previous bill summary
    ExtractedCreditCardBillSummaryPreviousBillSummary? previousBillSummary;
    if (detalle != null) {
      previousBillSummary = ExtractedCreditCardBillSummaryPreviousBillSummary(
        initialDueAmount: null,
        totalDueAmount: null,
        billedAmount: _parseAmount(
          detalle.totalPeriodoAnterior,
          currency,
        )?.value,
        paidAmount: _parseAmount(detalle.pagosRealizados, currency)?.value,
        finalDueAmount: _parseAmount(
          detalle.saldoPeriodoAnterior,
          currency,
        )?.value,
        toDate: _parseDate(resumen?.periodoFacturacionDesde),
        pendingDueAmount: null,
      );
    }

    // Map next 4 months from proximasCuotas - only for national currency
    List<ExtractedCreditCardBillSummaryNext4MonthsItem>? next4Months;
    if (currencyType == CurrencyType.national &&
        proximoDetalle != null &&
        proximoDetalle.proximasCuotas.isNotEmpty) {
      next4Months = proximoDetalle.proximasCuotas.asMap().entries.take(4).map((
        entry,
      ) {
        final value = _parseAmount(entry.value, currency)?.value;
        return ExtractedCreditCardBillSummaryNext4MonthsItem(
          number: entry.key + 1,
          value: value,
        );
      }).toList();
    }

    final summary = ExtractedCreditCardBillSummary(
      currentBillDate: _parseDate(resumen?.periodoFacturacionHasta),
      cardBalance: null,
      cashAdvanceBalance: null,
      prepaidCae: null,
      prepaidCost: null,
      openingBillingDate: _parseDate(resumen?.periodoFacturacionDesde),
      closingBillingDate: _parseDate(resumen?.periodoFacturacionHasta),
      paymentDueDate: _parseDate(resumen?.pagarHasta),
      minimumPaymentAmount: _parseAmount(resumen?.pagoMinimo, currency)?.value,
      totalBilledAmount: _parseAmount(resumen?.totalFacturado, currency)?.value,
      previousBillSummary: previousBillSummary,
      next4Months: next4Months,
      installmentBalance: _parseAmount(
        detalle?.totalComprasAvancesEnCuotas,
        currency,
      )?.value,
      nextBillOpeningBillingDate: _parseDate(proximoResumen?.periodoDesde),
      nextBillClosingBillingDate: _parseDate(proximoResumen?.periodoHasta),
      latePaymentCost: null,
      metadata: null,
    );

    return summary;
  }

  static Amount? _parseAmount(String? value, Currency currency) {
    if (value == null || value.isEmpty) return null;
    return Amount.tryParse(
      value,
      currency,
      options: AmountParseOptions(
        factor: 1,
        thousandSeparator: '.',
        decimalSeparator: ',',
      ),
    );
  }

  /// Parse date from DD/MM/YYYY format to YYYY-MM-DD ISO format
  /// Returns null if date is null, empty, or "--/--/--"
  static String? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    // Handle "--/--/--" as null
    if (dateStr.trim() == '--/--/--') return null;
    try {
      return getIsoDateFromSlashSeparatedDDMMYYYYDate(dateStr);
    } catch (e) {
      return null;
    }
  }
}
