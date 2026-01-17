import 'package:example/screens/credit_card_details_screen.dart';
import 'package:example/screens/product_details_screen.dart';
import 'package:example/widget/product_card.dart';
import 'package:flutter/material.dart';
import 'package:pan_scrapper/entities/index.dart';
import 'package:pan_scrapper/entities/local_connection.dart';
import 'package:pan_scrapper/pan_connect.dart';
import 'package:pan_scrapper/pan_scrapper_service.dart';

class ConnectionDetailsScreen extends StatefulWidget {
  const ConnectionDetailsScreen({
    super.key,
    required this.connection,
    required this.publicKey,
  });

  final LocalConnection connection;
  final String publicKey;

  @override
  State<ConnectionDetailsScreen> createState() =>
      _ConnectionDetailsScreenState();
}

class _ConnectionDetailsScreenState extends State<ConnectionDetailsScreen> {
  List<ExtractedProductModel> _products = [];
  bool _isLoading = false;
  final TextEditingController _linkTokenController = TextEditingController();

  late final PanScrapperService service = PanScrapperService(
    context: context,
    connection: widget.connection,
  );

  @override
  void dispose() {
    _linkTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.connection.rawUsername} - ${widget.connection.institutionCode.name}',
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(10),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(
                  'Connection',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              TextField(
                controller: _linkTokenController,
                decoration: InputDecoration(
                  labelText: 'Link Token',
                  border: OutlineInputBorder(),
                  hintText: 'Enter your link token',
                ),
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text(
                  'Connection ID: ${widget.connection.id}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                contentPadding: EdgeInsets.zero,
                trailing: ElevatedButton(
                  onPressed: () {
                    final linkToken = _linkTokenController.text.trim();
                    if (linkToken.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link Token is required')),
                      );
                      return;
                    }
                    PanConnect.syncLocalConnection(linkToken, widget.publicKey);
                  },
                  child: Text('Sync'),
                ),
              ),
              SizedBox(height: 10),
              ListTile(
                title: Text(
                  'Products',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                contentPadding: EdgeInsets.zero,
                trailing: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          _fetchProducts();
                        },
                  child: _isLoading
                      ? Container(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(),
                        )
                      : Text('Fetch'),
                ),
              ),
              if (_products.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return ProductCard(
                      product: product,
                      onTap: () {
                        final isCreditCard =
                            product.type == ProductType.creditCard;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => isCreditCard
                                ? CreditCardDetailsScreen(
                                    service: service,
                                    product: product,
                                  )
                                : ProductDetailsScreen(
                                    service: service,
                                    product: product,
                                  ),
                          ),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final newProducts = await service.getProducts();
      setState(() {
        _isLoading = false;
        _products = newProducts;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}
