import 'package:example/models/card_brand_ext.dart';
import 'package:example/models/product_type_ext.dart';
import 'package:example/screens/bill_period_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:pan_scrapper/entities/currency.dart';
import 'package:pan_scrapper/entities/currency_type.dart';
import 'package:pan_scrapper/entities/index.dart';
import 'package:pan_scrapper/pan_scrapper_service.dart';
import 'package:pan_scrapper/presentation/widgets/loading_indicator.dart';

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
  bool _isLoadingPeriods = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPeriods();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              Text(
                'Bill periods',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: _isLoadingPeriods
                    ? null
                    : () {
                        _fetchPeriods();
                      },
                child: _isLoadingPeriods
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: const LoadingIndicator(size: 20),
                      )
                    : Text('Fetch'),
              ),
            ],
          ),
          SizedBox(height: 12),
          ..._buildPeriodTiles(
            currencyType: CurrencyType.national,
            periods: _nationalPeriods,
          ),
          if (_nationalPeriods.isEmpty && !_isLoadingPeriods)
            Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                'Tap "Fetch" to load billed periods.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
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
              Text(
                'Bill periods',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: _isLoadingPeriods
                    ? null
                    : () {
                        _fetchPeriods();
                      },
                child: _isLoadingPeriods
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: const LoadingIndicator(size: 20),
                      )
                    : Text('Fetch'),
              ),
            ],
          ),
          SizedBox(height: 12),
          ..._buildPeriodTiles(
            currencyType: CurrencyType.international,
            periods: _internationalPeriods,
          ),
          if (_internationalPeriods.isEmpty && !_isLoadingPeriods)
            Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                'Tap "Fetch" to load billed periods.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildPeriodTiles({
    required CurrencyType currencyType,
    required List<ExtractedCreditCardBillPeriod> periods,
  }) {
    final list = <Widget>[];
    // Unbilled first
    list.add(
      _buildPeriodTile(
        periodId: 'unbilled',
        label: 'Current Unbilled Period',
        currencyType: currencyType,
      ),
    );
    for (final period in periods) {
      final label = period.endDate != null
          ? '${period.startDate} - ${period.endDate}'
          : period.startDate;
      list.add(
        _buildPeriodTile(
          periodId: period.providerId,
          label: label,
          currencyType: currencyType,
        ),
      );
    }
    return list;
  }

  Widget _buildPeriodTile({
    required String periodId,
    required String label,
    required CurrencyType currencyType,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(label),
        trailing: Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BillPeriodDetailsScreen(
                service: widget.service,
                product: widget.product,
                periodId: periodId,
                currencyType: currencyType,
                periodLabel: label,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _fetchPeriods() async {
    setState(() {
      _isLoadingPeriods = true;
    });
    try {
      final periods = await widget.service.getCreditCardBillPeriods(
        widget.product.providerId,
      );
      if (mounted) {
        setState(() {
          _nationalPeriods = periods
              .where((p) => p.currencyType == CurrencyType.national)
              .toList();
          _internationalPeriods = periods
              .where((p) => p.currencyType == CurrencyType.international)
              .toList();
          _isLoadingPeriods = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPeriods = false;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }
}
