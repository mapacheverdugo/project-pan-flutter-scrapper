import 'package:example/models/card_brand_ext.dart';
import 'package:example/models/product_type_ext.dart';
import 'package:flutter/material.dart';
import 'package:pan_scrapper/models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.number),
            Text(product.name, style: Theme.of(context).textTheme.titleMedium),

            Row(
              children: [
                Text(product.type.label),
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
                    'Disponible: ${product.availableAmount?.amount.toString()}',
                  ),
                ],
              ),
            ],
            for (final creditBalance in product.creditBalances ?? []) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text('Balance ${creditBalance.currency}:'),
                  Text('Cupo: ${creditBalance.creditLimitAmount.toString()}'),
                  Text(
                    'Disponible: ${creditBalance.availableAmount.toString()}',
                  ),
                  Text('Utilizado: ${creditBalance.usedAmount.toString()}'),
                  SizedBox(height: 4),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
