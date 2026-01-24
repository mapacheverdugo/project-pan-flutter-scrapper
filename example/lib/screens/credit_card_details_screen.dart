import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:example/models/card_brand_ext.dart';
import 'package:example/models/product_type_ext.dart';
import 'package:example/widget/transaction_list_item.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:pan_scrapper/entities/currency.dart';
import 'package:pan_scrapper/entities/extraction.dart';
import 'package:pan_scrapper/entities/extraction_operation.dart';
import 'package:pan_scrapper/entities/index.dart';
import 'package:pan_scrapper/pan_scrapper_service.dart';
import 'package:path_provider/path_provider.dart';

class CreditCardDetailsScreen extends StatefulWidget {
  const CreditCardDetailsScreen({
    super.key,
    required this.service,
    required this.product,
  });

  final PanScrapperService service;
  final ExtractedProductModel product;

  @override
  State<CreditCardDetailsScreen> createState() =>
      _CreditCardDetailsScreenState();
}

class _CreditCardDetailsScreenState extends State<CreditCardDetailsScreen>
    with SingleTickerProviderStateMixin {
  List<ExtractedCreditCardBillPeriod> _nationalPeriods = [];
  List<ExtractedCreditCardBillPeriod> _internationalPeriods = [];

  late TabController _tabController;
  String? _selectedNationalPeriodId;
  String? _selectedInternationalPeriodId;
  List<ExtractedTransactionWithoutProviderId> _nationalTransactions = [];
  List<ExtractedTransactionWithoutProviderId> _internationalTransactions = [];
  bool _isLoadingNationalTransactions = false;
  bool _isLoadingInternationalTransactions = false;
  int _previousTabIndex = 0;
  ExtractedCreditCardBill? _nationalBill;
  ExtractedCreditCardBill? _internationalBill;
  bool _isLoadingPdf = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    // Defer the fetch to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPeriods();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      // Tab change completed
      if (_previousTabIndex != _tabController.index) {
        // Clear transactions when tab changes
        setState(() {
          if (_tabController.index == 0) {
            _internationalTransactions = [];
          } else {
            _nationalTransactions = [];
          }
          _previousTabIndex = _tabController.index;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              SliverAppBar(
                title: Text(widget.product.name),
                pinned: true,
                floating: false,
                bottom: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'National'),
                    Tab(text: 'International'),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(
                          'Product Details',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      _buildProductPropertiesTable(),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [_buildNationalTab(), _buildInternationalTab()],
          ),
        ),
      ),
    );
  }

  Widget _buildProductPropertiesTable() {
    final product = widget.product;
    return Table(
      children: <TableRow>[
        _buildTableRow('ID', product.providerId),
        _buildTableRow('Number', widget.product.number),
        _buildTableRow('Name', product.name, isOdd: true),
        _buildTableRow('Type', product.type.label),
        _buildTableRow(
          'Card Brand',
          product.cardBrand?.label ?? 'null',
          isOdd: true,
        ),
        _buildTableRow('Card Last 4 Digits', product.cardLast4Digits ?? 'null'),
        _buildTableRow(
          'Available Amount',
          product.availableAmount?.formattedDependingOnCurrency ?? 'null',
          isOdd: true,
        ),
        for (final ExtractedCreditBalance creditBalance
            in product.creditBalances ?? []) ...[
          _buildTableRow(
            'Credit Balance ${creditBalance.currency.isoLetters}',
            creditBalance.availableAmountModel.formattedDependingOnCurrency,
            isOdd: product.creditBalances!.indexOf(creditBalance) % 2 != 0,
          ),
        ],
      ],
    );
  }

  TableRow _buildTableRow(String label, String value, {bool isOdd = false}) {
    return TableRow(
      decoration: BoxDecoration(
        color: isOdd ? Colors.grey[200] : Colors.transparent,
      ),
      children: [
        Padding(
          padding: EdgeInsets.all(8),
          child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(padding: EdgeInsets.all(8), child: Text(value)),
      ],
    );
  }

  Widget _buildNationalTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedNationalPeriodId,
                  hint: Text('Select period'),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem<String>(
                      value: 'unbilled',
                      child: Text('Current Unbilled Period'),
                    ),
                    ..._nationalPeriods.map((period) {
                      return DropdownMenuItem<String>(
                        value: period.providerId,
                        child: Text(
                          '${period.startDate}${period.endDate != null ? ' - ${period.endDate}' : ''}',
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedNationalPeriodId = value;
                      _nationalTransactions = [];
                      _nationalBill = null;
                    });
                  },
                ),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed:
                    _selectedNationalPeriodId == null ||
                        _isLoadingNationalTransactions
                    ? null
                    : () {
                        _fetchNationalTransactions();
                      },
                child: _isLoadingNationalTransactions
                    ? Container(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(),
                      )
                    : Text('Fetch'),
              ),
            ],
          ),
          SizedBox(height: 20),
          if (_nationalBill != null) _buildBillSummary(_nationalBill!),
          if (_nationalBill != null) SizedBox(height: 20),
          if (_nationalBill != null && _selectedNationalPeriodId != 'unbilled')
            ElevatedButton.icon(
              onPressed: _isLoadingPdf ? null : () => _openPdf(_nationalBill!),
              icon: _isLoadingPdf
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.picture_as_pdf),
              label: Text('Open PDF'),
            ),
          if (_nationalBill != null) SizedBox(height: 20),
          if (_nationalTransactions.isNotEmpty)
            ..._nationalTransactions.map((transaction) {
              return TransactionListItem(transaction: transaction);
            }),
          if (_nationalTransactions.isEmpty &&
              !_isLoadingNationalTransactions &&
              _selectedNationalPeriodId != null)
            Padding(
              padding: EdgeInsets.all(10),
              child: Text('No transactions found'),
            ),
        ],
      ),
    );
  }

  Widget _buildInternationalTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedInternationalPeriodId,
                  hint: Text('Select period'),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem<String>(
                      value: 'unbilled',
                      child: Text('Current Unbilled Period'),
                    ),
                    ..._internationalPeriods.map((period) {
                      return DropdownMenuItem<String>(
                        value: period.providerId,
                        child: Text(
                          '${period.startDate}${period.endDate != null ? ' - ${period.endDate}' : ''}',
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedInternationalPeriodId = value;
                      _internationalTransactions = [];
                      _internationalBill = null;
                    });
                  },
                ),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed:
                    _selectedInternationalPeriodId == null ||
                        _isLoadingInternationalTransactions
                    ? null
                    : () {
                        _fetchInternationalTransactions();
                      },
                child: _isLoadingInternationalTransactions
                    ? Container(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(),
                      )
                    : Text('Fetch'),
              ),
            ],
          ),
          SizedBox(height: 20),
          if (_internationalBill != null)
            _buildBillSummary(_internationalBill!),
          if (_internationalBill != null) SizedBox(height: 20),
          if (_internationalBill != null &&
              _selectedInternationalPeriodId != 'unbilled')
            ElevatedButton.icon(
              onPressed: _isLoadingPdf
                  ? null
                  : () => _openPdf(_internationalBill!),
              icon: _isLoadingPdf
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.picture_as_pdf),
              label: Text('Open PDF'),
            ),
          if (_internationalBill != null) SizedBox(height: 20),
          if (_internationalTransactions.isNotEmpty)
            ..._internationalTransactions.map((transaction) {
              return TransactionListItem(transaction: transaction);
            }),
          if (_internationalTransactions.isEmpty &&
              !_isLoadingInternationalTransactions &&
              _selectedInternationalPeriodId != null)
            Padding(
              padding: EdgeInsets.all(10),
              child: Text('No transactions found'),
            ),
        ],
      ),
    );
  }

  Future<void> _fetchPeriods() async {
    try {
      final periods = await widget.service.getCreditCardBillPeriods(
        widget.product.providerId,
      );
      setState(() {
        _nationalPeriods = periods
            .where((p) => p.currencyType == CurrencyType.national)
            .toList();
        _internationalPeriods = periods
            .where((p) => p.currencyType == CurrencyType.international)
            .toList();
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _fetchNationalTransactions() async {
    if (_selectedNationalPeriodId == null) return;

    setState(() {
      _isLoadingNationalTransactions = true;
    });
    try {
      // Handle unbilled period - for now, we'll skip it or show a message
      if (_selectedNationalPeriodId == 'unbilled') {
        final unbilledTransactions = await widget.service
            .getCreditCardUnbilledTransactions(
              widget.product.providerId,
              CurrencyType.national,
            );
        setState(() {
          _isLoadingNationalTransactions = false;
          _nationalTransactions = unbilledTransactions;
        });
      }

      final bill = await widget.service.getCreditCardBill(
        widget.product.providerId,
        _selectedNationalPeriodId!,
      );
      setState(() {
        _isLoadingNationalTransactions = false;
        _nationalTransactions = bill.transactions ?? [];
        _nationalBill = bill;
      });
    } catch (e) {
      setState(() {
        _isLoadingNationalTransactions = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _fetchInternationalTransactions() async {
    if (_selectedInternationalPeriodId == null) return;

    setState(() {
      _isLoadingInternationalTransactions = true;
    });
    try {
      // Handle unbilled period - for now, we'll skip it or show a message
      if (_selectedInternationalPeriodId == 'unbilled') {
        final unbilledTransactions = await widget.service
            .getCreditCardUnbilledTransactions(
              widget.product.providerId,
              CurrencyType.international,
            );
        setState(() {
          _isLoadingInternationalTransactions = false;
          _internationalTransactions = unbilledTransactions;
        });
        return;
      }

      final bill = await widget.service.getCreditCardBill(
        widget.product.providerId,
        _selectedInternationalPeriodId!,
      );
      setState(() {
        _isLoadingInternationalTransactions = false;
        _internationalTransactions = bill.transactions ?? [];
        _internationalBill = bill;
      });
    } catch (e) {
      setState(() {
        _isLoadingInternationalTransactions = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
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
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
        SnackBar(content: Text('PDF not available for unbilled period')),
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
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/credit_card_bill_${bill.periodProviderId}.pdf',
      );
      await file.writeAsBytes(base64Decode(pdfBase64));

      // Open the file
      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to open PDF: ${result.message}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading PDF: $e')));
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
