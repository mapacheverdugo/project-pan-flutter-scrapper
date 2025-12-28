import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pan_scrapper/models/index.dart';
import 'package:pan_scrapper/services/connection_service.dart';
import 'package:pan_scrapper/webview/webview.dart';

class ClBciPersonasConnectionService extends ConnectionService {
  late final Dio _dio;
  final Future<WebviewInstance> Function() _webviewFactory;

  static const _baseUrl =
      'https://apilocal.bci.cl/bci-produccion/api-bci/bff-saldosyultimosmovimientoswebpersonas/v3.2';
  static const _creditCardBaseUrl =
      'https://apilocal.bci.cl/bci-produccion/api-bci';

  ClBciPersonasConnectionService(this._dio, this._webviewFactory);

  @override
  Future<String> auth(String username, String password) async {
    final completer = Completer<String>();
    final webview = await _webviewFactory();

    try {
      log("BciService auth before navigate");

      // Listen for navigation to the token redirect URL
      webview.addLoadResourceListener(
        RegExp(
          r'https://personas\.bci\.cl/nuevaWeb/fe-saldoscashback/\?token=',
        ),
        () async {
          // Extract token from current URL via JavaScript evaluation
          try {
            final result = await webview.evaluate("""
              (function() {
                const url = window.location.href;
                if (url.includes('token=')) {
                  const token = url.split('token=')[1].split('&')[0];
                  return token;
                }
                return null;
              })();
            """);
            if (result != null &&
                result.toString().isNotEmpty &&
                !completer.isCompleted) {
              completer.complete(result.toString());
            }
          } catch (e) {
            log('Error extracting token from URL: $e');
          }
        },
      );

      // Listen for error redirects
      webview.addLoadResourceListener(
        RegExp(r'https://www\.bci\.cl/personas/acceso-inhabilitado'),
        () {
          if (!completer.isCompleted) {
            completer.completeError(Exception('Credentials blocked'));
          }
        },
      );

      webview.addLoadResourceListener(
        RegExp(r'http://www\.bci\.cl/personas/clave_invalida'),
        () {
          if (!completer.isCompleted) {
            completer.completeError(Exception('Invalid credentials'));
          }
        },
      );

      webview.addLoadResourceListener(
        RegExp(
          r'https://www\.bci\.cl/cl/bci/aplicaciones/seguridad/autenticacion/autenticacionBciPass',
        ),
        () {
          if (!completer.isCompleted) {
            completer.completeError(Exception('Auth detected before password'));
          }
        },
      );

      await webview.navigate(
        URLRequest(
          url: WebUri('https://www.bci.cl/corporativo/banco-en-linea/personas'),
        ),
      );

      log("BciService auth after navigate");

      final rutSelector = '#rut_aux';
      final passwordSelector = '#clave';

      await webview.waitForSelector(
        rutSelector,
        timeout: Duration(seconds: 30),
      );

      log("BciService auth selector $rutSelector found");

      await webview.type(
        rutSelector,
        username,
        timeout: Duration(seconds: 5),
        delay: Duration(milliseconds: 100),
        minVariation: Duration(milliseconds: 50),
        maxVariation: Duration(milliseconds: 150),
      );
      await webview.type(
        passwordSelector,
        password,
        timeout: Duration(seconds: 5),
        delay: Duration(milliseconds: 100),
        minVariation: Duration(milliseconds: 50),
        maxVariation: Duration(milliseconds: 150),
      );

      await webview.click(
        "#frm button[type='submit']",
        timeout: Duration(seconds: 5),
      );

      log("BciService auth waiting for token...");

      // Wait for token with timeout
      final token = await completer.future.timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout waiting for token');
        },
      );

      log("BciService auth completed with token: ${token.substring(0, 20)}...");

      await webview.close();

      return token;
    } catch (e) {
      await webview.close();
      log('BCI auth error: $e');
      rethrow;
    }
  }

  @override
  Future<List<Product>> getProducts(String token) async {
    try {
      // Get depositary accounts
      final depositaryAccounts = await _getDepositaryAccounts(token);

      // Get cards with details
      final cardsWithDetails = await _getCardsWithDetails(token);

      // Map to Product models
      // TODO: Create BCI product mapper and models
      // Once models are created, uncomment and implement:
      // final parsedDepositaryAccounts =
      //     ClBciPersonasProductMapper.fromDepositaryAccounts(depositaryAccounts);
      // final parsedCards =
      //     ClBciPersonasProductMapper.fromCreditCards(cardsWithDetails);
      // return [...parsedDepositaryAccounts, ...parsedCards];

      // Temporary: return empty list until mapper is implemented
      log(
        'BCI getProducts: depositaryAccounts=${depositaryAccounts.length}, cardsWithDetails=${cardsWithDetails.length}',
      );
      throw UnimplementedError(
        'BCI product mapper not yet implemented. Models and mapper need to be created.',
      );
    } catch (e) {
      log('Error fetching BCI products: $e');
      rethrow;
    }
  }

  /// Extracts RUT from JWT token
  String _extractRutFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) {
        throw Exception('Invalid token format');
      }
      final payload = utf8.decode(base64Url.decode(parts[1]));
      final decoded = jsonDecode(payload) as Map<String, dynamic>;
      return decoded['rut_cliente'] as String? ??
          decoded['username'] as String? ??
          '';
    } catch (e) {
      log('Error extracting RUT from token: $e');
      throw Exception('Unable to extract RUT from token');
    }
  }

  /// Gets depositary accounts
  Future<List<Map<String, dynamic>>> _getDepositaryAccounts(
    String token,
  ) async {
    try {
      final rut = _extractRutFromToken(token);

      // First, get the list of accounts by RUT
      final searchResponse = await _dio.post<Map<String, dynamic>>(
        '$_baseUrl/cuentas-busquedas/por-rut',
        data: {'rut': rut},
        options: Options(headers: _getBaseHeaders(token)),
      );

      if (searchResponse.data == null) {
        return [];
      }

      final cuentas = searchResponse.data!['cuentas'] as List<dynamic>? ?? [];

      // Then, get details for each account
      final accountDetails = await Future.wait(
        cuentas.map((account) => _getDepositaryAccountDetail(token, account)),
      );

      return accountDetails;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Credentials expired - needs reauth');
      }
      log('Error fetching BCI depositary accounts: $e');
      rethrow;
    }
  }

  /// Gets depositary account detail
  Future<Map<String, dynamic>> _getDepositaryAccountDetail(
    String token,
    dynamic basic,
  ) async {
    try {
      final accountNumber =
          (basic as Map<String, dynamic>)['numero'] as String?;
      if (accountNumber == null) {
        throw Exception('Account number is required');
      }

      final response = await _dio.post<Map<String, dynamic>>(
        '$_baseUrl/cuentas-busquedas/por-numero-cuenta',
        data: {'cuentaNumero': accountNumber},
        options: Options(headers: _getBaseHeaders(token)),
      );

      return {'basic': basic, 'detail': response.data};
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Credentials expired - needs reauth');
      }
      log('Error fetching BCI account detail: $e');
      rethrow;
    }
  }

  /// Gets cards balances
  Future<List<Map<String, dynamic>>> _getCardsBalances(String token) async {
    try {
      final response = await _dio.post<List<dynamic>>(
        '$_creditCardBaseUrl/operaciones-y-ejecucion/tarjetas/ms-estadocuentapersonasweb-exp/v1.3/estado-cuenta-tc/consultar-tarjetas',
        data: <String, dynamic>{},
        options: Options(headers: _getCreditCardHeaders(token)),
      );

      if (response.data == null) {
        return [];
      }

      return response.data!.map((e) => e as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Credentials expired - needs reauth');
      }

      if (e.response?.statusCode == 460) {
        final data = e.response?.data;
        if (data is Map<String, dynamic> && data['codigo'] == '002') {
          return [];
        }
      }

      log('Error fetching BCI credit cards: $e');
      rethrow;
    }
  }

  /// Gets card detail
  Future<Map<String, dynamic>> _getCardDetail(
    String token,
    String cardNumber,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_creditCardBaseUrl/bff-tarjetaswebpersona/v2.3/tarjetas-credito/consultar-cupo',
        data: {'numeroTarjeta': cardNumber},
        options: Options(headers: _getCardDetailHeaders(token)),
      );

      return response.data ?? {};
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Credentials expired - needs reauth');
      }
      log('Error fetching BCI card detail: $e');
      rethrow;
    }
  }

  /// Gets cards with their details
  Future<List<Map<String, dynamic>>> _getCardsWithDetails(String token) async {
    final cards = await _getCardsBalances(token);
    final cardsWithDetails = await Future.wait(
      cards.map((card) async {
        final cardNumber = card['numeroTarjeta'] as String? ?? '';
        final details = await _getCardDetail(token, cardNumber);
        return {'base': card, 'details': details};
      }),
    );

    return cardsWithDetails;
  }

  /// Base headers for depositary account requests
  Map<String, String> _getBaseHeaders(String token) {
    return {
      'accept': 'application/json, text/plain, */*',
      'accept-language': 'es-419,es;q=0.7',
      'application-id': '1',
      'channel': '110',
      'origin': 'https://personas.bci.cl',
      'origin-addr': '10.252.144.146',
      'priority': 'u=1, i',
      'reference-operation': 'refope',
      'reference-service': 'refser',
      'referer': 'https://personas.bci.cl/',
      'sec-ch-ua': '"Chromium";v="136", "Brave";v="136", "Not.A/Brand";v="99"',
      'sec-ch-ua-mobile': '?1',
      'sec-ch-ua-platform': '"Android"',
      'sec-fetch-dest': 'empty',
      'sec-fetch-mode': 'cors',
      'sec-fetch-site': 'same-site',
      'sec-gpc': '1',
      'tracking-id': '1',
      'user-agent':
          'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Mobile Safari/537.36',
      'x-ibm-client-id': '3034b362-00e0-4cb6-977a-c901201b9c5e',
      'content-type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Headers for credit card requests
  Map<String, String> _getCreditCardHeaders(String token) {
    return {
      'accept': 'application/json, text/plain, */*',
      'accept-language': 'es-419,es;q=0.7',
      'application-id': 'fe-estadocuenta-v1.3',
      'channel': '110',
      'origin': 'https://personas.bci.cl',
      'origin-addr': '127.0.0.1',
      'priority': 'u=1, i',
      'reference-operation': 'fe-estadocuenta-v1.3',
      'reference-service': 'fe-estadocuenta-v1.3',
      'referer': 'https://personas.bci.cl/',
      'sec-ch-ua': '"Chromium";v="136", "Brave";v="136", "Not.A/Brand";v="99"',
      'sec-ch-ua-mobile': '?1',
      'sec-ch-ua-platform': '"Android"',
      'sec-fetch-dest': 'empty',
      'sec-fetch-mode': 'cors',
      'sec-fetch-site': 'same-site',
      'sec-gpc': '1',
      'user-agent':
          'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Mobile Safari/537.36',
      'x-ibm-client-id': 'uAvQ5Z4d9M8u0X5x7MxN1NzjL0qpEYsT',
      'content-type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Headers for card detail requests
  Map<String, String> _getCardDetailHeaders(String token) {
    return {
      'accept': 'application/json, text/plain, */*',
      'accept-language': 'es-419,es;q=0.7',
      'application-id': 'fe-mistarjetascredito',
      'channel': '110',
      'origin': 'https://personas.bci.cl',
      'origin-addr': '127.0.0.1',
      'priority': 'u=1, i',
      'reference-operation': 'ConsultarCupoTDC',
      'reference-service': 'ConsultarCupoTDC',
      'referer': 'https://personas.bci.cl/',
      'sec-ch-ua': '"Chromium";v="136", "Brave";v="136", "Not.A/Brand";v="99"',
      'sec-ch-ua-mobile': '?1',
      'sec-ch-ua-platform': '"Android"',
      'sec-fetch-dest': 'empty',
      'sec-fetch-mode': 'cors',
      'sec-fetch-site': 'same-site',
      'sec-gpc': '1',
      'tracking-id': '1',
      'user-agent':
          'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Mobile Safari/537.36',
      'x-ibm-client-id': '613ce065-b8db-4283-b4eb-cc3d909f543a',
      'content-type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<List<Transaction>> getDepositaryAccountTransactions(
    String credentials,
    String productId,
  ) async {
    throw UnimplementedError(
      'BCI depositary account transactions not implemented',
    );
  }

  @override
  Future<List<CreditCardBillPeriod>> getCreditCardBillPeriods(
    String credentials,
    String productId,
  ) async {
    try {
      // Parse productId: format is "accountNumber_cardNumber"
      final parts = productId.split('_');
      if (parts.length < 2) {
        throw Exception('Invalid product ID format');
      }
      final accountNumber = parts[0];
      final cardNumber = parts[1];

      // Get both national and international bill periods
      final nationalPeriods = await _getCardBillPeriodsByStatementType(
        credentials,
        accountNumber,
        cardNumber,
        'nacional',
      );
      final internationalPeriods = await _getCardBillPeriodsByStatementType(
        credentials,
        accountNumber,
        cardNumber,
        'internacional',
      );

      final allPeriods = <CreditCardBillPeriod>[];

      // Map national periods
      for (final periodDate in nationalPeriods) {
        // Convert DD/MM/YYYY to ISO date
        final dateParts = periodDate.split('/');
        if (dateParts.length == 3) {
          final isoDate =
              '${dateParts[2]}-${dateParts[1].padLeft(2, '0')}-${dateParts[0].padLeft(2, '0')}';
          final periodId = '$productId|$isoDate|${CurrencyType.national.name}';
          allPeriods.add(
            CreditCardBillPeriod(
              id: periodId,
              startDate: isoDate,
              endDate: null,
              currency: 'CLP',
              currencyType: CurrencyType.national,
            ),
          );
        }
      }

      // Map international periods
      for (final periodDate in internationalPeriods) {
        final dateParts = periodDate.split('/');
        if (dateParts.length == 3) {
          final isoDate =
              '${dateParts[2]}-${dateParts[1].padLeft(2, '0')}-${dateParts[0].padLeft(2, '0')}';
          final periodId =
              '$productId|$isoDate|${CurrencyType.international.name}';
          allPeriods.add(
            CreditCardBillPeriod(
              id: periodId,
              startDate: isoDate,
              endDate: null,
              currency: 'USD',
              currencyType: CurrencyType.international,
            ),
          );
        }
      }

      return allPeriods;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Credentials expired - needs reauth');
      }
      log('Error fetching BCI card bill periods: $e');
      rethrow;
    } catch (e) {
      log('Error fetching BCI card bill periods: $e');
      rethrow;
    }
  }

  Future<List<String>> _getCardBillPeriodsByStatementType(
    String token,
    String accountNumber,
    String cardNumber,
    String statementType,
  ) async {
    try {
      final response = await _dio.post<List<dynamic>>(
        '$_creditCardBaseUrl/operaciones-y-ejecucion/tarjetas/ms-estadocuentapersonasweb-exp/v1.3/estado-cuenta-tc/consultar-periodos',
        data: {
          'numeroCuenta': accountNumber,
          'numeroTarjeta': cardNumber,
          'tipoEstadoCuenta': statementType,
        },
        options: Options(headers: _getCreditCardHeaders(token)),
      );

      if (response.data == null) {
        return [];
      }

      return response.data!.map((e) => e.toString()).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Credentials expired - needs reauth');
      }
      log('Error fetching BCI card bill periods by type: $e');
      rethrow;
    }
  }

  @override
  Future<CreditCardBill> getCreditCardBill(
    String credentials,
    String productId,
    String periodId,
  ) async {
    throw UnimplementedError('BCI credit card bill not implemented');
  }

  @override
  Future<Uint8List> getCreditCardBillPdf(
    String credentials,
    String productId,
    String periodId,
  ) async {
    try {
      // Parse periodId: format is "productId|billingDate|currencyType"
      final periodParts = periodId.split('|');
      if (periodParts.length < 3) {
        throw Exception('Invalid period ID format');
      }
      final rawBillingDate = periodParts[1];
      final rawCurrencyType = periodParts[2];

      // Parse productId
      final productParts = productId.split('_');
      if (productParts.length < 1) {
        throw Exception('Invalid product ID format');
      }
      final rawAccountNumber = productParts[0];

      final type = rawCurrencyType == CurrencyType.national.name
          ? 'nacional'
          : 'internacional';

      // Convert ISO date (YYYY-MM-DD) to DD/MM/YYYY
      final dateParts = rawBillingDate.split('-');
      final formattedDate = '${dateParts[2]}/${dateParts[1]}/${dateParts[0]}';

      final requestBody = {
        'numeroCuenta': rawAccountNumber,
        'tipoEstadoCuenta': type,
        'periodo': formattedDate,
      };

      final response = await _dio.post<String>(
        '$_creditCardBaseUrl/operaciones-y-ejecucion/tarjetas/ms-estadocuentapersonasweb-exp/v1.3/estado-cuenta-tc/pdf',
        data: requestBody,
        options: Options(
          headers: _getCreditCardHeaders(credentials),
          responseType: ResponseType.plain,
        ),
      );

      // Decode base64 to bytes
      final base64Data = response.data ?? '';
      final bytes = base64Decode(base64Data);
      return Uint8List.fromList(bytes);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Credentials expired - needs reauth');
      }
      log('Error fetching BCI credit card bill PDF: $e');
      rethrow;
    } catch (e) {
      log('Error fetching BCI credit card bill PDF: $e');
      rethrow;
    }
  }
}
