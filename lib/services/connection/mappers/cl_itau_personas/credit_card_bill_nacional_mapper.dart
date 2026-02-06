import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:pan_scrapper/entities/amount.dart';
import 'package:pan_scrapper/entities/currency.dart';
import 'package:pan_scrapper/entities/currency_type.dart';
import 'package:pan_scrapper/entities/extracted_credit_card_bill_summary.dart';
import 'package:pan_scrapper/entities/extracted_transaction.dart';
import 'package:pan_scrapper/entities/extracted_transaction_installments.dart';
import 'package:pan_scrapper/helpers/date_helpers.dart';

/// Parses Itaú national credit card bill HTML (estado de cuenta nacional).
///
/// Expects the fragment that contains #estado-cuenta-nacional or #contenido
/// with span[name="..."] fields and table operacion_Table for transactions.
class ClItauPersonasCreditCardBillNacionalMapper {
  static final _clpOptions = AmountParseOptions(
    thousandSeparator: '.',
    decimalSeparator: ',',
    invertSign: true,
  );

  /// Returns [ExtractedCreditCardBillSummary] and list of bill transactions.
  /// [transactions] excludes section header rows (e.g. "1.Total operaciones").
  static ClItauPersonasCreditCardBillNacionalResult
  fromEstadoCuentaNacionalHtml(String html) {
    final doc = parse(html);
    final summary = _parseSummary(doc);
    final transactions = _parseTransactions(doc);
    return ClItauPersonasCreditCardBillNacionalResult(
      summary: summary,
      transactions: transactions,
    );
  }

  static String? _span(dynamic root, String name) {
    final el = root.querySelector('span[name="$name"]');
    final text = el?.text;
    return text?.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static ExtractedCreditCardBillSummary? _parseSummary(Document doc) {
    // Root may be #contenido or #estado-cuenta-nacional or document
    final root =
        doc.querySelector('#contenido') ??
        doc.querySelector('#estado-cuenta-nacional') ??
        doc;

    String? s(String name) => _span(root, name);

    final currency = Currency.clp;

    // Card balance: Cupo total, utilizado, disponible
    final cupoTotal = _parseAmount(s('CupoTotal_iso8601'), currency);
    final cupoUtilizado = _parseAmount(s('CupoUtilizado_iso8601'), currency);
    final cupoDisponible = _parseAmount(s('CupoDisponible_iso8601'), currency);
    ExtractedCreditCardBillSummaryCardBalance? cardBalance;
    if (cupoTotal != null || cupoUtilizado != null || cupoDisponible != null) {
      cardBalance = ExtractedCreditCardBillSummaryCardBalance(
        creditLimit: cupoTotal?.value,
        usedCredit: cupoUtilizado?.value,
        availableCredit: cupoDisponible?.value,
      );
    }

    // Cash advance balance (avance en efectivo)
    final fld144 = _parseAmount(s('fld_144_iso8601'), currency);
    final fld145 = _parseAmount(s('fld_145_iso8601'), currency);
    final fld146 = _parseAmount(s('fld_146_iso8601'), currency);
    ExtractedCreditCardBillSummaryCardBalance? cashAdvanceBalance;
    if (fld144 != null || fld145 != null || fld146 != null) {
      cashAdvanceBalance = ExtractedCreditCardBillSummaryCardBalance(
        creditLimit: fld144?.value,
        usedCredit: fld145?.value,
        availableCredit: fld146?.value,
      );
    }

    // Interest rates: Rotativo, Compra en cuotas, Avance (percentages like "2,13%")
    final revolving = _parsePercent(s('CARGO_CTA'));
    final installmentPurchases = _parsePercent(s('CREDITO_RAT'));
    final cashAdvances = _parsePercent(s('fld_147_iso8601'));
    ExtractedCreditCardBillSummaryCurrentInterestRate? currentInterestRate;
    if (revolving != null ||
        installmentPurchases != null ||
        cashAdvances != null) {
      currentInterestRate = ExtractedCreditCardBillSummaryCurrentInterestRate(
        revolving: revolving,
        installmentPurchases: installmentPurchases,
        cashAdvances: cashAdvances,
      );
    }

    // CAE (Costos Anuales Equivalentes)
    final caeRevolving = _parsePercent(s('fld_148_iso8601'));
    final caeInstallment = _parsePercent(s('fld_149_iso8601'));
    final caeAvance = _parsePercent(s('fld_150_iso8601'));
    ExtractedCreditCardBillSummaryCae? cae;
    if (caeRevolving != null || caeInstallment != null || caeAvance != null) {
      cae = ExtractedCreditCardBillSummaryCae(
        revolving: caeRevolving,
        installmentPurchases: caeInstallment,
        cashAdvances: caeAvance,
      );
    }

    final prepaidCae = _parsePercent(s('fld_151_iso8601'));

    // Previous period summary
    final prevFrom = _parseDate(s('fld_152_iso8601'));
    final prevTo = _parseDate(s('fld_153_iso8601'));
    final prevInitial = _parseAmount(s('fld_154_iso8601'), currency)?.value;
    final prevBilled = _parseAmount(s('fld_155_iso8601'), currency)?.value;
    final prevPaid = _parseAmount(s('fld_156_iso8601'), currency)?.value;
    final prevFinal = _parseAmount(s('fld_157_iso8601'), currency)?.value;
    ExtractedCreditCardBillSummaryPreviousBillSummary? previousBillSummary;
    if (prevFrom != null ||
        prevTo != null ||
        prevInitial != null ||
        prevBilled != null ||
        prevPaid != null ||
        prevFinal != null) {
      previousBillSummary = ExtractedCreditCardBillSummaryPreviousBillSummary(
        fromDate: prevFrom,
        toDate: prevTo,
        initialDueAmount: prevInitial,
        totalDueAmount: prevBilled,
        billedAmount: prevBilled,
        paidAmount: prevPaid,
        finalDueAmount: prevFinal,
        pendingDueAmount: null,
      );
    }

    // Next 4 months (DetalleVencimiento1..4)
    final next1 = _parseAmount(
      s('DetalleVencimiento1_iso8601'),
      currency,
    )?.value;
    final next2 = _parseAmount(
      s('DetalleVencimiento2_iso8601'),
      currency,
    )?.value;
    final next3 = _parseAmount(
      s('DetalleVencimiento3_iso8601'),
      currency,
    )?.value;
    final next4 = _parseAmount(
      s('DetalleVencimiento4_iso8601'),
      currency,
    )?.value;
    List<ExtractedCreditCardBillSummaryNext4MonthsItem>? next4Months;
    if (next1 != null || next2 != null || next3 != null || next4 != null) {
      next4Months = [
        if (next1 != null)
          ExtractedCreditCardBillSummaryNext4MonthsItem(
            number: 1,
            value: next1,
          ),
        if (next2 != null)
          ExtractedCreditCardBillSummaryNext4MonthsItem(
            number: 2,
            value: next2,
          ),
        if (next3 != null)
          ExtractedCreditCardBillSummaryNext4MonthsItem(
            number: 3,
            value: next3,
          ),
        if (next4 != null)
          ExtractedCreditCardBillSummaryNext4MonthsItem(
            number: 4,
            value: next4,
          ),
      ];
    }

    // Late payment cost (Interés Moratorio + Cargo de Cobranza)
    final defaultInterestRateStr = s('fld_124_iso8601'); // e.g. "25,56%"
    List<ExtractedCreditCardBillSummaryLatePaymentCostCollectionCharge>?
    collectionCharge;
    final upTo1 = s('fld_158_iso8601');
    final pct1 = s('fld_159_iso8601');
    final upTo2 = s('fld_160_iso8601');
    final upTo3 = s('fld_161_iso8601');
    final pct2 = s('fld_162_iso8601');
    final above3 = s('fld_163_iso8601');
    final pct3 = s('fld_164_iso8601');
    if (upTo1 != null ||
        pct1 != null ||
        upTo2 != null ||
        pct2 != null ||
        above3 != null ||
        pct3 != null) {
      collectionCharge = [
        if (upTo1 != null && pct1 != null)
          ExtractedCreditCardBillSummaryLatePaymentCostCollectionCharge(
            debtAmountUF: 'Hasta $upTo1 UF',
            percentage: pct1,
          ),
        if (upTo2 != null && upTo3 != null && pct2 != null)
          ExtractedCreditCardBillSummaryLatePaymentCostCollectionCharge(
            debtAmountUF: 'Excedan $upTo2 UF y hasta $upTo3 UF',
            percentage: pct2,
          ),
        if (above3 != null && pct3 != null)
          ExtractedCreditCardBillSummaryLatePaymentCostCollectionCharge(
            debtAmountUF: 'Excedan $above3 UF',
            percentage: pct3,
          ),
      ];
    }
    ExtractedCreditCardBillSummaryLatePaymentCost? latePaymentCost;
    if (defaultInterestRateStr != null ||
        (collectionCharge != null && collectionCharge.isNotEmpty)) {
      latePaymentCost = ExtractedCreditCardBillSummaryLatePaymentCost(
        defaultInterestRate: defaultInterestRateStr,
        collectionCharge: collectionCharge?.isNotEmpty == true
            ? collectionCharge
            : null,
        notes: null,
      );
    }

    return ExtractedCreditCardBillSummary(
      currentBillDate: _parseDate(s('FechaFacturacion_iso8601')),
      cardBalance: cardBalance,
      cashAdvanceBalance: cashAdvanceBalance,
      currentInterestRate: currentInterestRate,
      cae: cae,
      prepaidCae: prepaidCae,
      openingBillingDate: _parseDate(s('fld_15_iso8601')),
      closingBillingDate: _parseDate(s('pfFechaFacturacion_iso8601')),
      paymentDueDate: _parseDate(s('PagarHasta_iso8601')),
      previousBillSummary: previousBillSummary,
      totalBilledAmount: _parseAmount(
        s('infoMontoFacturado_iso8601'),
        currency,
      )?.value,
      minimumPaymentAmount: _parseAmount(
        s('infoPagoMinimo_iso8601'),
        currency,
      )?.value,
      prepaidCost: _parseAmount(s('fld_121_iso8601'), currency)?.value,
      next4Months: next4Months,
      installmentBalance: _parseAmount(
        s('SaldoCapitalCuotas_iso8601'),
        currency,
      )?.value,
      nextBillOpeningBillingDate: _parseDate(s('fld_122_iso8601')),
      nextBillClosingBillingDate: _parseDate(s('fld_123_iso8601')),
      latePaymentCost: latePaymentCost,
      metadata: null,
    );
  }

  static List<ExtractedTransactionWithoutProviderId> _parseTransactions(
    Document doc,
  ) {
    final table = doc.querySelector(
      'table[name="operacion_Table"], table#EstadoDeudaNacionalPortletip_estadoDeCuentaTarjetaoperacion_table',
    );
    if (table == null) return [];

    final rows = table.querySelectorAll('tr[name="DataContainer"]');
    final list = <ExtractedTransactionWithoutProviderId>[];
    final currency = Currency.clp;

    for (final tr in rows) {
      // Skip section headers (single cell with colspan 8)
      final firstCell = tr.querySelector('td');
      if (firstCell != null) {
        final colspan = firstCell.attributes['colspan'];
        if (colspan == '8' || colspan == '2') continue;
      }

      String getSpan(String name) {
        final cell = tr.querySelector('td[name="${name}_ColumnData"]');
        return cell?.querySelector('span[name="$name"]')?.text.trim() ?? '';
      }

      final description = getSpan('Descripcion');
      if (description.isEmpty) continue;

      final amountStr = getSpan('MontoTransaccion_iso8601');
      final amount = _parseAmount(amountStr, currency);
      if (amount == null) continue;

      final dateStr = getSpan('NumeroReferencia_iso8601');
      final transactionDate = _parseDate(dateStr);
      final city = getSpan('Ciudad');

      // Cuota: "01/1" or "04/6" -> current/total
      ExtractedTransactionInstallments? installments;
      final cuotaStr = getSpan('cuota');
      if (cuotaStr.isNotEmpty) {
        final cuota = _parseCuota(cuotaStr);
        if (cuota != null) {
          final valorCuotaStr = getSpan('operacion_fld_21_iso8601');
          final currentAmount = _parseAmount(valorCuotaStr, currency);
          if (currentAmount != null) {
            installments = ExtractedTransactionInstallments(
              currentCount: cuota.$1,
              remainingCount: cuota.$2 - cuota.$1,
              totalCount: cuota.$2,
              currentAmount: currentAmount,
              originalTransactionAmount: null,
              totalFinalAmount: null,
              interestRate: null,
              firstInstallmentDate: transactionDate ?? '',
            );
          }
        }
      }

      list.add(
        ExtractedTransactionWithoutProviderId(
          description: description,
          amount: amount,
          transactionDate: transactionDate,
          transactionTime: null,
          processingDate: null,
          originalAmount: null,
          city: city.isEmpty ? null : city,
          country: null,
          billingCurrencyType: CurrencyType.national,
          billingStatus: null,
          installments: installments,
        ),
      );
    }

    return list;
  }

  /// Parses "01/1" or "04/6" -> (current, total). Returns null if invalid.
  static (int, int)? _parseCuota(String text) {
    final parts = text.split('/');
    if (parts.length != 2) return null;
    final current = int.tryParse(parts[0].trim());
    final total = int.tryParse(parts[1].trim());
    if (current == null || total == null || current > total) return null;
    return (current, total);
  }

  static Amount? _parseAmount(String? value, Currency currency) {
    if (value == null || value.trim().isEmpty) return null;
    return Amount.tryParse(value.trim(), currency, options: _clpOptions);
  }

  static String? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      return getIsoDateFromSlashSeparatedDDMMYYYYDate(value.trim());
    } catch (_) {
      return null;
    }
  }

  static double? _parsePercent(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final cleaned = value.trim().replaceAll('%', '').replaceAll(',', '.');
    return double.tryParse(cleaned);
  }
}

/// Result of parsing national credit card bill HTML.
class ClItauPersonasCreditCardBillNacionalResult {
  final ExtractedCreditCardBillSummary? summary;
  final List<ExtractedTransactionWithoutProviderId> transactions;

  ClItauPersonasCreditCardBillNacionalResult({
    this.summary,
    required this.transactions,
  });
}
