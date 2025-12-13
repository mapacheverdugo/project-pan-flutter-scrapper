import 'package:flutter/material.dart';
import 'package:pan_scrapper/models/product.dart';
import 'package:pan_scrapper/models/product_type.dart';

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
            Text(
              product.name,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),

            if (product.type == ProductType.creditCard) ...[
              Row(
                children: [
                  Text(
                    'Tarjeta ${product.cardLast4Digits ?? ''} ${product.cardBrand?.name ?? ''} ',
                  ),
                ],
              ),
            ],
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
