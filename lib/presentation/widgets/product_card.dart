import 'package:flutter/material.dart';
import 'package:pan_scrapper/entities/product.dart';
import 'package:pan_scrapper/entities/product_type.dart';
import 'package:pan_scrapper/presentation/widgets/default_card.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final bool isSelected;
  final Function({required bool isSelected}) onSelected;

  const ProductCard({
    super.key,
    required this.product,
    required this.isSelected,
    required this.onSelected,
  });

  String get _lastFourDigits =>
      product.cardLast4Digits ??
      (product.number.length > 4
          ? product.number.substring(product.number.length - 4)
          : product.number);

  String get _productDisplayName => '${product.name} · $_lastFourDigits';

  String? get _productBalances {
    final availableAmount = product.availableAmount;
    if (availableAmount != null) {
      return availableAmount.formattedDependingOnCurrency;
    }
    final creditBalances = product.creditBalances;
    if (creditBalances != null && creditBalances.isNotEmpty) {
      return creditBalances
          .map(
            (creditBalance) =>
                creditBalance.availableAmount.formattedDependingOnCurrency,
          )
          .join(' | ');
    }
    return null;
  }

  String get _productType => switch (product.type) {
    ProductType.depositaryAccount => 'Cuenta corriente',
    ProductType.depositaryAccountCreditLine => 'Línea de crédito',
    ProductType.creditCard => 'Tarjeta de crédito',
    ProductType.unknown => 'Producto desconocido',
  };

  @override
  Widget build(BuildContext context) {
    return DefaultCard(
      backgroundColor: Theme.of(context).colorScheme.surface,
      borderColor: isSelected ? Theme.of(context).colorScheme.primary : null,
      onTap: () {
        onSelected(isSelected: !isSelected);
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,

              onChanged: (value) {
                onSelected(isSelected: !isSelected);
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _productType,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _productDisplayName,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (_productBalances != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _productBalances!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
