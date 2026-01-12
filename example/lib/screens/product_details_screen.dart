import 'package:example/widget/period_card.dart';
import 'package:flutter/material.dart';
import 'package:pan_scrapper/entities/index.dart';
import 'package:pan_scrapper/pan_scrapper_service.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({
    super.key,
    required this.service,
    required this.product,
  });

  final PanScrapperService service;
  final ExtractedProductModel product;
  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  List<ExtractedTransactionWithoutProviderId> _transactions = [];
  List<ExtractedCreditCardBillPeriod> _periods = [];
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
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _transactions[index].description,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Amount: ${_transactions[index].amount.formattedDependingOnCurrency} ${_transactions[index].amount.currency}',
                              ),
                              if (_transactions[index].transactionDate != null)
                                Text(
                                  'Date: ${_transactions[index].transactionDate}',
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
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
        _buildTableRow('ID', widget.product.providerId),
        _buildTableRow('Number', widget.product.number),
        _buildTableRow('Name', widget.product.name),
        _buildTableRow(
          'Card Last 4 Digits',
          widget.product.cardLast4Digits ?? 'null',
        ),
        _buildTableRow(
          'Available Amount',
          widget.product.availableAmount != null
              ? '${widget.product.availableAmount!.formattedDependingOnCurrency} ${widget.product.availableAmount!.currency}'
              : 'null',
        ),
        _buildTableRow(
          'Credit Balances',
          widget.product.creditBalances != null
              ? widget.product.creditBalances!.length.toString()
              : 'null',
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
          .getDepositaryAccountTransactions(widget.product.providerId);
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
        widget.product.providerId,
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
