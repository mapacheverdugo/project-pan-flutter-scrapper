import 'package:example/models/access_credentials.dart';
import 'package:example/models/card_brand_ext.dart';
import 'package:example/models/product_type_ext.dart';
import 'package:flutter/material.dart';
import 'package:pan_scrapper/models/index.dart';
import 'package:pan_scrapper/pan_scrapper_service.dart';

class CreditCardDetailsScreen extends StatefulWidget {
  const CreditCardDetailsScreen({
    super.key,
    required this.service,
    required this.credentials,
    required this.product,
  });

  final PanScrapperService service;
  final AccessCredentials credentials;
  final Product product;

  @override
  State<CreditCardDetailsScreen> createState() =>
      _CreditCardDetailsScreenState();
}

class _CreditCardDetailsScreenState extends State<CreditCardDetailsScreen>
    with SingleTickerProviderStateMixin {
  List<CreditCardBillPeriod> _nationalPeriods = [];
  List<CreditCardBillPeriod> _internationalPeriods = [];

  late TabController _tabController;
  String? _selectedNationalPeriodId;
  String? _selectedInternationalPeriodId;
  List<Transaction> _nationalTransactions = [];
  List<Transaction> _internationalTransactions = [];
  bool _isLoadingNationalTransactions = false;
  bool _isLoadingInternationalTransactions = false;
  int _previousTabIndex = 0;

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
          widget.product.availableAmount?.formattedDependingOnCurrency ??
              'null',
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
                        value: period.id,
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
          if (_nationalTransactions.isNotEmpty)
            ..._nationalTransactions.map((transaction) {
              return Card(
                margin: EdgeInsets.only(bottom: 10),
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
                        'Amount: ${transaction.amount.formattedDependingOnCurrency}',
                      ),
                      if (transaction.transactionDate != null)
                        Text('Date: ${transaction.transactionDate}'),
                      Text('Type: ${transaction.type.name}'),
                    ],
                  ),
                ),
              );
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
                        value: period.id,
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
          if (_internationalTransactions.isNotEmpty)
            ..._internationalTransactions.map((transaction) {
              return Card(
                margin: EdgeInsets.only(bottom: 10),
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
                        'Amount: ${transaction.amount.formattedDependingOnCurrency} ${transaction.amount.currency}',
                      ),
                      if (transaction.transactionDate != null)
                        Text('Date: ${transaction.transactionDate}'),
                      Text('Type: ${transaction.type.name}'),
                    ],
                  ),
                ),
              );
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
        widget.credentials.resultCredentials,
        widget.product.id,
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
              widget.credentials.resultCredentials,
              widget.product.id,
              CurrencyType.national,
            );
        setState(() {
          _isLoadingNationalTransactions = false;
          _nationalTransactions = unbilledTransactions;
        });
      }

      final bill = await widget.service.getCreditCardBill(
        widget.credentials.resultCredentials,
        widget.product.id,
        _selectedNationalPeriodId!,
      );
      setState(() {
        _isLoadingNationalTransactions = false;
        _nationalTransactions = bill.transactions;
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
              widget.credentials.resultCredentials,
              widget.product.id,
              CurrencyType.international,
            );
        setState(() {
          _isLoadingInternationalTransactions = false;
          _internationalTransactions = unbilledTransactions;
        });
        return;
      }

      final bill = await widget.service.getCreditCardBill(
        widget.credentials.resultCredentials,
        widget.product.id,
        _selectedInternationalPeriodId!,
      );
      setState(() {
        _isLoadingInternationalTransactions = false;
        _internationalTransactions = bill.transactions;
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
}
