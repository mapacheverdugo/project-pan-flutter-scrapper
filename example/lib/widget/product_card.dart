import 'package:example/models/access_credentials.dart';
import 'package:example/models/card_brand_ext.dart';
import 'package:example/models/product_type_ext.dart';
import 'package:example/screens/credit_card_details_screen.dart';
import 'package:example/screens/product_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:pan_scrapper/models/index.dart';
import 'package:pan_scrapper/pan_scrapper_service.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final PanScrapperService service;
  final AccessCredentials credentials;

  const ProductCard({
    super.key,
    required this.product,
    required this.service,
    required this.credentials,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          final isCreditCard = product.type == ProductType.creditCard;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => isCreditCard
                  ? CreditCardDetailsScreen(
                      service: service,
                      credentials: credentials,
                      product: product,
                    )
                  : ProductDetailsScreen(
                      service: service,
                      credentials: credentials,
                      product: product,
                    ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.id),
              Text(
                product.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),

              Row(
                children: [
                  Text(product.type.label),
                  if (product.cardLast4Digits == null) ...[
                    Text(" (${product.number}) "),
                  ],
                  if (product.cardBrand != null) ...[
                    Text(' (${product.cardBrand?.label}) '),
                  ],
                  if (product.cardLast4Digits != null) ...[
                    Text(' **** ${product.cardLast4Digits}'),
                  ],
                ],
              ),

              if (product.availableAmount != null) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text(
                      'Disponible: ${product.availableAmount?.formattedDependingOnCurrency}',
                    ),
                  ],
                ),
              ],
              for (final creditBalance in product.creditBalances ?? []) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text('Balance ${creditBalance.currency.isoLetters}:'),
                    Text(
                      'Cupo: ${creditBalance.creditLimitAmount.formattedDependingOnCurrency}',
                    ),
                    Text(
                      'Disponible: ${creditBalance.availableAmount.formattedDependingOnCurrency}',
                    ),
                    Text(
                      'Utilizado: ${creditBalance.usedAmount.formattedDependingOnCurrency}',
                    ),
                    SizedBox(height: 4),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
