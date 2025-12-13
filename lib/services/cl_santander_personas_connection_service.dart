import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pan_scrapper/mappers/cl_santander_personas/product_mapper.dart';
import 'package:pan_scrapper/models/product.dart';
import 'package:pan_scrapper/services/connection_service.dart';
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

  /// Fetches card devices management for the given document number and JWT
  Future<ClSantanderPersonasCardDevicesManagementResponse>
  _getCardDevicesManagement({
    required ClSantanderPersonasPropertiesResponseModel properties,
    required String rut,
    required String jwt,
    String? optionCall,
    String? debitOrCreditCard,
    String? flagRecall,
    String? dataRecall,
  }) async {
    try {
      final xSantanderClientId = properties.xSantanderClientId;

      final queryParameters = <String, dynamic>{
        'document_number': rut,
        if (optionCall != null) 'option_call': optionCall,
        if (debitOrCreditCard != null)
          'debit_or_credit_card': debitOrCreditCard,
        if (flagRecall != null) 'flag_recall': flagRecall,
        if (dataRecall != null) 'data_recall': dataRecall,
      };

      final response = await _dio.get<Map<String, dynamic>>(
        'https://openbanking.santander.cl/card_authorization/card_authorization/v1/cards/card_devices_management',
        queryParameters: queryParameters,
        options: Options(
          headers: {
            'accept': 'application/json, text/plain, */*',
            'accept-language': 'es-419,es;q=0.9',
            'authorization': 'Bearer $jwt',
            'content-type': 'application/json',
            'origin': 'https://mibanco.santander.cl',
            'priority': 'u=1, i',
            'referer': 'https://mibanco.santander.cl/',
            'sec-ch-ua':
                '"Chromium";v="142", "Brave";v="142", "Not_A Brand";v="99"',
            'sec-ch-ua-mobile': '?1',
            'sec-ch-ua-platform': '"Android"',
            'sec-fetch-dest': 'empty',
            'sec-fetch-mode': 'cors',
            'sec-fetch-site': 'same-site',
            'sec-gpc': '1',
            'user-agent':
                'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Mobile Safari/537.36',
            'x-santander-client-id': xSantanderClientId,
          },
        ),
      );

      final responseData = response.data;
      if (responseData == null) {
        throw Exception('Empty response from card devices management API');
      }

      return ClSantanderPersonasCardDevicesManagementResponse.fromJson(
        responseData,
      );
    } catch (e) {
      log('Error fetching card devices management: $e');
      rethrow;
    }
  }
}
