import 'package:example/models/access_credentials.dart';
import 'package:example/models/card_brand_ext.dart';
import 'package:example/models/product_type_ext.dart';
import 'package:example/widget/period_card.dart';
import 'package:flutter/material.dart';
import 'package:pan_scrapper/models/index.dart';
import 'package:pan_scrapper/pan_scrapper_service.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({
    super.key,
    required this.service,
    required this.credentials,
    required this.product,
  });

  final PanScrapperService service;
  final AccessCredentials credentials;
  final Product product;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  List<Transaction> _transactions = [];
  List<CreditCardBillPeriod> _periods = [];
  bool _isLoadingTransactions = false;
  bool _isLoadingPeriods = false;

  @override
  Widget build(BuildContext context) {
    final isCreditCard = widget.product.type == ProductType.creditCard;
    final isDepositaryAccount =
        widget.product.type == ProductType.depositaryAccount ||
        widget.product.type == ProductType.depositaryAccountCreditLine;

    return Scaffold(
      appBar: AppBar(title: Text(widget.product.name)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(10),
        child: SafeArea(
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
              SizedBox(height: 20),
              if (isDepositaryAccount) ...[
                ListTile(
                  title: Text(
                    'Transactions',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  contentPadding: EdgeInsets.zero,
                  trailing: ElevatedButton(
                    onPressed: _isLoadingTransactions
                        ? null
                        : () {
                            _fetchTransactions();
                          },
                    child: _isLoadingTransactions
                        ? Container(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(),
                          )
                        : Text('Fetch'),
                  ),
                ),
                if (_transactions.isNotEmpty)
                  ..._transactions.take(5).map((transaction) {
                    return Card(
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transaction.description,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Amount: ${transaction.amount.amount} ${transaction.amount.currency}',
                            ),
                            if (transaction.transactionDate != null)
                              Text('Date: ${transaction.transactionDate}'),
                            Text('Type: ${transaction.type.name}'),
                            if (transaction.creditDebit != null)
                              Text(
                                'Credit/Debit: ${transaction.creditDebit!.name}',
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                if (_transactions.isEmpty && !_isLoadingTransactions)
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: Text('No transactions found'),
                  ),
              ],
              if (isCreditCard) ...[
                ListTile(
                  title: Text(
                    'Bill Periods',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  contentPadding: EdgeInsets.zero,
                  trailing: ElevatedButton(
                    onPressed: _isLoadingPeriods
                        ? null
                        : () {
                            _fetchPeriods();
                          },
                    child: _isLoadingPeriods
                        ? Container(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(),
                          )
                        : Text('Fetch'),
                  ),
                ),
                if (_periods.isNotEmpty)
                  ..._periods.map((period) {
                    return PeriodCard(period: period);
                  }),
                if (_periods.isEmpty && !_isLoadingPeriods)
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: Text('No periods found'),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductPropertiesTable() {
    return Table(
      border: TableBorder.all(),
      children: [
        _buildTableRow('ID', widget.product.id),
        _buildTableRow('Number', widget.product.number),
        _buildTableRow('Name', widget.product.name),
        _buildTableRow('Type', widget.product.type.label),
        _buildTableRow('Card Brand', widget.product.cardBrand?.label ?? 'null'),
        _buildTableRow(
          'Card Last 4 Digits',
          widget.product.cardLast4Digits ?? 'null',
        ),
        _buildTableRow(
          'Available Amount',
          widget.product.availableAmount != null
              ? '${widget.product.availableAmount!.amount} ${widget.product.availableAmount!.currency}'
              : 'null',
        ),
        _buildTableRow(
          'Credit Balances',
          widget.product.creditBalances != null
              ? widget.product.creditBalances!.length.toString()
              : 'null',
        ),
        _buildTableRow(
          'Is For Secondary Card Holder',
          widget.product.isForSecondaryCardHolder.toString(),
        ),
      ],
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.all(8),
          child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(padding: EdgeInsets.all(8), child: Text(value)),
      ],
    );
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoadingTransactions = true;
    });
    try {
      final transactions = await widget.service
          .getDepositaryAccountTransactions(
            widget.credentials.resultCredentials,
            widget.product.number,
          );
      setState(() {
        _isLoadingTransactions = false;
        _transactions = transactions;
      });
    } catch (e) {
      setState(() {
        _isLoadingTransactions = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _fetchPeriods() async {
    setState(() {
      _isLoadingPeriods = true;
    });
    try {
      final periods = await widget.service.getCreditCardBillPeriods(
        widget.credentials.resultCredentials,
        widget.product.id,
      );
      setState(() {
        _isLoadingPeriods = false;
        _periods = periods;
      });
    } catch (e) {
      setState(() {
        _isLoadingPeriods = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}
