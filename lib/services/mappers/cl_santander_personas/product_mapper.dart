import 'package:pan_scrapper/helpers/amount_helpers.dart';
import 'package:pan_scrapper/helpers/string_helpers.dart';
import 'package:pan_scrapper/models/available_amount.dart';
import 'package:pan_scrapper/models/card_brand.dart';
import 'package:pan_scrapper/models/credit_balance.dart';
import 'package:pan_scrapper/models/product.dart';
import 'package:pan_scrapper/models/product_type.dart';

// ProductIdMetadata interface
class _ProductIdMetadata {
  final String rawContractId;
  final String rawProductId;
  final String rawSubProductId;
  final String rawCenterId;
  final String? rawEntityId;

  _ProductIdMetadata({
    required this.rawContractId,
    required this.rawProductId,
    required this.rawSubProductId,
    required this.rawCenterId,
    this.rawEntityId,
  });
}

// Response model classes (using dynamic/json structure)
// These models can be constructed from JSON responses
// Example: _SantanderProductsResponseModel(data: jsonDecode(response)['DATA'])
class _SantanderProductsResponseModel {
  final Map<String, dynamic>? data;

  _SantanderProductsResponseModel({this.data});

  // Access DATA.OUTPUT.MATRICES.MATRIZCAPTACIONES.e1
  List<dynamic>? get e1 {
    final output = data?['OUTPUT'] as Map<String, dynamic>?;
    final matrices = output?['MATRICES'] as Map<String, dynamic>?;
    final matrizCaptaciones =
        matrices?['MATRIZCAPTACIONES'] as Map<String, dynamic>?;
    return matrizCaptaciones?['e1'] as List<dynamic>?;
  }
}

class _SantanderCardResponseModel {
  final Map<String, dynamic>? data;

  _SantanderCardResponseModel({this.data});

  // Access DATA.CONTarjetasRut_Response.OUTPUT.DetalleConsultaTarjetas
  List<dynamic>? get detalleConsultaTarjetas {
    final contTarjetasRutResponse =
        data?['CONTarjetasRut_Response'] as Map<String, dynamic>?;
    final output = contTarjetasRutResponse?['OUTPUT'] as Map<String, dynamic>?;
    return output?['DetalleConsultaTarjetas'] as List<dynamic>?;
  }
}

class ClSantanderPersonasProductMapper {
  static final Map<String, ProductType> _santanderProductType = {
    'TCR': ProductType.creditCard,
    'LCR': ProductType.loan,
    'CCC': ProductType.checkingAccount,
  };

  static List<Product> fromProductsResponseModelAndCardResponseModel(
    Map<String, dynamic> productsResponseJson,
    Map<String, dynamic> cardResponseJson,
  ) {
    final productsResponseModel = _SantanderProductsResponseModel(
      data: productsResponseJson,
    );
    final cardResponseModel = _SantanderCardResponseModel(
      data: cardResponseJson,
    );
    final productList = <Product>[];

    final e1 = productsResponseModel.e1;
    if (e1 != null && e1.isNotEmpty) {
      // Group products by productId
      final groupedProducts = <String, List<Map<String, dynamic>>>{};

      for (final product in e1) {
        final productMap = product as Map<String, dynamic>;
        final contractNumber = productMap['NUMEROCONTRATO'] as String? ?? '';
        final producto = productMap['PRODUCTO'] as String? ?? '';

        // Find matching card
        final detalle = cardResponseModel.detalleConsultaTarjetas;
        Map<String, dynamic>? card;
        if (detalle != null) {
          card = detalle.cast<Map<String, dynamic>>().firstWhere(
            (c) => c['Contrato'] == contractNumber,
            orElse: () => <String, dynamic>{},
          );
          if (card.isEmpty) card = null;
        }

        final productId = createProductId(
          rawContractId: contractNumber,
          rawProductId: producto,
          rawSubProductId: productMap['SUBPRODUCTO'] as String? ?? '',
          rawCenterId: productMap['OFICINACONTRATO'] as String? ?? '',
          rawEntityId: card?['Entidad'] as String?,
        );

        groupedProducts.putIfAbsent(productId, () => []);
        groupedProducts[productId]!.add(productMap);
      }

      // Process grouped products
      groupedProducts.forEach((productId, products) {
        if (products.isEmpty) return;

        final firstProduct = products[0];
        final agrupacionComercial =
            firstProduct['AGRUPACIONCOMERCIAL'] as String? ?? '';

        if (agrupacionComercial == 'TCR') {
          // Credit card product
          var creditBalances = products
              .map((product) {
                final cupo =
                    numberFromNumberWithSymbolAtTheEnd(
                      product['CUPO'] as String? ?? '',
                    ) /
                    100;
                final montoDisponible =
                    numberFromNumberWithSymbolAtTheEnd(
                      product['MONTODISPONIBLE'] as String? ?? '',
                    ) /
                    100;
                final montoUtilizado =
                    numberFromNumberWithSymbolAtTheEnd(
                      product['MONTOUTILIZADO'] as String? ?? '',
                    ) /
                    100;
                final codigoMoneda = product['CODIGOMONEDA'] as String? ?? '';

                return CreditBalance(
                  creditLimitAmount: cupo,
                  availableAmount: montoDisponible,
                  usedAmount: montoUtilizado,
                  currency: codigoMoneda,
                );
              })
              .where((balance) => balance.creditLimitAmount != 0)
              .toList();

          final numeroPan = firstProduct['NUMEROPAN'] as String? ?? '';
          final glosaCorta = firstProduct['GLOSACORTA'] as String? ?? '';

          productList.add(
            Product(
              number: removeEverythingButNumbers(numeroPan),
              name: titleCase(glosaCorta.toLowerCase()),
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
          final glosaCorta = firstProduct['GLOSACORTA'] as String? ?? '';
          final numeroContrato =
              firstProduct['NUMEROCONTRATO'] as String? ?? '';
          final montoDisponible =
              numberFromNumberWithSymbolAtTheEnd(
                firstProduct['MONTODISPONIBLE'] as String? ?? '',
              ) /
              100;
          final codigoMoneda = firstProduct['CODIGOMONEDA'] as String? ?? '';

          ProductType productType =
              _santanderProductType[agrupacionComercial] ?? ProductType.other;

          productList.add(
            Product(
              number: removeEverythingButNumbers(
                removeEverythingButNumbers(numeroContrato),
              ),
              name: titleCase(glosaCorta.toLowerCase()),
              type: productType,
              availableAmount: AvailableAmount(
                amount: montoDisponible,
                currency: codigoMoneda,
              ),
              creditBalances: [],
              isForSecondaryCardHolder: false,
            ),
          );
        }
      });
    }

    return productList;
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

  static _ProductIdMetadata parseProductId(String productId) {
    final parts = productId.split('_');
    return _ProductIdMetadata(
      rawContractId: parts.length > 0 ? parts[0] : '',
      rawProductId: parts.length > 1 ? parts[1] : '',
      rawSubProductId: parts.length > 2 ? parts[2] : '',
      rawCenterId: parts.length > 3 ? parts[3] : '',
      rawEntityId: parts.length > 4 ? parts[4] : null,
    );
  }
}
