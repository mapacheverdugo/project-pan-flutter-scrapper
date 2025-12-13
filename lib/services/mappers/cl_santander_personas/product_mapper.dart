import 'package:collection/collection.dart';
import 'package:pan_scrapper/helpers/amount_helpers.dart';
import 'package:pan_scrapper/helpers/string_helpers.dart';
import 'package:pan_scrapper/models/available_amount.dart';
import 'package:pan_scrapper/models/card_brand.dart';
import 'package:pan_scrapper/models/credit_balance.dart';
import 'package:pan_scrapper/models/product.dart';
import 'package:pan_scrapper/models/product_type.dart';
import 'package:pan_scrapper/services/models/cl_santander_personas/index.dart';

class ClSantanderPersonasProductMapper {
  static ProductType _getProductType(String agrupacionComercial) {
    switch (agrupacionComercial) {
      case 'TCR':
        return ProductType.creditCard;
      case 'LCR':
        return ProductType.depositaryAccountCreditLine;
      case 'CCC':
        return ProductType.depositaryAccount;
      default:
        return ProductType.depositaryAccount;
    }
  }

  static List<Product> fromProductsResponseAndCardResponse(
    ClSantanderPersonasProductsResponse productsResponse,
    ClSantanderPersonasCardResponse cardResponse,
  ) {
    try {
      final productList = <Product>[];

      final e1 = productsResponse.data?.output?.matrices?.matrizcaptaciones?.e1;
      if (e1 != null && e1.isNotEmpty) {
        // Group products by productId
        final groupedProducts = <String, _GrouppedProduct>{};

        for (final product in e1) {
          final numerocontrato = product.numerocontrato;
          final producto = product.producto;
          final subproducto = product.subproducto;
          final oficinacontrato = product.oficinacontrato;

          // Find matching card
          final cards = cardResponse
              .data
              ?.conTarjetasRutResponse
              ?.output
              ?.detalleConsultaTarjetas;
          ClSantanderPersonasCardDetalleConsultaTarjeta? card;

          card = cards?.firstWhereOrNull(
            (card) => card.contrato == numerocontrato,
          );

          final productId = createProductId(
            rawContractId: numerocontrato,
            rawProductId: producto,
            rawSubProductId: subproducto,
            rawCenterId: oficinacontrato,
            rawEntityId: card?.entidad,
          );

          if (groupedProducts.containsKey(productId)) {
            groupedProducts[productId]!.products.add(product);
          } else {
            groupedProducts[productId] = _GrouppedProduct(
              products: [product],
              card: card,
            );
          }
        }

        // Process grouped products
        groupedProducts.forEach((productId, productsCard) {
          final products = productsCard.products;
          final card = productsCard.card;

          if (products.isEmpty) return;

          final agrupacionComercial = products.first.agrupacioncomercial;

          if (agrupacionComercial == 'TCR' && card != null) {
            final creditBalances = <CreditBalance>[];

            for (final product in products) {
              final currency = product.codigomoneda;
              final options = currency == 'CLP'
                  ? _nationalOptions
                  : _internationalOptions;

              final creditLimitAmount = Amount.parse(
                product.cupo,
                options,
              ).value;
              final availableAmount = Amount.parse(
                product.montodisponible,
                options,
              ).value;

              final usedAmount = Amount.parse(
                product.montoutilizado,
                options,
              ).value;

              if (creditLimitAmount != 0 && currency != null) {
                creditBalances.add(
                  CreditBalance(
                    creditLimitAmount: creditLimitAmount!.toInt(),
                    availableAmount: availableAmount!.toInt(),
                    usedAmount: usedAmount!.toInt(),
                    currency: currency,
                  ),
                );
              }
            }

            final numeroPan = products.first.numeropan;
            final glosaCorta = products.first.glosacorta;

            productList.add(
              Product(
                number: productId,
                name: titleCase(
                  glosaCorta?.toLowerCase() ?? card.glosaProducto ?? '',
                ),
                type: _getProductType(agrupacionComercial),
                cardBrand: CardBrand.other,
                cardLast4Digits: numeroPan.length >= 4
                    ? numeroPan.substring(numeroPan.length - 4)
                    : numeroPan,
                creditBalances: creditBalances,
                isForSecondaryCardHolder: false,
              ),
            );
          } else {
            // Depositary product
            final glosaCorta = products.first.glosacorta;

            final currency = products.first.codigomoneda;
            final options = currency == 'CLP'
                ? _nationalOptions
                : _internationalOptions;
            final montoDisponible = Amount.parse(
              products.first.montodisponible!,
              options,
            ).value;

            ProductType productType = _getProductType(agrupacionComercial);

            productList.add(
              Product(
                number: productId,
                name: titleCase(glosaCorta?.toLowerCase() ?? ''),
                type: productType,
                availableAmount: AvailableAmount(
                  amount: montoDisponible!.toInt(),
                  currency: currency ?? 'CLP',
                ),
                creditBalances: [],
                isForSecondaryCardHolder: false,
              ),
            );
          }
        });
      }

      return productList;
    } catch (e) {
      rethrow;
    }
  }

  static String createProductId({
    required String rawContractId,
    required String rawProductId,
    required String rawSubProductId,
    required String rawCenterId,
    String? rawEntityId,
  }) {
    var id =
        '${rawContractId}_${rawProductId}_${rawSubProductId}_${rawCenterId}';

    if (rawEntityId != null && rawEntityId.isNotEmpty) {
      id = '${id}_${rawEntityId}';
    }

    return id;
  }

  static ClSantanderPersonasProductIdMetadata parseProductId(String productId) {
    final parts = productId.split('_');
    return ClSantanderPersonasProductIdMetadata(
      rawContractId: parts.length > 0 ? parts[0] : '',
      rawProductId: parts.length > 1 ? parts[1] : '',
      rawSubProductId: parts.length > 2 ? parts[2] : '',
      rawCenterId: parts.length > 3 ? parts[3] : '',
      rawEntityId: parts.length > 4 ? parts[4] : null,
    );
  }

  static final _nationalOptions = AmountOptions(
    factor: 100,
    thousandSeparator: null,
    decimalSeparator: null,
    currencyDecimals: 0,
  );

  static final _internationalOptions = AmountOptions(
    factor: 1,
    thousandSeparator: null,
    decimalSeparator: null,
    currencyDecimals: 2,
  );
}

class _GrouppedProduct {
  final List<ClSantanderPersonasProductsE1> products;
  final ClSantanderPersonasCardDetalleConsultaTarjeta? card;

  _GrouppedProduct({required this.products, required this.card});
}
