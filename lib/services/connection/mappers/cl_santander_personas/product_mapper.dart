import 'package:collection/collection.dart';
import 'package:pan_scrapper/entities/amount.dart';
import 'package:pan_scrapper/entities/currency.dart';
import 'package:pan_scrapper/helpers/string_helpers.dart';
import 'package:pan_scrapper/models/connection/card_brand.dart';
import 'package:pan_scrapper/models/connection/credit_balance.dart';
import 'package:pan_scrapper/models/connection/product.dart';
import 'package:pan_scrapper/models/connection/product_type.dart';
import 'package:pan_scrapper/services/connection/models/cl_santander_personas/index.dart';

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

  static CardBrand _getCardBrand(String descripcion) {
    if (descripcion.toLowerCase().contains('visa')) {
      return CardBrand.visa;
    } else if (descripcion.toLowerCase().contains('mastercard')) {
      return CardBrand.mastercard;
    } else if (descripcion.toLowerCase().contains('american express')) {
      return CardBrand.amex;
    } else if (descripcion.toLowerCase().contains('diners')) {
      return CardBrand.diners;
    }
    return CardBrand.other;
  }

  static List<ExtractedProductModel> fromProductsResponseAndCardResponse(
    ClSantanderPersonasProductsResponse productsResponse,
    ClSantanderPersonasCardResponse cardResponse,
  ) {
    try {
      final productList = <ExtractedProductModel>[];

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
            final creditBalances = <ExtractedCreditBalance>[];

            for (final product in products) {
              final codigomoneda = product.codigomoneda;

              if (codigomoneda == null) continue;

              final currency = Currency.fromIsoLetters(codigomoneda);
              final options = currency == Currency.clp
                  ? _nationalOptions
                  : _internationalOptions;

              final creditLimitAmount = Amount.tryParse(
                product.cupo,
                currency,
                options: options,
              );
              final availableAmount = Amount.parse(
                product.montodisponible,
                currency,
                options: options,
              );

              final usedAmount = Amount.tryParse(
                product.montoutilizado,
                currency,
                options: options,
              );

              if (creditLimitAmount != null &&
                  creditLimitAmount.value != 0 &&
                  availableAmount.value != 0 &&
                  usedAmount != null &&
                  usedAmount.value != 0) {
                creditBalances.add(
                  ExtractedCreditBalance(
                    creditLimitAmount: creditLimitAmount.value,
                    availableAmount: availableAmount.value,
                    usedAmount: usedAmount.value,
                    currency: currency,
                  ),
                );
              }
            }

            final numeroPan = products.first.numeropan;
            final glosaCorta = products.first.glosacorta;

            productList.add(
              ExtractedProductModel(
                providerId: productId,
                number: products.first.numerocontrato,
                name: titleCase(
                  glosaCorta?.toLowerCase() ?? card.glosaProducto,
                ),
                type: _getProductType(agrupacionComercial),
                cardBrand: _getCardBrand(card.glosaProducto),
                cardLast4Digits: numeroPan.length >= 4
                    ? numeroPan.substring(numeroPan.length - 4)
                    : numeroPan,
                creditBalances: creditBalances,
              ),
            );
          } else {
            // Depositary product
            final glosaCorta = products.first.glosacorta;

            final codigomoneda = products.first.codigomoneda;
            if (codigomoneda == null) return;
            final currency = Currency.fromIsoLetters(codigomoneda);
            final options = currency == Currency.clp
                ? _nationalOptions
                : _internationalOptions;

            final availableAmount = Amount.tryParse(
              products.first.montodisponible,
              currency,
              options: options,
            );
            final usedAmount = Amount.tryParse(
              products.first.montoutilizado,
              currency,
              options: options,
            );
            final creditLimitAmount = Amount.tryParse(
              products.first.cupo,
              currency,
              options: options,
            );

            final creditBalances = <ExtractedCreditBalance>[];
            if (creditLimitAmount != null &&
                creditLimitAmount.value != 0 &&
                availableAmount != null &&
                availableAmount.value != 0 &&
                usedAmount != null &&
                usedAmount.value != 0) {
              creditBalances.add(
                ExtractedCreditBalance(
                  creditLimitAmount: creditLimitAmount.value,
                  availableAmount: availableAmount.value,
                  usedAmount: usedAmount.value,
                  currency: currency,
                ),
              );
            }

            ProductType productType = _getProductType(agrupacionComercial);

            productList.add(
              ExtractedProductModel(
                providerId: productId,
                number: products.first.numerocontrato,
                name: titleCase(glosaCorta?.toLowerCase() ?? ''),
                type: productType,
                availableAmount: creditBalances.isEmpty
                    ? Amount(value: availableAmount!.value, currency: currency)
                    : null,
                creditBalances: creditBalances,
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

  static final _nationalOptions = AmountParseOptions(
    factor: 100,
    thousandSeparator: null,
    decimalSeparator: null,
    currencyDecimals: 0,
  );

  static final _internationalOptions = AmountParseOptions(
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
