import 'package:example/models/access_credentials.dart';
import 'package:example/models/institution_ext.dart';
import 'package:example/widget/code_block.dart';
import 'package:example/widget/product_card.dart';
import 'package:flutter/material.dart';
import 'package:pan_scrapper/models/index.dart';
import 'package:pan_scrapper/pan_scrapper_service.dart';

class ConnectionDetailsScreen extends StatefulWidget {
  const ConnectionDetailsScreen({
    super.key,
    required this.service,
    required this.credentials,
  });

  final PanScrapperService service;
  final AccessCredentials credentials;

  @override
  State<ConnectionDetailsScreen> createState() =>
      _ConnectionDetailsScreenState();
}

class _ConnectionDetailsScreenState extends State<ConnectionDetailsScreen> {
  List<Product> _products = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.credentials.username} - ${widget.service.institution.label}',
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
                  'Credentials',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              CodeBlock(text: widget.credentials.resultCredentials),
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
                    return ProductCard(
                      product: _products[index],
                      service: widget.service,
                      credentials: widget.credentials,
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
      final newProducts = await widget.service.getProducts(
        widget.credentials.resultCredentials,
      );
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
