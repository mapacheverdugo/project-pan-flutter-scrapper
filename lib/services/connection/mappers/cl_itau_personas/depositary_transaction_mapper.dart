import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:pan_scrapper/entities/currency.dart';
import 'package:pan_scrapper/entities/index.dart';
import 'package:pan_scrapper/helpers/date_helpers.dart';

/// Parses Itaú "Cartola Histórica" HTML: table inside #tablaMovimientos
/// or empty state (#cartola-historicaSinDatos / no data rows).
class ClItauPersonasDepositaryTransactionMapper {
  static final _clpOptions = AmountParseOptions(
    thousandSeparator: '.',
    decimalSeparator: ',',
  );

  /// Parses cartola HTML. Returns empty list if:
  /// - #tablaMovimientos is missing
  /// - Empty state is present (#cartola-historicaSinDatos with "No existen datos")
  /// - No data rows (tr[name="DataContainer"]) found
  static List<ExtractedTransaction> fromCartolaHtml(String html) {
    final doc = parse(html);

    // Empty state: message like "No existen datos para la fecha consultada"
    final sinDatos = doc.querySelector('#cartola-historicaSinDatos');
    if (sinDatos != null) {
      final titulo = sinDatos.querySelector('span[name="titulo-mensaje"]');
      if (titulo != null &&
          titulo.text.toLowerCase().contains('no existen datos')) {
        return [];
      }
    }

    // Table container: #tablaMovimientos span[name="movimientos"]
    final tablaMovimientos = doc.querySelector('#tablaMovimientos');
    if (tablaMovimientos == null) return [];

    // Table: name="record_Table" or id containing "record_table"
    final table = tablaMovimientos.querySelector(
          'table[name="record_Table"], table[id*="record_table"]',
        ) ??
        tablaMovimientos.querySelector('table.gridTable');
    if (table == null) return [];

    final rows = table.querySelectorAll('tr[name="DataContainer"]');
    if (rows.isEmpty) return [];

    final transactions = <ExtractedTransaction>[];
    for (var i = 0; i < rows.length; i++) {
      final tx = _parseRow(rows[i], rowIndex: i);
      if (tx != null) transactions.add(tx);
    }
    return transactions;
  }

  static ExtractedTransaction? _parseRow(Element row, {required int rowIndex}) {
    String getSpan(String name) {
      final cell = row.querySelector('td[name="${name}_ColumnData"]');
      return cell?.querySelector('span[name="$name"]')?.text.trim() ?? '';
    }

    final dateRaw = getSpan('Fecha_page_iso8601');
    if (dateRaw.isEmpty) return null;

    String? transactionDate;
    try {
      transactionDate = getIsoDateFromSlashSeparatedDDMMYYYYDate(dateRaw);
    } catch (_) {
      return null;
    }

    final nroOperacion = getSpan('NroOperacion');
    final description = getSpan('Descripcion');
    final cargosRaw = getSpan('GirosoCargos_iso8601');
    final abonosRaw = getSpan('DepositosoAbonos_iso8601');

    // Amount: positive = abono (credit), negative = cargo (debit)
    final cargoAmount = _parseAmount(cargosRaw);
    final abonoAmount = _parseAmount(abonosRaw);

    int amountValue = 0;
    if (abonoAmount != null && abonoAmount.value != 0) {
      amountValue = abonoAmount.value;
    }
    if (cargoAmount != null && cargoAmount.value != 0) {
      amountValue = -cargoAmount.value;
    }

    final amount = Amount(currency: Currency.clp, value: amountValue);

    // providerId: NroOperacion; if repeated (e.g. 000000000), add row index
    final providerId = nroOperacion.isNotEmpty
        ? (nroOperacion == '000000000' ? 'row_${rowIndex}_$nroOperacion' : nroOperacion)
        : 'row_$rowIndex';

    return ExtractedTransaction(
      providerId: providerId,
      description: description.isEmpty ? 'Sin descripción' : description,
      amount: amount,
      transactionDate: transactionDate,
      transactionTime: null,
      processingDate: transactionDate,
      originalAmount: null,
      city: null,
      country: null,
    );
  }

  static Amount? _parseAmount(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return Amount.tryParse(
      trimmed,
      Currency.clp,
      options: _clpOptions,
    );
  }
}
