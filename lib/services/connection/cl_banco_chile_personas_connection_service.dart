import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pan_scrapper/entities/currency.dart';
import 'package:pan_scrapper/entities/index.dart';
import 'package:pan_scrapper/services/connection/connection_exception.dart';
import 'package:pan_scrapper/services/connection/connection_service.dart';
import 'package:pan_scrapper/services/connection/mappers/cl_banco_chile_personas/credit_card_unbilled_transaction_mapper.dart';
import 'package:pan_scrapper/services/connection/mappers/cl_banco_chile_personas/depositary_transaction_mapper.dart';
import 'package:pan_scrapper/services/connection/mappers/cl_banco_chile_personas/product_mapper.dart';
import 'package:pan_scrapper/services/connection/mappers/common.dart';
import 'package:pan_scrapper/services/connection/models/cl_banco_chile_personas/index.dart';
import 'package:pan_scrapper/services/connection/webview/webview.dart';

class ClBancoChilePersonasConnectionService extends ConnectionService {
  late final Dio _dio;
  final Future<WebviewInstance> Function() _webviewFactory;

  ClBancoChilePersonasConnectionService(this._dio, this._webviewFactory);

  @override
  Future<String> auth(
    String username,
    String password, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final completer = Completer<String>();
    final webview = await _webviewFactory();

    try {
      log("BancoChileService auth before navigate");

      // Listen for error redirects
      webview.addLoadResourceListener(
        RegExp(
          r'https://login\.portal\.bancochile\.cl/bancochile-web/persona/login/index\.html#/alerta-bloqueo',
        ),
        () {
          if (!completer.isCompleted) {
            completer.completeError(Exception('Credentials blocked'));
          }
        },
      );

      webview.addAjaxResponseListener(
        RegExp(
          r'https://login\.portales\.bancochile\.cl/usernamepassword/login',
        ),
        (request) async {
          final status = request.status;
          final response = request.responseText;

          var responseJson;
          try {
            responseJson = response != null ? jsonDecode(response) : null;
          } catch (e) {
            log('Error decoding response: $e');
          }

          if (status != null) {
            if (status == 429) {
              if (!completer.isCompleted) {
                completer.completeError(
                  ConnectionException(ConnectionExceptionType.authBlocked),
                );
              }
            } else if (status == 401 &&
                responseJson != null &&
                responseJson['code'] == 'invalid_user_password') {
              if (!completer.isCompleted) {
                completer.completeError(
                  ConnectionException(
                    ConnectionExceptionType.invalidLoginCredentials,
                  ),
                );
              }
            } else if (status >= 400) {
              if (!completer.isCompleted) {
                completer.completeError(
                  ConnectionException(ConnectionExceptionType.unknown),
                );
              }
            }
          }
          return AjaxRequestAction.PROCEED;
        },
      );

      await webview.navigate(
        URLRequest(
          url: WebUri('https://portalpersonas.bancochile.cl/persona/'),
        ),
        timeout: timeout,
      );

      final rutSelector = '#ppriv_per-login-click-input-rut';
      final passwordSelector = '#ppriv_per-login-click-input-password';

      await webview.waitForSelector(
        rutSelector,
        timeout: timeout,
        visible: true,
      );

      log("BancoChileService auth selector $rutSelector found");

      await webview.type(rutSelector, username, timeout: timeout);
      await webview.type(passwordSelector, password, timeout: timeout);

      // Listen for success URL or error selector
      final successCompleter = Completer<bool>();

      webview.addLoadResourceListener(
        RegExp(r'.*portalpersonas\.bancochile\.cl/mibancochile-web/.*'),
        () {
          if (!successCompleter.isCompleted) {
            successCompleter.complete(true);
          }
        },
      );

      // Check for error selector will be done after click

      await webview.click(
        '#ppriv_per-login-click-ingresar-login',
        timeout: timeout,
      );

      log("BancoChileService auth waiting for success...");

      // Wait for success with timeout
      try {
        await successCompleter.future.timeout(
          Duration(seconds: timeout.inSeconds * 3),
          onTimeout: () async {
            // Check manually for error before timing out
            try {
              final hasError = await webview.evaluate("""
                (function() {
                  const errorElement = document.querySelector('#errorPassword:not([hidden])');
                  return errorElement !== null;
                })();
              """);
              if (hasError == true) {
                throw Exception('Invalid credentials');
              }
            } catch (checkError) {
              if (checkError.toString().contains('Invalid credentials')) {
                rethrow;
              }
            }
            throw Exception('Timeout waiting for login success');
          },
        );
      } catch (e) {
        // Check if it's an error we want to propagate
        if (e.toString().contains('Invalid credentials') ||
            e.toString().contains('blocked')) {
          rethrow;
        }
        // Otherwise check manually for error
        try {
          final hasError = await webview.evaluate("""
            (function() {
              const errorElement = document.querySelector('#errorPassword:not([hidden])');
              return errorElement !== null;
            })();
          """);
          if (hasError == true) {
            throw Exception('Invalid credentials');
          }
        } catch (checkError) {
          if (checkError.toString().contains('Invalid credentials')) {
            rethrow;
          }
        }
        rethrow;
      }

      log("BancoChileService auth login successful, extracting cookies...");

      final cookies = await webview.cookies(
        urls: [Uri.parse('https://portalpersonas.bancochile.cl/')],
      );

      await webview.close();

      final cookieString = cookies
          .map((e) => '${e.name}=${e.value}')
          .join('; ');

      log("BancoChileService auth completed");

      return cookieString;
    } catch (e) {
      await webview.close();
      log('BancoChile auth error: $e');
      rethrow;
    }
  }

  @override
  Future<List<ExtractedProductModel>> getProducts(String cookiesString) async {
    try {
      final rawProducts = await _getRawProducts(cookiesString);
      final depositaryBalances = await _getDepositaryBalances(cookiesString);
      final cardsBalances = await _getCardsBalances(cookiesString);

      // Map to Product models
      return ClBancoChilePersonasProductMapper.fromProductsAndBalances(
        rawProducts,
        depositaryBalances,
        cardsBalances,
      );
    } catch (e) {
      log('Error fetching BancoChile products: $e');
      rethrow;
    }
  }

  /// Gets raw products
  Future<ClBancoChilePersonasProductsResponseModel> _getRawProducts(
    String cookiesString,
  ) async {
    try {
      final response = await _dio.get<dynamic>(
        'https://portalpersonas.bancochile.cl/mibancochile/rest/persona/selectorproductos/selectorProductos/obtenerProductos?incluirTarjetas=true',
        options: Options(
          headers: {
            'Host': 'portalpersonas.bancochile.cl',
            'Referer':
                'https://portalpersonas.bancochile.cl/mibancochile-web/front/persona/index.html',
            'Cookie': cookiesString,
          },
        ),
      );

      await _checkDioResponse(response);

      log('BancoChile raw products response: ${response.data}');

      return ClBancoChilePersonasProductsResponseModel.fromJson(
        response.data ?? {},
      );
    } on DioException catch (e) {
      await _checkDioException(e);
      log('Error fetching BancoChile raw products: $e');
      rethrow;
    }
  }

  /// Gets depositary balances
  Future<List<ClBancoChilePersonasDepositaryBalancesResponseModel>>
  _getDepositaryBalances(String cookiesString) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        'https://portalpersonas.bancochile.cl/mibancochile/rest/persona/bff-pp-prod-ctas-saldos/productos/cuentas/saldos',
        options: Options(
          headers: {
            'Host': 'portalpersonas.bancochile.cl',
            'Referer': 'https://portalpersonas.bancochile.cl/',
            'Cookie': cookiesString,
          },
        ),
      );

      if (response.data == null) {
        return [];
      }

      return response.data!
          .map(
            (e) =>
                ClBancoChilePersonasDepositaryBalancesResponseModel.fromJson(e),
          )
          .toList();
    } catch (e) {
      log('Error fetching BancoChile depositary balances: $e');
      rethrow;
    }
  }

  /// Gets cards balances
  Future<List<ClBancoChilePersonasCardsBalancesResponseModel>>
  _getCardsBalances(String cookiesString) async {
    try {
      final response = await _dio.post<List<dynamic>>(
        'https://portalpersonas.bancochile.cl/mibancochile/rest/persona/tarjetas/widget/saldos-tarjetas',
        data: <String, dynamic>{},
        options: Options(
          headers: {
            'Host': 'portalpersonas.bancochile.cl',
            'Referer': 'https://portalpersonas.bancochile.cl/',
            'Cookie': cookiesString,
          },
        ),
      );

      if (response.data == null) {
        return [];
      }

      return response.data!
          .map(
            (e) => ClBancoChilePersonasCardsBalancesResponseModel.fromJson(e),
          )
          .toList();
    } catch (e) {
      log('Error fetching BancoChile card balances: $e');
      rethrow;
    }
  }

  @override
  Future<List<ExtractedTransaction>> getDepositaryAccountTransactions(
    String credentials,
    String productId,
  ) async {
    try {
      final rawProducts = await _getRawProducts(credentials);
      final rawProductId =
          productId; // BancoChile productId is just the account ID

      final account = rawProducts.productos.firstWhere(
        (product) => product.id == rawProductId,
        orElse: () => throw Exception('Account not found'),
      );

      // Get movement configuration to determine available date range
      final config = await _getMovementConfigWithAccountInfo(
        credentials,
        rawProducts,
        account,
      );

      final useDates = false;

      // Use the configuration date range - convert milliseconds to ISO strings
      final startDate = useDates
          ? DateTime.fromMillisecondsSinceEpoch(
              config.fechaDesde ?? 0,
            ).toIso8601String()
          : null;
      final endDate = useDates
          ? DateTime.fromMillisecondsSinceEpoch(
              config.fechaHasta ?? 0,
            ).toIso8601String()
          : null;

      final transactions = await _getDepositaryAccountTransactionsByDate(
        credentials,
        rawProducts.nombre ?? '',
        rawProducts.rut ?? '',
        account,
        startDate,
        endDate,
      );

      return CommonsMapper.processTransactions(transactions);
    } catch (e) {
      log('Error fetching BancoChile depositary account transactions: $e');
      rethrow;
    }
  }

  /// Gets movement configuration with account info
  Future<ClBancoChilePersonasConfigConsultaMovimientosModel>
  _getMovementConfigWithAccountInfo(
    String cookiesString,
    ClBancoChilePersonasProductsResponseModel rawProducts,
    ClBancoChilePersonasProducto account,
  ) async {
    try {
      final requestBody = {
        'cuentasSeleccionadas': [
          {
            'nombreCliente': rawProducts.nombre,
            'rutCliente': rawProducts.rut,
            'numero': account.numero,
            'mascara': account.mascara,
            'selected': true,
            'codigoProducto': account.codigo,
            'claseCuenta': account.claseCuenta,
            'moneda': account.codigoMoneda,
          },
        ],
      };

      final response = await _dio.post(
        'https://portalpersonas.bancochile.cl/mibancochile/rest/persona/movimientos/getConfigConsultaMovimientos',
        data: requestBody,
        options: Options(
          headers: {
            'Host': 'portalpersonas.bancochile.cl',
            'Referer': 'https://portalpersonas.bancochile.cl/',
            'Cookie': cookiesString,
          },
        ),
      );

      _checkDioResponse(response);

      final responseData = response.data as Map<String, dynamic>?;
      if (responseData == null) {
        throw Exception('Empty response from movement config API');
      }

      return ClBancoChilePersonasConfigConsultaMovimientosModel.fromJson(
        responseData,
      );
    } catch (e) {
      log('Error fetching BancoChile movement config: $e');
      rethrow;
    }
  }

  /// Gets depositary account transactions by date range
  Future<List<ExtractedTransactionWithoutProviderId>>
  _getDepositaryAccountTransactionsByDate(
    String cookiesString,
    String nombreCliente,
    String rutCliente,
    ClBancoChilePersonasProducto account,
    String? startDate,
    String? endDate,
  ) async {
    try {
      final requestBody = {
        'cuentaSeleccionada': {
          'nombreCliente': nombreCliente,
          'rutCliente': rutCliente,
          'numero': account.numero,
          'mascara': account.mascara,
          'selected': true,
          'codigoProducto': account.codigo,
          'claseCuenta': account.claseCuenta,
          'moneda': account.codigoMoneda,
        },
        'cabecera': {
          'statusGenerico': true,
          'paginacionDesde': 1,
          'fechaInicio': startDate,
          'fechaFin': endDate,
        },
      };

      final response = await _dio.post(
        'https://portalpersonas.bancochile.cl/mibancochile/rest/persona/bff-pper-prd-cta-movimientos/movimientos/getCartola',
        data: requestBody,
        options: Options(
          headers: {
            'Host': 'portalpersonas.bancochile.cl',
            'Referer': 'https://portalpersonas.bancochile.cl/',
            'Cookie': cookiesString,
          },
        ),
      );

      _checkDioResponse(response);

      final responseData = response.data;

      final cartolaModel = ClBancoChilePersonasCartolaModel.fromJson(
        responseData as Map<String, dynamic>,
      );

      return ClBancoChilePersonasDepositaryTransactionMapper.fromCartolaModel(
        cartolaModel,
      );
    } on DioException catch (e) {
      log(
        'Error fetching BancoChile depositary account transactions by date: $e',
      );
      await _checkDioException(e);

      rethrow;
    }
  }

  @override
  Future<List<ExtractedCreditCardBillPeriod>> getCreditCardBillPeriods(
    String credentials,
    String productId,
  ) async {
    try {
      final rawProducts = await _getRawProducts(credentials);
      final rawProductId =
          productId; // BancoChile productId is just the card ID

      final card = rawProducts.productos.firstWhere(
        (card) => card.id == rawProductId,
        orElse: () => throw Exception('Card not found'),
      );

      final response = await _dio.post<Map<String, dynamic>>(
        'https://portalpersonas.bancochile.cl/mibancochile/rest/persona/tarjetas/estadocuenta/fechas-facturacion',
        data: {
          'idTarjeta': card.id,
          'codigoProducto': card.codigo,
          'tipoTarjeta': card.descripcionLogo,
          'mascara': card.mascara,
          'nombreTitular': card.tarjetaHabiente,
        },
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
                '(KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
            'Accept': 'application/json',
            'Accept-Language': 'es-ES,es;q=0.9',
            'Accept-Encoding': 'gzip, deflate, br',
            'Referer': 'https://portalpersonas.bancochile.cl/',
            'Cookie': credentials,
          },
        ),
      );

      final responseData = response.data;
      if (responseData == null) {
        throw Exception('Empty response from bill periods API');
      }

      final listaNacional =
          responseData['listaNacional'] as List<dynamic>? ?? [];
      final listaInternacional =
          responseData['listaInternacional'] as List<dynamic>? ?? [];

      final periods = <ExtractedCreditCardBillPeriod>[];

      // Map national periods
      for (final period in listaNacional) {
        final periodMap = period as Map<String, dynamic>;
        final fechaFacturacion = periodMap['fechaFacturacion'] as String?;
        if (fechaFacturacion == null) continue;

        final periodId = '${CurrencyType.national.name}_$fechaFacturacion';

        periods.add(
          ExtractedCreditCardBillPeriod(
            providerId: periodId,
            startDate: fechaFacturacion,
            endDate: null,
            currency: Currency.clp,
            currencyType: CurrencyType.national,
          ),
        );
      }

      // Map international periods
      for (final period in listaInternacional) {
        final periodMap = period as Map<String, dynamic>;
        final fechaFacturacion = periodMap['fechaFacturacion'] as String?;
        if (fechaFacturacion == null) continue;

        final periodId = '${CurrencyType.international.name}_$fechaFacturacion';

        periods.add(
          ExtractedCreditCardBillPeriod(
            providerId: periodId,
            startDate: fechaFacturacion,
            endDate: null,
            currency: Currency.usd,
            currencyType: CurrencyType.international,
          ),
        );
      }

      return periods;
    } catch (e) {
      log('Error fetching BancoChile card bill periods: $e');
      rethrow;
    }
  }

  @override
  Future<ExtractedCreditCardBill> getCreditCardBill(
    String credentials,
    String productId,
    String periodId,
  ) async {
    try {
      final periodParts = periodId.split('_');
      if (periodParts.length < 2) {
        throw Exception('Invalid period ID format');
      }
      final rawCurrencyType = periodParts[0];
      final rawPeriodId = periodParts[1];

      final currencyType = rawCurrencyType == CurrencyType.national.name
          ? CurrencyType.national
          : CurrencyType.international;

      final bytesPdf = await _getCreditCardBillPdfAsBytes(
        credentials,
        productId,
        currencyType,
        rawPeriodId,
      );
      final base64Pdf = base64Encode(bytesPdf);
      return ExtractedCreditCardBill(
        periodProviderId: periodId,
        currencyType: rawCurrencyType == CurrencyType.national.name
            ? CurrencyType.national
            : CurrencyType.international,
        summary: null,
        transactions: null,
        billDocumentBase64: base64Pdf,
      );
    } catch (e) {
      log('Error fetching BancoChile credit card bill: $e');
      rethrow;
    }
  }

  Future<Uint8List> _getCreditCardBillPdfAsBytes(
    String credentials,
    String productId,
    CurrencyType currencyType,
    String rawPeriodId,
  ) async {
    try {
      final rawProducts = await _getRawProducts(credentials);
      final rawProductId = productId;
      final card = rawProducts.productos.firstWhere(
        (card) => card.id == rawProductId,
        orElse: () => throw Exception('Card not found'),
      );

      // Get billing periods to get numeroCuenta
      final billingPeriodsResponse = await _dio.post<Map<String, dynamic>>(
        'https://portalpersonas.bancochile.cl/mibancochile/rest/persona/tarjetas/estadocuenta/fechas-facturacion',
        data: {
          'idTarjeta': card.id,
          'codigoProducto': card.codigo,
          'tipoTarjeta': card.descripcionLogo,
          'mascara': card.mascara,
          'nombreTitular': card.tarjetaHabiente,
        },
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
                '(KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
            'Accept': 'application/json',
            'Accept-Language': 'es-ES,es;q=0.9',
            'Referer': 'https://portalpersonas.bancochile.cl/',
            'Cookie': credentials,
          },
        ),
      );

      final numeroCuentaUrlDecoded = Uri.decodeComponent(
        billingPeriodsResponse.data?['numeroCuenta'] as String? ?? '',
      );

      final requestBody = {
        'idTarjeta': card.id,
        'fechaFacturacion': rawPeriodId,
        'esNacional': currencyType == CurrencyType.national,
        'numeroCuenta': numeroCuentaUrlDecoded,
        'esImprimir': false,
      };

      final response = await _dio.post(
        'https://portalpersonas.bancochile.cl/mibancochile/rest/persona/tarjetas/estadocuenta/pdf',
        data: requestBody,
        options: Options(
          headers: {
            'Accept': 'application/json, text/plain, */*',
            'Accept-Language': 'es-419,es;q=0.8',
            'Connection': 'keep-alive',
            'Content-Type': 'application/json',
            'Origin': 'https://portalpersonas.bancochile.cl',
            'Referer':
                'https://portalpersonas.bancochile.cl/mibancochile-web/front/persona/index.html',
            'Sec-Fetch-Dest': 'empty',
            'Sec-Fetch-Mode': 'cors',
            'Sec-Fetch-Site': 'same-origin',
            'Sec-GPC': '1',
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Mobile Safari/537.36',
            'Cookie': credentials,
          },
          responseType: ResponseType.bytes,
        ),
      );

      return Uint8List.fromList(response.data as List<int>);
    } catch (e) {
      log('Error fetching BancoChile credit card bill PDF: $e');
      rethrow;
    }
  }

  @override
  Future<List<ExtractedTransaction>> getCreditCardUnbilledTransactions(
    String credentials,
    String productId,
    CurrencyType transactionType,
  ) async {
    try {
      final rawProducts = await _getRawProducts(credentials);
      final rawProductId =
          productId; // BancoChile productId is just the card ID

      final card = rawProducts.productos.firstWhere(
        (card) => card.id == rawProductId,
        orElse: () => throw Exception('Card not found'),
      );

      final requestBody = {
        'idTarjeta': card.id,
        'codigoProducto': card.codigo,
        'tipoTarjeta': card.descripcionLogo,
        'mascara': card.mascara,
        'nombreTitular': card.tarjetaHabiente,
        'tipoCliente': (card.tipoCliente ?? '').toUpperCase().isNotEmpty
            ? (card.tipoCliente ?? '').toUpperCase().substring(0, 1)
            : '',
      };

      final response = await _dio.post(
        'https://portalpersonas.bancochile.cl/mibancochile/rest/persona/tarjeta-credito-digital/movimientos-no-facturados',
        data: requestBody,
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
                '(KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
            'Accept': 'application/json',
            'Accept-Language': 'es-ES,es;q=0.9',
            'Accept-Encoding': 'gzip, deflate, br',
            'Referer': 'https://portalpersonas.bancochile.cl/',
            'Cookie': credentials,
          },
        ),
      );

      _checkDioResponse(response);

      final responseData = response.data as Map<String, dynamic>?;
      if (responseData == null) {
        throw Exception('Empty response from unbilled transactions API');
      }

      final unbilledModel =
          ClBancoChilePersonasMovimientosNoFacturadosModel.fromJson(
            responseData,
          );

      final transactions =
          ClBancoChilePersonasCreditCardUnbilledTransactionMapper.fromUnbilledTransactionModel(
            unbilledModel,
          );

      final filteredTransactions = transactions
          .where(
            (transaction) => transaction.billingCurrencyType == transactionType,
          )
          .toList();

      return CommonsMapper.processTransactions(filteredTransactions);
    } catch (e) {
      log('Error fetching BancoChile credit card unbilled transactions: $e');
      rethrow;
    }
  }

  Future<void> _checkDioResponse(Response<dynamic> response) async {
    if (response.data == null) {
      throw ConnectionException(ConnectionExceptionType.authCredentialsExpired);
    }
    if (response.data is String && response.data.startsWith('<html>')) {
      throw ConnectionException(ConnectionExceptionType.authCredentialsExpired);
    }
  }

  Future<void> _checkDioException(DioException exception) async {
    if (exception.response?.statusCode != null &&
            (exception.response!.statusCode! >= 300 &&
                exception.response!.statusCode! < 400) ||
        exception.response?.statusCode == 500) {
      throw ConnectionException(ConnectionExceptionType.authCredentialsExpired);
    }
    log('Error fetching BancoChile: $exception');
  }
}
