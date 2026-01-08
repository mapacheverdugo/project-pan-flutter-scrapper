import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pan_scrapper/models/currency.dart';
import 'package:pan_scrapper/models/index.dart';
import 'package:pan_scrapper/services/connection_service.dart';
import 'package:pan_scrapper/services/mappers/cl_santander_personas/depositary_account_transaction_mapper.dart';
import 'package:pan_scrapper/services/mappers/cl_santander_personas/product_mapper.dart';
import 'package:pan_scrapper/services/mappers/cl_santander_personas/tarjetas_de_credito_consulta_ultimos_movimientos_mapper.dart';
import 'package:pan_scrapper/services/models/cl_santander_personas/index.dart';
import 'package:pan_scrapper/webview/webview.dart';

class ClSantanderPersonasConnectionService extends ConnectionService {
  final Dio _dio;
  final Future<WebviewInstance> Function() _webviewFactory;

  ClSantanderPersonasConnectionService(this._dio, this._webviewFactory);

  @override
  Future<String> auth(String username, String password) async {
    final completer = Completer<String>();
    final webview = await _webviewFactory();

    try {
      log("SantanderService auth before navigate");

      await webview.navigate(
        URLRequest(url: WebUri("https://www.santandermovil.cl/")),
      );

      webview.addAjaxResponseListener(RegExp(r'oauth2/token'), (request) async {
        debugPrint(
          'SantanderService ajaxResponseListener ${request.readyState}',
        );
        if (request.readyState == AjaxRequestReadyState.DONE) {
          final response = request.responseText;
          completer.complete(response);
        }

        return AjaxRequestAction.PROCEED;
      });

      log("SantanderService auth after navigate");

      await webview.waitForSelector('#rut', timeout: Duration(seconds: 60));

      log("SantanderService auth selector #rut founded");

      // aquí simulas login
      await webview.evaluate("""
        const rutInput = document.getElementById("rut");
        const passwordInput = document.getElementById("pass");
        
        rutInput.value = "$username";
        rutInput.dispatchEvent(new Event('input'));
        rutInput.dispatchEvent(new Event('blur'));

        passwordInput.value = "$password";
        passwordInput.dispatchEvent(new Event('input'));
        passwordInput.dispatchEvent(new Event('blur'));

        document.querySelector("div.login > form > div.container-btn-lib > button > span.mat-button-wrapper").click();
      """);

      log("SantanderService auth waiting for completer...");

      // 🚀 aquí esperas hasta que el interceptor resuelva
      final result = await completer.future;

      log("SantanderService auth completed with: $result");

      await webview.close();

      return result;
    } catch (e) {
      await webview.close();
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<List<Product>> getProducts(String credentials) async {
    final webview = await _webviewFactory();
    try {
      final tokenResponse = jsonDecode(credentials) as Map<String, dynamic>;

      final tokenModel = ClSantanderPersonasTokenModel.fromMap(tokenResponse);
      final rut = tokenModel.crucedeProducto['ESCALARES']['NUMERODOCUMENTO'];
      final jwt = tokenModel.tokenJwt;

      // Fetch properties
      final properties = await _getProperties(webview);

      // Fetch products and credit cards
      final rawProducts = await _getRawProducts(
        properties: properties,
        rut: rut,
        jwt: jwt,
      );
      final cardResponse = await _getCreditCards(
        properties: properties,
        rut: rut,
        jwt: jwt,
      );

      // Map to Product models
      return ClSantanderPersonasProductMapper.fromProductsResponseAndCardResponse(
        rawProducts,
        cardResponse,
      );
    } catch (e) {
      log('Error fetching products: $e');
      rethrow;
    }
  }

  /// Fetches properties from the Santander properties frame JavaScript file
  Future<ClSantanderPersonasPropertiesResponseModel> _getProperties(
    WebviewInstance webview,
  ) async {
    final url =
        "https://movil.santander.cl/UI.Web.HB/Private_new/frame/assets/web/properties-frame.web.js";

    final response = await _dio.get(url);
    final text = response.data.toString();

    try {
      await webview.navigate(
        URLRequest(url: WebUri("https://www.santandermovil.cl/")),
      );

      await webview.evaluate(text);

      final propertiesFrameJson = await webview.evaluate("propertiesFrame");

      await webview.close();

      return ClSantanderPersonasPropertiesResponseModel.fromMap(
        propertiesFrameJson,
      );
    } catch (e) {
      await webview.close();
      rethrow;
    }
  }

  /// Fetches credit cards for the given RUT and JWT
  Future<ClSantanderPersonasCardResponse> _getCreditCards({
    required ClSantanderPersonasPropertiesResponseModel properties,
    required String rut,
    required String jwt,
  }) async {
    try {
      final usuarioAlt = properties.usuarioAlt;
      final canalId = properties.canal;
      final canalFisico = properties.canalFisico;
      final canalLogico = properties.canalLogico;
      final numeroServidor = properties.nroSer;

      final response = await _dio.post<Map<String, dynamic>>(
        'https://apiper.santander.cl/perdsk/transversales/mdp/tarjetasRut',
        data: {
          'Cabecera': {
            'InfoGeneral': {'NumeroServidor': numeroServidor},
          },
          'CONTarjetasRut_Request': {
            'cabecera': {
              'HOST': {
                'USUARIO-ALT': usuarioAlt,
                'TERMINAL-ALT': '',
                'CANAL-ID': canalId,
              },
              'CanalFisico': canalFisico,
              'CanalLogico': canalLogico,
              'RutCliente': rut,
              'RutUsuario': rut,
              'IpCliente': '',
              'InfoDispositivo': 'xx',
            },
            'Entrada': {
              'RutCliente': rut,
              'Opcion': 'C',
              'IndicadorTarjeta': '',
              'IndicadorRellamada': '',
              'DatosRellamada': '',
            },
          },
        },
        options: Options(
          headers: {
            'accept': 'application/json, text/plain, */*',
            'accept-language': 'es-419,es;q=0.6',
            'access-token': jwt,
            'content-type': 'application/json',
            'origin': 'https://movil.santander.cl',
            'priority': 'u=1, i',
            'referer': 'https://movil.santander.cl/',
            'sec-ch-ua':
                '"Not(A:Brand";v="99", "Brave";v="133", "Chromium";v="133"',
            'sec-ch-ua-mobile': '?1',
            'sec-ch-ua-platform': '"Android"',
            'sec-fetch-dest': 'empty',
            'sec-fetch-mode': 'cors',
            'sec-fetch-site': 'same-site',
            'sec-gpc': '1',
            'user-agent':
                'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Mobile Safari/537.36',
          },
        ),
      );

      final responseData = response.data;
      if (responseData == null) {
        throw Exception('Empty response from credit cards API');
      }

      final metadata = responseData['METADATA'] as Map<String, dynamic>?;
      if (metadata != null && metadata['STATUS'] == '101') {
        throw Exception('Credentials expired - needs reauth');
      }

      return ClSantanderPersonasCardResponse.fromJson(responseData);
    } catch (e) {
      log('Error fetching credit cards: $e');
      rethrow;
    }
  }

  /// Fetches raw products for the given RUT and JWT
  Future<ClSantanderPersonasProductsResponse> _getRawProducts({
    required ClSantanderPersonasPropertiesResponseModel properties,
    required String rut,
    required String jwt,
  }) async {
    try {
      final usuarioAlt = properties.usuarioAlt;
      final canalId = properties.canal;
      final canalFisico = properties.canalFisico;
      final canalLogico = properties.canalLogico;
      final infoDispositivo = properties.infoDispositivo;
      final numeroServidor = properties.nroSer;

      final data = {
        'cabecera': {
          'HOST': {
            'USUARIO-ALT': usuarioAlt,
            'TERMINAL-ALT': '',
            'CANAL-ID': canalId,
          },
          'CanalFisico': canalFisico,
          'CanalLogico': canalLogico,
          'RutCliente': rut,
          'RutUsuario': rut,
          'InfoDispositivo': infoDispositivo,
          'InfoGeneral': {'NumeroServidor': numeroServidor},
        },
        'INPUT': {
          'ID-RECALL': '',
          'USUARIO-ALT': usuarioAlt,
          'ENTIDAD': '',
          'TIPODOCUMENTO': '',
          'NUMERODOCUMENTO': rut,
          'CANALACONSULTAR': '',
          'CRUCEACONSULTAR': '',
          'ESTADORELACION': '',
        },
      };

      final headers = {
        'accept': 'application/json, text/plain, */*',
        'accept-language': 'es-419,es;q=0.6',
        'access-token': jwt,
        'content-type': 'application/json',
        'origin': 'https://movil.santander.cl',
        'priority': 'u=1, i',
        'referer': 'https://movil.santander.cl/',
        'sec-ch-ua':
            '"Not(A:Brand";v="99", "Brave";v="133", "Chromium";v="133"',
        'sec-ch-ua-mobile': '?1',
        'sec-ch-ua-platform': '"Android"',
        'sec-fetch-dest': 'empty',
        'sec-fetch-mode': 'cors',
        'sec-fetch-site': 'same-site',
        'sec-gpc': '1',
        'user-agent':
            'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Mobile Safari/537.36',
      };

      final response = await _dio.post<Map<String, dynamic>>(
        'https://apiper.santander.cl/perdsk/datosCliente/cruceProductosOnline',
        data: data,
        options: Options(headers: headers),
      );

      final responseData = response.data;
      if (responseData == null) {
        throw Exception('Empty response from products API');
      }

      final metadata = responseData['METADATA'] as Map<String, dynamic>?;
      if (metadata != null && metadata['STATUS'] == '101') {
        throw Exception('Credentials expired - needs reauth');
      }

      return ClSantanderPersonasProductsResponse.fromJson(responseData);
    } catch (e) {
      log('Error fetching products: $e');
      rethrow;
    }
  }

  @override
  Future<List<Transaction>> getDepositaryAccountTransactions(
    String credentials,
    String productId,
  ) async {
    try {
      final tokenResponse = jsonDecode(credentials) as Map<String, dynamic>;
      final tokenModel = ClSantanderPersonasTokenModel.fromMap(tokenResponse);
      final rut = tokenModel.crucedeProducto['ESCALARES']['NUMERODOCUMENTO'];
      final accessToken = tokenModel.accessToken;
      final jwt = tokenModel.tokenJwt;

      // Subscribe key first
      await _suscriberKey(rut, accessToken);

      // Parse product ID
      final productIdMetadata = ClSantanderPersonasProductMapper.parseProductId(
        productId,
      );

      final transactions = <Transaction>[];

      // Get raw products to find currency
      final rawProducts = await _getRawProducts(
        properties: await _getProperties(await _webviewFactory()),
        rut: rut,
        jwt: jwt,
      );

      final currentProduct = rawProducts
          .data
          ?.output
          ?.matrices
          ?.matrizcaptaciones
          ?.e1
          .firstWhereOrNull(
            (product) =>
                product.numerocontrato == productIdMetadata.rawContractId,
          );

      if (currentProduct == null) {
        throw Exception('Product not found');
      }

      final codigomoneda = currentProduct.codigomoneda;

      if (codigomoneda == null) {
        throw Exception('Product currency not found');
      }

      final productCurrency =
          Currency.tryFromIsoLetters(codigomoneda) ?? Currency.clp;

      // Paginated requests
      var shouldContinue = true;
      String? lastMovementNumber;

      do {
        final response = await _getRawDepositaryAccountRecentTransactionsPage(
          productIdMetadata: productIdMetadata,
          productCurrency: codigomoneda,
          accessToken: accessToken,
          endMovement: lastMovementNumber,
        );

        final newTransactions =
            ClSantanderPersonasDepositaryAccountTransactionMapper.fromResponseModel(
              response,
              productCurrency,
            );

        transactions.addAll(newTransactions);

        final finalMove = response.repositioningExit?.finalMove;

        if (finalMove == null) {
          shouldContinue = false;
        } else {
          lastMovementNumber = finalMove;
        }
      } while (shouldContinue);

      return transactions;
    } catch (e) {
      log('Error fetching depositary account transactions: $e');
      rethrow;
    }
  }

  /// Subscribes the key for the given RUT and access token
  Future<void> _suscriberKey(String rut, String accessToken) async {
    try {
      final response = await _dio.post(
        'https://apideveloper.santander.cl/sancl/privado/market_research/v1/suscriberkeymc',
        data: {
          'rut': rut.substring(0, rut.length - 1),
          'digitoVerificador': rut.substring(rut.length - 1),
        },
        options: Options(
          headers: {
            'accept': 'application/json, text/plain, */*',
            'accept-language': 'es-419,es;q=0.9',
            'origin': 'https://mibanco.santander.cl',
            'priority': 'u=1, i',
            'referer': 'https://mibanco.santander.cl/',
            'sec-ch-ua':
                '"Chromium";v="134", "Not:A-Brand";v="24", "Brave";v="134"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
            'sec-fetch-dest': 'empty',
            'sec-fetch-mode': 'cors',
            'sec-fetch-site': 'same-site',
            'sec-gpc': '1',
            'user-agent':
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36',
            'content-type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      final responseData = response.data;
      if (responseData == null) {
        throw Exception('Credentials expired - needs reauth');
      }

      if (responseData is Map<String, dynamic>) {
        final metadata = responseData['METADATA'] as Map<String, dynamic>?;
        if (metadata != null && metadata['STATUS'] == '401') {
          throw Exception('Credentials expired - needs reauth');
        }
      }
    } catch (e) {
      log('Error in suscriberKey: $e');
      // Check if it's a 401 error
      if (e is DioException && e.response?.statusCode == 401) {
        throw Exception('Credentials expired - needs reauth');
      }
      rethrow;
    }
  }

  /// Fetches a page of depositary account transactions
  Future<ClSantanderPersonasDepositaryAccountTransactionResponseModel>
  _getRawDepositaryAccountRecentTransactionsPage({
    required ClSantanderPersonasProductIdMetadata productIdMetadata,
    required String productCurrency,
    required String accessToken,
    String? endMovement,
  }) async {
    try {
      final properties = await _getProperties(await _webviewFactory());
      final santanderClientId = properties.xSantanderClientId;
      final usuarioAlt = properties.usuarioAlt;

      // Construct account ID from center ID and contract ID
      final accountId =
          '${productIdMetadata.rawCenterId}${productIdMetadata.rawContractId}';

      final startDate = '2000-01-01';
      // Get current date and add 30 days
      final endDate = DateTime.now().add(const Duration(days: 30));

      final body = <String, dynamic>{
        'accountId': accountId,
        'currency': productCurrency,
        'commercialGroup': '',
        'openingDate': startDate,
        'closingDate': endDate.toIso8601String().split('T')[0],
      };

      if (endMovement != null) {
        body['startMovement'] = '000000000';
        body['endMovement'] = endMovement;
      }

      final response = await _dio.post(
        'https://openbanking.santander.cl/account_balances_transactions_and_withholdings_retail/v1/current-accounts/transactions',
        data: body,
        options: Options(
          headers: {
            'host': 'openbanking.santander.cl',
            'origin': 'https://mibanco.santander.cl',
            'referer': 'https://mibanco.santander.cl/',
            'sec-ch-ua':
                '"Chromium";v="134", "Not:A-Brand";v="24", "Brave";v="134"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"macOS"',
            'sec-fetch-dest': 'empty',
            'sec-fetch-mode': 'cors',
            'sec-fetch-site': 'same-site',
            'sec-gpc': '1',
            'user-agent':
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36',
            'x-b3-spanid': 'AL43243287438243P',
            'x-client-code': 'STD-PER-FPP',
            'x-organization-code': 'Santander',
            'x-santander-client-id': santanderClientId,
            'x-schema-id': usuarioAlt,
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      final responseData = response.data;
      if (responseData == null) {
        throw Exception('Empty response from transactions API');
      }

      return ClSantanderPersonasDepositaryAccountTransactionResponseModel.fromJson(
        responseData as Map<String, dynamic>,
      );
    } catch (e) {
      log('Error fetching depositary account transactions page: $e');
      if (e is DioException && e.response?.statusCode == 401) {
        throw Exception('Credentials expired - needs reauth');
      }
      rethrow;
    }
  }

  @override
  Future<List<CreditCardBillPeriod>> getCreditCardBillPeriods(
    String credentials,
    String productId,
  ) async {
    try {
      final tokenResponse = jsonDecode(credentials) as Map<String, dynamic>;
      final tokenModel = ClSantanderPersonasTokenModel.fromMap(tokenResponse);
      final rut = tokenModel.crucedeProducto['ESCALARES']['NUMERODOCUMENTO'];
      final jwt = tokenModel.tokenJwt;

      final properties = await _getProperties(await _webviewFactory());

      final usuarioAlt = properties.usuarioAlt;
      final canalId = properties.canal;
      final numeroServidor = properties.nroSer;

      // Parse productId - format is entityId_centerId_contractId
      final productParts = productId.split('_');
      if (productParts.length < 3) {
        throw Exception('Invalid product ID format');
      }
      final numero = productParts[0];
      final centalt = productParts[3];
      final codent = productParts[4];

      final requestBody = {
        'cabecera': {
          'HOST': {
            'USUARIO-ALT': usuarioAlt,
            'TERMINAL-ALT': '',
            'CANAL-ID': canalId,
          },
          'CanalFisico': '',
          'CanalLogico': '',
          'RutCliente': rut,
          'RutUsuario': rut,
          'InfoDispositivo': 'InfoDispositivo',
          'InfoGeneral': {'NumeroServidor': numeroServidor},
        },
        'INPUT': {
          'USUARIO-ALT': usuarioAlt,
          'CANAL-ID': canalId,
          'CODENT': codent,
          'CENTALT': centalt,
          'CUENTA': numero,
          'PAN': '',
        },
      };

      final headers = {
        'accept': 'application/json, text/plain, */*',
        'accept-language': 'es-419,es;q=0.6',
        'content-type': 'application/json',
        'origin': 'https://movil.santander.cl',
        'referer': 'https://movil.santander.cl/',
        'access-token': jwt,
      };

      final response = await _dio.post<Map<String, dynamic>>(
        'https://apiper.santander.cl/permov/tarjetasDeCredito/cuentasDisponibles',
        data: requestBody,
        options: Options(headers: headers),
      );

      final responseData = response.data;
      if (responseData == null) {
        throw Exception('Empty response from bill periods API');
      }

      final metadata = responseData['METADATA'] as Map<String, dynamic>?;
      if (metadata != null && metadata['STATUS'] == '101') {
        throw Exception('Credentials expired - needs reauth');
      }

      // Parse response
      final data = responseData['DATA'] as Map<String, dynamic>?;
      final asTib =
          data?['AS_TIB_WM01_CONCuentasDisponibles'] as Map<String, dynamic>?;
      final output = asTib?['OUTPUT'] as Map<String, dynamic>?;
      final matriz = output?['MATRIZ'] as List<dynamic>?;

      if (matriz == null) {
        return [];
      }

      final periods = <CreditCardBillPeriod>[];
      for (final period in matriz) {
        final periodMap = period as Map<String, dynamic>;
        final moneda = periodMap['MONEDA'] as String?;
        final fechaExt = periodMap['FECHAEXT'] as String?;
        final numExt = periodMap['NUMEXT'] as String?;

        if (moneda == null || fechaExt == null || numExt == null) {
          continue;
        }

        // Convert ISO number to currency code
        final currencyCode = _getCurrencyFromIsoNumber(
          int.tryParse(moneda) ?? 0,
        );
        final currencyType = currencyCode == 'CLP'
            ? CurrencyType.national
            : CurrencyType.international;

        final periodId = '${currencyType.name}_$numExt';

        periods.add(
          CreditCardBillPeriod(
            id: periodId,
            startDate: fechaExt,
            endDate: null,
            currency: currencyCode,
            currencyType: currencyType,
          ),
        );
      }

      return periods;
    } catch (e) {
      log('Error fetching Santander credit card bill periods: $e');
      rethrow;
    }
  }

  String _getCurrencyFromIsoNumber(int isoNumber) {
    // ISO 4217 currency codes
    // 152 = CLP, 840 = USD
    switch (isoNumber) {
      case 152:
        return 'CLP';
      case 840:
        return 'USD';
      default:
        return 'CLP'; // Default to CLP
    }
  }

  /// Gets credit card unbilled transactions for the given product and currency type
  @override
  Future<List<Transaction>> getCreditCardUnbilledTransactions(
    String credentials,
    String productId,
    CurrencyType transactionType,
  ) async {
    try {
      final tokenResponse = jsonDecode(credentials) as Map<String, dynamic>;
      final tokenModel = ClSantanderPersonasTokenModel.fromMap(tokenResponse);
      final rut = tokenModel.crucedeProducto['ESCALARES']['NUMERODOCUMENTO'];
      final accessToken = tokenModel.accessToken;

      final properties = await _getProperties(await _webviewFactory());
      final usuarioAlt = properties.usuarioAlt;
      final canalId = properties.canal;
      final canalFisico = properties.canalFisico;
      final canalLogico = properties.canalLogico;
      final infoDispositivo = properties.infoDispositivo;
      final santanderClientId = properties.xSantanderClientId;

      // Parse product ID
      final productIdMetadata = ClSantanderPersonasProductMapper.parseProductId(
        productId,
      );

      // Determine currency code
      final moneda = transactionType == CurrencyType.national ? 'CLP' : 'USD';

      final requestBody = {
        'Cabecera': {
          'HOST': {
            'USUARIO-ALT': usuarioAlt,
            'TERMINAL-ALT': '',
            'CANAL-ID': canalId,
          },
          'CanalFisico': canalFisico,
          'CanalLogico': canalLogico,
          'RutCliente': rut,
          'RutUsuario': rut,
          'IpCliente': '',
          'InfoDispositivo': infoDispositivo,
        },
        'Entrada': {
          'Entidad': productIdMetadata.rawEntityId ?? '',
          'Centro': productIdMetadata.rawCenterId,
          'Cuenta': productIdMetadata.rawContractId,
          'Moneda': moneda,
        },
      };

      final headers = {
        'accept': 'application/json, text/plain, */*',
        'accept-language': 'es-419,es;q=0.9',
        'authorization': 'Bearer $accessToken',
        'content-type': 'application/json',
        'origin': 'https://movil.santander.cl',
        'priority': 'u=1, i',
        'referer': 'https://movil.santander.cl/',
        'sec-ch-ua':
            '"Brave";v="143", "Chromium";v="143", "Not A(Brand";v="24"',
        'sec-ch-ua-mobile': '?1',
        'sec-ch-ua-platform': '"Android"',
        'sec-fetch-dest': 'empty',
        'sec-fetch-mode': 'cors',
        'sec-fetch-site': 'same-site',
        'sec-gpc': '1',
        'user-agent':
            'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Mobile Safari/537.36',
        'x-santander-client-id': santanderClientId,
      };

      final response = await _dio.post<Map<String, dynamic>>(
        'https://api-dsk.santander.cl/permov/tarjetasDeCredito/consultaUltimosMovimientos',
        data: requestBody,
        options: Options(headers: headers),
      );

      final responseData = response.data;
      if (responseData == null) {
        throw Exception('Empty response from unbilled transactions API');
      }

      final metadata = responseData['METADATA'] as Map<String, dynamic>?;
      if (metadata != null && metadata['STATUS'] == '101') {
        throw Exception('Credentials expired - needs reauth');
      }

      final model =
          ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosResponseModel.fromJson(
            responseData,
          );

      return ClSantanderPersonasTarjetasDeCreditoConsultaUltimosMovimientosMapper.fromResponseModel(
        model,
        transactionType,
      );
    } catch (e) {
      log('Error fetching credit card unbilled transactions: $e');
      rethrow;
    }
  }

  @override
  Future<CreditCardBill> getCreditCardBill(
    String credentials,
    String productId,
    String periodId,
  ) async {
    throw UnimplementedError('Santander credit card bill not implemented');
  }

  @override
  Future<Uint8List> getCreditCardBillPdf(
    String credentials,
    String productId,
    String periodId,
  ) async {
    try {
      final tokenResponse = jsonDecode(credentials) as Map<String, dynamic>;
      final tokenModel = ClSantanderPersonasTokenModel.fromMap(tokenResponse);
      final rut = tokenModel.crucedeProducto['ESCALARES']['NUMERODOCUMENTO'];
      final accessToken = tokenModel.accessToken;

      final properties = await _getProperties(await _webviewFactory());

      final usuarioAlt = properties.usuarioAlt;
      final canalId = properties.canal;
      final canalFisico = properties.canalFisico;
      final canalLogico = properties.canalLogico;
      final numeroServidor = properties.nroSer;

      // Parse productId
      final productParts = productId.split('_');
      if (productParts.length < 3) {
        throw Exception('Invalid product ID format');
      }
      final rawEntityId = productParts[0];
      final rawCenterId = productParts[1];
      final rawContractId = productParts[2];

      // Get period details to find startDate
      final periods = await getCreditCardBillPeriods(credentials, productId);
      final period = periods.firstWhere(
        (p) => p.id == periodId,
        orElse: () => throw Exception('Period not found'),
      );

      final requestBody = {
        'Cabecera': {
          'HOST': {
            'USUARIO-ALT': usuarioAlt,
            'TERMINAL-ALT': '',
            'CANAL-ID': canalId,
          },
          'CanalFisico': canalFisico,
          'CanalLogico': canalLogico,
          'RutCliente': rut,
          'RutUsuario': rut,
          'IpCliente': '',
          'InfoDispositivo': 'InfoDispositivo',
          'InfoGeneral': {'NumeroServidor': numeroServidor},
        },
        'Entrada': {
          'RutCliente': rut,
          'CodEntidad': rawEntityId,
          'CentroAlt': rawCenterId,
          'Moneda': period.currency,
          'Cuenta': rawContractId,
          'Fecha': period.startDate.replaceAll('-', ''),
        },
      };

      final response = await _dio.post<Map<String, dynamic>>(
        'https://apiper.santander.cl/permov/tarjetasDeCredito/estadoDeCuenta',
        data: requestBody,
        options: Options(
          headers: {
            'accept': 'application/json, text/plain, */*',
            'accept-language': 'es-419,es;q=0.6',
            'access-token': accessToken,
            'content-type': 'application/json',
            'origin': 'https://mibanco.santander.cl',
            'priority': 'u=1, i',
            'referer': 'https://mibanco.santander.cl/',
            'sec-fetch-dest': 'empty',
            'sec-fetch-mode': 'cors',
            'sec-fetch-site': 'same-site',
            'sec-gpc': '1',
            'user-agent':
                'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
          },
        ),
      );

      final responseData = response.data;
      if (responseData == null) {
        throw Exception('Empty response from bill PDF API');
      }

      final metadata = responseData['METADATA'] as Map<String, dynamic>?;
      if (metadata != null && metadata['STATUS'] == '101') {
        throw Exception('Credentials expired - needs reauth');
      }

      if (metadata?['STATUS'] != '0') {
        throw Exception('Error fetching bill PDF');
      }

      final data = responseData['DATA'] as Map<String, dynamic>?;
      final imgNbs64 = data?['imgNbs64'] as String?;

      if (imgNbs64 == null) {
        throw Exception('No PDF data in response');
      }

      // Decode base64 to bytes
      final bytes = base64Decode(imgNbs64);
      return Uint8List.fromList(bytes);
    } catch (e) {
      log('Error fetching Santander credit card bill PDF: $e');
      rethrow;
    }
  }
}
