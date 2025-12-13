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
  static final Map<String, ProductType> _santanderProductType = {
    'TCR': ProductType.creditCard,
    'LCR': ProductType.loan,
    'CCC': ProductType.checkingAccount,
  };

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

          if (numerocontrato == null ||
              producto == null ||
              subproducto == null ||
              oficinacontrato == null) {
            continue;
          }

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
              final cupo =
                  numberFromNumberWithSymbolAtTheEnd(product.cupo!) / 100;
              final montoDisponible =
                  numberFromNumberWithSymbolAtTheEnd(product.montodisponible!) /
                  100;
              final montoUtilizado =
                  numberFromNumberWithSymbolAtTheEnd(product.montoutilizado!) /
                  100;
              final codigoMoneda = product.codigomoneda;

              if (cupo != 0 && codigoMoneda != null) {
                creditBalances.add(
                  CreditBalance(
                    creditLimitAmount: cupo,
                    availableAmount: montoDisponible,
                    usedAmount: montoUtilizado,
                    currency: codigoMoneda,
                  ),
                );
              }
            }

            final numeroPan = products.first.numeropan;
            final glosaCorta = products.first.glosacorta;

            if (numeroPan == null) return;

            productList.add(
              Product(
                number: productId,
                name: titleCase(
                  glosaCorta?.toLowerCase() ?? card.glosaProducto ?? '',
                ),
                type: ProductType.creditCard,
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
            final montoDisponible =
                numberFromNumberWithSymbolAtTheEnd(
                  products.first.montodisponible!,
                ) /
                100;
            final codigoMoneda = products.first.codigomoneda;

            ProductType productType =
                _santanderProductType[agrupacionComercial] ?? ProductType.other;

            productList.add(
              Product(
                number: productId,
                name: titleCase(glosaCorta?.toLowerCase() ?? ''),
                type: productType,
                availableAmount: AvailableAmount(
                  amount: montoDisponible,
                  currency: codigoMoneda ?? 'CLP',
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
}

class _GrouppedProduct {
  final List<ClSantanderPersonasProductsE1> products;
  final ClSantanderPersonasCardDetalleConsultaTarjeta? card;

  _GrouppedProduct({required this.products, required this.card});
}
