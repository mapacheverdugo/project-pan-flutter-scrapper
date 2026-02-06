import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:pan_scrapper/entities/currency.dart';
import 'package:pan_scrapper/entities/index.dart';
import 'package:pan_scrapper/helpers/date_helpers.dart';
import 'package:pan_scrapper/helpers/string_helpers.dart';

/// Parses Itaú credit card unbilled transactions HTML.
///
/// Two table variants:
/// - **International (USD)**: #imprimirDolares, MONTO_TRANSACCION column, amounts like "USD$ 49,17"
/// - **National (CLP)**: refreshTabla / displayPageTable, MONTO_TRANSACCION_ column, amounts like "$ -639.519" or "$ 587.328"
class ClItauPersonasCreditCardUnbilledTransactionMapper {
  static final _usdOptions = AmountParseOptions(
    thousandSeparator: null,
    decimalSeparator: ',',
    invertSign: true,
  );

  static final _clpOptions = AmountParseOptions(
    thousandSeparator: '.',
    decimalSeparator: ',',
    invertSign: true,
  );

  /// Parses unbilled transactions HTML for the given [billingCurrencyType].
  /// Returns empty list if no matching table or data rows found.
  static List<ExtractedTransactionWithoutProviderId>
  fromUnbilledTransactionsHtml(String html, CurrencyType billingCurrencyType) {
    final doc = parse(html);

    final currency = billingCurrencyType == CurrencyType.national
        ? Currency.clp
        : Currency.usd;

    // International: look for #imprimirDolares (USD table)
    // National: look for table with MONTO_TRANSACCION_ column (CLP table)
    Element? table;
    if (billingCurrencyType == CurrencyType.international) {
      final imprimirDolares = doc.querySelector('#imprimirDolares');
      table =
          imprimirDolares?.querySelector(
            'table[name="record_Table"], table[id*="record_table"]',
          ) ??
          imprimirDolares?.querySelector('table.gridTable');
    } else {
      // CLP: find table with MONTO_TRANSACCION_ in column header or data
      final allTables = doc.querySelectorAll(
        'table[name="record_Table"], table[id*="record_table"], table.gridTable',
      );
      for (final t in allTables) {
        if (_isClpTable(t)) {
          table = t;
          break;
        }
      }
    }

    if (table == null) return [];

    final rows = table.querySelectorAll('tr[name="DataContainer"]');
    if (rows.isEmpty) return [];

    final amountSpanName = billingCurrencyType == CurrencyType.international
        ? 'MONTO_TRANSACCION'
        : 'MONTO_TRANSACCION_';

    final amountOptions = billingCurrencyType == CurrencyType.international
        ? _usdOptions
        : _clpOptions;

    final transactions = <ExtractedTransactionWithoutProviderId>[];
    for (var i = 0; i < rows.length; i++) {
      final tx = _parseRow(
        rows[i],
        currency: currency,
        billingCurrencyType: billingCurrencyType,
        amountSpanName: amountSpanName,
        amountOptions: amountOptions,
        rowIndex: i,
      );
      if (tx != null) transactions.add(tx);
    }

    return transactions;
  }

  static bool _isClpTable(Element table) {
    // Check for MONTO_TRANSACCION_ header (CLP table)
    final header = table.querySelector(
      'th[name="MONTO_TRANSACCION__ColumnHeaderSorted"]',
    );
    if (header != null) return true;
    // Or check for span MONTO_TRANSACCION_ in any cell
    final span = table.querySelector('span[name="MONTO_TRANSACCION_"]');
    return span != null;
  }

  static ExtractedTransactionWithoutProviderId? _parseRow(
    Element row, {
    required Currency currency,
    required CurrencyType billingCurrencyType,
    required String amountSpanName,
    required AmountParseOptions amountOptions,
    required int rowIndex,
  }) {
    String getSpan(String name) {
      final cell = row.querySelector('td[name="${name}_ColumnData"]');
      return cell?.querySelector('span[name="$name"]')?.text.trim() ?? '';
    }

    final dateRaw = getSpan('FECHA_TRANSACCION_iso8601');
    if (dateRaw.isEmpty) return null;

    String? transactionDate;
    try {
      transactionDate = getIsoDateFromSlashSeparatedDDMMYYYYDate(dateRaw);
    } catch (_) {
      return null;
    }

    final processingDateRaw = getSpan('FECHA_POSTEO_iso8601');
    String? processingDate;
    if (processingDateRaw.isNotEmpty) {
      try {
        processingDate = getIsoDateFromSlashSeparatedDDMMYYYYDate(
          processingDateRaw,
        );
      } catch (_) {}
    }

    final description = nullIfEmpty(getSpan('GLOSA_TRANSACCION')) ?? '';
    final city = nullIfEmpty(getSpan('CIUDA_COMUNA'));

    final amountRaw = getSpan(amountSpanName);
    if (amountRaw.isEmpty) return null;

    final amount = Amount.tryParse(amountRaw, currency, options: amountOptions);
    if (amount == null) return null;

    return ExtractedTransactionWithoutProviderId(
      description: description,
      amount: amount,
      transactionDate: transactionDate,
      transactionTime: null,
      processingDate: processingDate ?? transactionDate,
      originalAmount: null,
      city: city,
      country: null,
      billingCurrencyType: billingCurrencyType,
    );
  }
}
