import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:example/widget/transaction_list_item.dart';
import 'package:flutter/material.dart';
import 'package:pan_scrapper/entities/currency.dart';
import 'package:pan_scrapper/entities/currency_type.dart';
import 'package:pan_scrapper/entities/extraction.dart';
import 'package:pan_scrapper/entities/extraction_operation.dart';
import 'package:pan_scrapper/entities/index.dart';
import 'package:pan_scrapper/pan_scrapper_service.dart';
import 'package:pan_scrapper/presentation/widgets/loading_indicator.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class BillPeriodDetailsScreen extends StatefulWidget {
  const BillPeriodDetailsScreen({
    super.key,
    required this.service,
    required this.product,
    required this.periodId,
    required this.currencyType,
    required this.periodLabel,
  });

  final PanScrapperService service;
  final ExtractedProductModel product;
  final String periodId;
  final CurrencyType currencyType;
  final String periodLabel;

  @override
  State<BillPeriodDetailsScreen> createState() => _BillPeriodDetailsScreenState();
}

class _BillPeriodDetailsScreenState extends State<BillPeriodDetailsScreen> {
  bool _isLoading = true;
  bool _isLoadingPdf = false;
  ExtractedCreditCardBill? _bill;
  List<ExtractedTransactionWithoutProviderId> _transactions = [];
  String? _error;

  bool get _isUnbilled => widget.periodId == 'unbilled';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      if (_isUnbilled) {
        final unbilledTransactions = await widget.service
            .getCreditCardUnbilledTransactions(
              widget.product.providerId,
              widget.currencyType,
            );
        if (mounted) {
          setState(() {
            _transactions = unbilledTransactions;
            _isLoading = false;
          });
        }
      } else {
        final bill = await widget.service.getCreditCardBill(
          widget.product.providerId,
          widget.periodId,
        );
        if (mounted) {
          setState(() {
            _bill = bill;
            _transactions = bill.transactions ?? [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.periodLabel),
      ),
      body: _isLoading
          ? Center(
              child: LoadingIndicator(size: 40),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_bill != null) _buildBillSummary(_bill!),
                      if (_bill != null) SizedBox(height: 20),
                      if (_bill != null && !_isUnbilled)
                        ElevatedButton.icon(
                          onPressed: _isLoadingPdf ? null : () => _openPdf(_bill!),
                          icon: _isLoadingPdf
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: const LoadingIndicator(size: 16),
                                )
                              : Icon(Icons.picture_as_pdf),
                          label: Text('Open PDF'),
                        ),
                      if (_bill != null && !_isUnbilled) SizedBox(height: 20),
                      if (_isUnbilled)
                        Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Unbilled transactions',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      if (_transactions.isNotEmpty)
                        ..._transactions.map((transaction) {
                          return TransactionListItem(transaction: transaction);
                        }),
                      if (_transactions.isEmpty && !_isLoading)
                        Padding(
                          padding: EdgeInsets.all(10),
                          child: Text('No transactions found'),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildBillSummary(ExtractedCreditCardBill bill) {
    final summary = bill.summary;
    if (summary == null) return SizedBox.shrink();

    final currency = bill.currencyType == CurrencyType.international
        ? Currency.usd
        : Currency.clp;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bill Summary',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            if (summary.openingBillingDate != null)
              _buildSummaryRow('Opening Date', summary.openingBillingDate!),
            if (summary.closingBillingDate != null)
              _buildSummaryRow('Closing Date', summary.closingBillingDate!),
            if (summary.paymentDueDate != null)
              _buildSummaryRow('Payment Due Date', summary.paymentDueDate!),
            if (summary.totalBilledAmount != null)
              _buildSummaryRow(
                'Total Billed',
                Amount(
                  currency: currency,
                  value: summary.totalBilledAmount!,
                ).formattedDependingOnCurrency,
              ),
            if (summary.minimumPaymentAmount != null)
              _buildSummaryRow(
                'Minimum Payment',
                Amount(
                  currency: currency,
                  value: summary.minimumPaymentAmount!,
                ).formattedDependingOnCurrency,
              ),
            if (summary.installmentBalance != null)
              _buildSummaryRow(
                'Installment Balance',
                Amount(
                  currency: currency,
                  value: summary.installmentBalance!,
                ).formattedDependingOnCurrency,
              ),
            if (summary.previousBillSummary != null) ...[
              SizedBox(height: 8),
              Divider(),
              SizedBox(height: 8),
              Text(
                'Previous Bill',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (summary.previousBillSummary!.billedAmount != null)
                _buildSummaryRow(
                  'Billed Amount',
                  Amount(
                    currency: currency,
                    value: summary.previousBillSummary!.billedAmount!,
                  ).formattedDependingOnCurrency,
                ),
              if (summary.previousBillSummary!.paidAmount != null)
                _buildSummaryRow(
                  'Paid Amount',
                  Amount(
                    currency: currency,
                    value: summary.previousBillSummary!.paidAmount!,
                  ).formattedDependingOnCurrency,
                ),
              if (summary.previousBillSummary!.finalDueAmount != null)
                _buildSummaryRow(
                  'Final Due Amount',
                  Amount(
                    currency: currency,
                    value: summary.previousBillSummary!.finalDueAmount!,
                  ).formattedDependingOnCurrency,
                ),
            ],
            if (summary.next4Months != null &&
                summary.next4Months!.isNotEmpty) ...[
              SizedBox(height: 8),
              Divider(),
              SizedBox(height: 8),
              Text(
                'Next 4 Months',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              ...summary.next4Months!.map((item) {
                return _buildSummaryRow(
                  'Month ${item.number}',
                  item.value != null
                      ? Amount(
                          currency: currency,
                          value: item.value!,
                        ).formattedDependingOnCurrency
                      : 'N/A',
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _openPdf(ExtractedCreditCardBill bill) async {
    final pdfBase64 = bill.billDocumentBase64;
    if (pdfBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF not available')),
      );
      return;
    }

    setState(() {
      _isLoadingPdf = true;
    });

    try {
      final extraction = Extraction(
        payload: bill.toJson(),
        params: {
          'productId': widget.product.providerId,
          'billPeriodId': bill.periodProviderId,
        },
        operation: ExtractionOperation.creditCardBillDetails,
      );
      log('extraction: ${extraction.toJson()}');
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/credit_card_bill_${bill.periodProviderId}.pdf',
      );
      await file.writeAsBytes(base64Decode(pdfBase64));

      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open PDF: ${result.message}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading PDF: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPdf = false;
        });
      }
    }
  }
}
