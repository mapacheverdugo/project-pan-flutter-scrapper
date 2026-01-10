import 'package:flutter/material.dart';
import 'package:pan_scrapper/constants/strings.dart';
import 'package:pan_scrapper/presentation/controllers/connection_notifier.dart';
import 'package:pan_scrapper/presentation/widgets/default_button.dart';
import 'package:pan_scrapper/presentation/widgets/product_card.dart';

class ConnectionSelectProductsView extends StatefulWidget {
  const ConnectionSelectProductsView({super.key});

  @override
  State<ConnectionSelectProductsView> createState() =>
      _ConnectionSelectProductsViewState();
}

class _ConnectionSelectProductsViewState
    extends State<ConnectionSelectProductsView> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ConnectionProvider.of(context),
      builder: (context, _) {
        final connectionNotifier = ConnectionProvider.of(context);
        final products = connectionNotifier.value.products;
        final selectedProductIds = connectionNotifier.value.selectedProductIds;
        final institution = connectionNotifier.value.selectedInstitution;
        final institutionName = institution?.name;
        final clientName = connectionNotifier.value.linkIntent.clientName;

        return CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Seleccionar cuentas',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$productName compartirá con $clientName solamente la información de los productos de $institutionName que selecciones.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  Column(
                    spacing: 12,
                    children: [
                      ...products.map((product) {
                        final isSelected = selectedProductIds.contains(
                          product.id,
                        );
                        return ProductCard(
                          product: product,
                          isSelected: isSelected,
                          onSelected: ({required bool isSelected}) {
                            final currentSelected = List<String>.from(
                              selectedProductIds,
                            );
                            if (isSelected) {
                              if (!currentSelected.contains(product.id)) {
                                currentSelected.add(product.id);
                              }
                            } else {
                              currentSelected.remove(product.id);
                            }
                            connectionNotifier.setSelectedProductIds(
                              currentSelected,
                            );
                          },
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: DefaultButton(
                      text: 'Continuar',
                      size: DefaultButtonSize.lg,
                      onPressed: selectedProductIds.isNotEmpty
                          ? () {
                              // TODO: Handle product selection
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
