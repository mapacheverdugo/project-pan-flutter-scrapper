import 'package:flutter/material.dart';
import 'package:pan_scrapper/constants/strings.dart';
import 'package:pan_scrapper/presentation/controllers/connection_notifier.dart';
import 'package:pan_scrapper/presentation/widgets/default_button.dart';
import 'package:pan_scrapper/presentation/widgets/product_card.dart';

class ConnectionSelectProductsView extends StatefulWidget {
  const ConnectionSelectProductsView({
    super.key,
    required this.onContinue,
    this.forceAllSelected = true,
  });

  final Function(List<String> productIds) onContinue;
  final bool forceAllSelected;

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
        final isLoading = connectionNotifier.value.isLoading;

        return CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.forceAllSelected
                        ? 'Confirmar cuentas'
                        : 'Seleccionar cuentas',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.forceAllSelected
                        ? '$productName compartirá con $clientName la información de los siguiente productos de $institutionName.'
                        : '$productName compartirá con $clientName solamente la información de los productos de $institutionName que selecciones.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  Column(
                    spacing: 12,
                    children: [
                      ...products.map((product) {
                        final isSelected = selectedProductIds.contains(
                          product.providerId,
                        );
                        return ProductCard(
                          product: product,
                          isSelected: isSelected,
                          isSelectable: !widget.forceAllSelected,
                          onSelected: !isLoading && !widget.forceAllSelected
                              ? ({required bool isSelected}) {
                                  final currentSelected = List<String>.from(
                                    selectedProductIds,
                                  );
                                  if (isSelected) {
                                    if (!currentSelected.contains(
                                      product.providerId,
                                    )) {
                                      currentSelected.add(product.providerId);
                                    }
                                  } else {
                                    currentSelected.remove(product.providerId);
                                  }
                                  connectionNotifier.setSelectedProductIds(
                                    currentSelected,
                                  );
                                }
                              : null,
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
                      isLoading: isLoading,
                      size: DefaultButtonSize.lg,
                      onPressed: selectedProductIds.isNotEmpty
                          ? () {
                              widget.onContinue(selectedProductIds);
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
