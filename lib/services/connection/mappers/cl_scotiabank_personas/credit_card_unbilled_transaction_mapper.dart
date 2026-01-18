import 'package:pan_scrapper/entities/amount.dart';
import 'package:pan_scrapper/entities/currency.dart';
import 'package:pan_scrapper/entities/currency_type.dart';
import 'package:pan_scrapper/entities/extracted_transaction.dart';
import 'package:pan_scrapper/helpers/date_helpers.dart';
import 'package:pan_scrapper/helpers/string_helpers.dart';
import 'package:pan_scrapper/services/connection/mappers/common.dart';
import 'package:pan_scrapper/services/connection/models/cl_scotiabank_personas/card_unbilled_transactions_response_model.dart';

class ClScotiabankPersonasCreditCardUnbilledTransactionMapper {
  static List<ExtractedTransaction> fromResponseModel(
    ClScotiabankPersonasCardUnbilledTransactionsResponseModel model,
    CurrencyType billingCurrencyType,
  ) {
    final lstUltimosMovVisaEnc = model.lstUltimosMovVisaEnc;
    final transactions = <ExtractedTransactionWithoutProviderId?>[];

    // Get the fant date for filtering installment transactions
    final fantDateStr = nullIfEmpty(lstUltimosMovVisaEnc.fant);
    final fantDate = fantDateStr != null
        ? tryGetIsoDateFromNoSeparatorYYYYMMDD(fantDateStr)
        : null;

    final gtipo = lstUltimosMovVisaEnc.gtipo;
    final gdesc = lstUltimosMovVisaEnc.gdesc;
    final vtrs = lstUltimosMovVisaEnc.vtrs;
    final ftrs = lstUltimosMovVisaEnc.ftrs;
    final vmonori = lstUltimosMovVisaEnc.vmonori;
    final svmonori = lstUltimosMovVisaEnc.svmonori;
    final gciu = lstUltimosMovVisaEnc.gciu;
    final cpais = lstUltimosMovVisaEnc.cpais;
    final svtrs = lstUltimosMovVisaEnc.svtrs;

    final maxLength = [
      gtipo.length,
      gdesc.length,
      vtrs.length,
      ftrs.length,
      gciu.length,
      cpais.length,
      svtrs.length,
    ].reduce((a, b) => a < b ? a : b);

    for (int i = 0; i < maxLength; i++) {
      try {
        // Combine gtipo[i] + gdesc[i] for description
        final tipo = i < gtipo.length ? gtipo[i] : '';
        final desc = i < gdesc.length ? gdesc[i] : '';
        final description = nullIfEmpty('$tipo$desc') ?? '';

        // Get amount string
        final transactionAmountStr = i < vtrs.length
            ? (nullIfEmpty(vtrs[i]) ?? '')
            : '';
        if (transactionAmountStr.isEmpty) {
          continue;
        }

        final originalAmountStr = i < vmonori.length
            ? (nullIfEmpty(vmonori[i]) ?? '')
            : '';

        // Get date string
        final dateStr = i < ftrs.length ? nullIfEmpty(ftrs[i]) : null;
        if (dateStr == null || dateStr.isEmpty) {
          continue;
        }

        // Parse date from YYYYMMDD format
        final transactionDate = tryGetIsoDateFromNoSeparatorYYYYMMDD(dateStr);
        if (transactionDate == null) {
          continue;
        }

        // Filter out transactions with dates before fant (installment transactions)
        if (fantDate != null) {
          final transactionDateObj = DateTime.tryParse(transactionDate);
          final fantDateObj = DateTime.tryParse(fantDate);
          if (transactionDateObj != null &&
              fantDateObj != null &&
              transactionDateObj.isBefore(fantDateObj)) {
            continue;
          }
        }

        // Get city and country
        final city = i < gciu.length ? nullIfEmpty(gciu[i]) : null;
        final country = i < cpais.length ? nullIfEmpty(cpais[i]) : null;

        final transactionAmountSign = i < svtrs.length
            ? (nullIfEmpty(svtrs[i]) ?? '')
            : '';
        final originalAmountSign = i < svmonori.length
            ? (nullIfEmpty(svmonori[i]) ?? '')
            : '';

        // Determine currency type from country: CL = NATIONAL, else INTERNATIONAL
        final billingCurrencyType = country == 'CL'
            ? CurrencyType.national
            : CurrencyType.international;
        final currency = billingCurrencyType == CurrencyType.national
            ? Currency.clp
            : Currency.usd;

        final transactionAmount = Amount.tryParse(
          transactionAmountStr,
          currency,
          options: AmountParseOptions(
            invertSign: transactionAmountSign == '+',
            factor: 100,
          ),
        );

        if (transactionAmount == null) {
          continue;
        }

        final originalAmount = Amount.tryParse(
          originalAmountStr,
          currency,
          options: AmountParseOptions(
            invertSign: originalAmountSign == '+',
            factor: 100,
          ),
        );

        transactions.add(
          ExtractedTransactionWithoutProviderId(
            description: description,
            amount: transactionAmount,
            transactionDate: transactionDate,
            transactionTime: null,
            processingDate: transactionDate,
            originalAmount: originalAmount,
            city: city,
            country: country,
            billingCurrencyType: billingCurrencyType,
          ),
        );
      } catch (e) {
        // Skip transactions with errors
        continue;
      }
    }

    final filteredTransactions = transactions
        .where((e) => e?.billingCurrencyType == billingCurrencyType)
        .toList();

    return CommonsMapper.processTransactions(filteredTransactions);
  }
}
