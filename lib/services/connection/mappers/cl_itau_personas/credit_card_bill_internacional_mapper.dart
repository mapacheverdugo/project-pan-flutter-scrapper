import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:pan_scrapper/entities/amount.dart';
import 'package:pan_scrapper/entities/currency.dart';
import 'package:pan_scrapper/entities/currency_type.dart';
import 'package:pan_scrapper/entities/extracted_credit_card_bill_summary.dart';
import 'package:pan_scrapper/entities/extracted_transaction.dart';
import 'package:pan_scrapper/helpers/date_helpers.dart';

/// Parses Itaú international credit card bill HTML (estado de cuenta internacional).
///
/// Uses USD amounts with [invertSign: true]. No installments (international
/// bill has no cuota column). Expects #contenido with span[name="..."] and
/// table record_Table for transactions.
class ClItauPersonasCreditCardBillInternacionalMapper {
  /// USD: comma decimal, dot thousands, invert sign (charges = negative).
  static final _usdOptions = AmountParseOptions(
    thousandSeparator: '.',
    decimalSeparator: ',',
    invertSign: true,
  );

  /// Returns [ExtractedCreditCardBillSummary] and list of bill transactions.
  /// Section header rows (e.g. "Total De Pagos", "Total De Compras") are skipped.
  static ClItauPersonasCreditCardBillInternacionalResult
      fromEstadoCuentaInternacionalHtml(String html) {
    final doc = parse(html);
    final summary = _parseSummary(doc);
    final transactions = _parseTransactions(doc);
    return ClItauPersonasCreditCardBillInternacionalResult(
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
    final root =
        doc.querySelector('#contenido') ?? doc;

    String? s(String name) => _span(root, name);

    final currency = Currency.usd;

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

    // Cash advance (Cupo avance en efectivo): fld_23, fld_24, fld_25
    final fld23 = _parseAmount(s('fld_23_iso8601'), currency);
    final fld24 = _parseAmount(s('fld_24_iso8601'), currency);
    final fld25 = _parseAmount(s('fld_25_iso8601'), currency);
    ExtractedCreditCardBillSummaryCardBalance? cashAdvanceBalance;
    if (fld23 != null || fld24 != null || fld25 != null) {
      cashAdvanceBalance = ExtractedCreditCardBillSummaryCardBalance(
        creditLimit: fld23?.value,
        usedCredit: fld24?.value,
        availableCredit: fld25?.value,
      );
    }

    // Previous period / payment info (international has different structure)
    final saldoAnterior = _parseAmount(s('SaldoAnteriorFacturado_iso8601'), currency)?.value;
    final abonoRealizado = _parseAmount(s('AbonoRealizado_iso8601'), currency)?.value;
    final traspasoNacional = _parseAmount(s('TraspasoDeudaNacional_iso8601'), currency)?.value;
    final deudaTotal = _parseAmount(s('DeudaTotal_iso8601'), currency)?.value;
    ExtractedCreditCardBillSummaryPreviousBillSummary? previousBillSummary;
    if (saldoAnterior != null || abonoRealizado != null || traspasoNacional != null) {
      previousBillSummary = ExtractedCreditCardBillSummaryPreviousBillSummary(
        fromDate: _parseDate(s('fld_12_iso8601')),
        toDate: _parseDate(s('FechaFacturacion_iso8601')),
        initialDueAmount: saldoAnterior,
        totalDueAmount: deudaTotal,
        billedAmount: null,
        paidAmount: abonoRealizado,
        finalDueAmount: deudaTotal,
        pendingDueAmount: null,
      );
    }

    return ExtractedCreditCardBillSummary(
      currentBillDate: _parseDate(s('FechaFacturacion_iso8601')) ?? _parseDate(s('FechaFacturacion')),
      cardBalance: cardBalance,
      cashAdvanceBalance: cashAdvanceBalance,
      currentInterestRate: null,
      cae: null,
      prepaidCae: null,
      openingBillingDate: _parseDate(s('fld_12_iso8601')),
      closingBillingDate: _parseDate(s('FechaFacturacion_iso8601')),
      paymentDueDate: _parseDate(s('PagarHasta_iso8601')),
      previousBillSummary: previousBillSummary,
      totalBilledAmount: deudaTotal ?? _parseAmount(s('DeudaTotalEmisor'), currency)?.value,
      minimumPaymentAmount: null,
      prepaidCost: null,
      next4Months: null,
      installmentBalance: null,
      nextBillOpeningBillingDate: null,
      nextBillClosingBillingDate: null,
      latePaymentCost: null,
      metadata: null,
    );
  }

  static List<ExtractedTransactionWithoutProviderId> _parseTransactions(
    Document doc,
  ) {
    final table = doc.querySelector(
      'table[name="record_Table"], table#EstadoDeudaInternacionalPortletip_estadoDeCuentaTarjetarecord_table',
    );
    if (table == null) return [];

    final rows = table.querySelectorAll('tr[name="DataContainer"]');
    final list = <ExtractedTransactionWithoutProviderId>[];
    final currency = Currency.usd;

    for (final tr in rows) {
      // Skip section headers (DetalleTransaccion with colspan 6)
      final detalleCell = tr.querySelector('td[name="DetalleTransaccion_ColumnData"]');
      if (detalleCell != null) {
        final colspan = detalleCell.attributes['colspan'];
        if (colspan == '6') continue;
      }

      String getSpan(String name) {
        final cell = tr.querySelector('td[name="${name}_ColumnData"]');
        return cell?.querySelector('span[name="$name"]')?.text.trim() ?? '';
      }

      final description = getSpan('DetalleTransaccion');
      if (description.isEmpty) continue;

      final amountStr = getSpan('MontoDolar_iso8601');
      final amount = _parseAmount(amountStr, currency);
      if (amount == null) continue;

      final dateStr = getSpan('Fecha_iso8601');
      final transactionDate = _parseDate(dateStr);
      final city = getSpan('Ciudad');
      final country = getSpan('Pais');

      list.add(
        ExtractedTransactionWithoutProviderId(
          description: description,
          amount: amount,
          transactionDate: transactionDate,
          transactionTime: null,
          processingDate: null,
          originalAmount: null,
          city: city.isEmpty ? null : city,
          country: country.isEmpty ? null : country,
          billingCurrencyType: CurrencyType.international,
          billingStatus: null,
          installments: null,
        ),
      );
    }

    return list;
  }

  static Amount? _parseAmount(String? value, Currency currency) {
    if (value == null || value.trim().isEmpty) return null;
    // Strip "USD$ " or "USD " prefix if present
    var cleaned = value.trim();
    if (cleaned.toUpperCase().startsWith('USD\$')) {
      cleaned = cleaned.substring(4).trim();
    } else if (cleaned.toUpperCase().startsWith('USD')) {
      cleaned = cleaned.substring(3).trim();
    }
    if (cleaned.isEmpty) return null;
    return Amount.tryParse(cleaned, currency, options: _usdOptions);
  }

  static String? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      return getIsoDateFromSlashSeparatedDDMMYYYYDate(value.trim());
    } catch (_) {
      return null;
    }
  }
}

/// Result of parsing international credit card bill HTML.
class ClItauPersonasCreditCardBillInternacionalResult {
  final ExtractedCreditCardBillSummary? summary;
  final List<ExtractedTransactionWithoutProviderId> transactions;

  ClItauPersonasCreditCardBillInternacionalResult({
    this.summary,
    required this.transactions,
  });
}
