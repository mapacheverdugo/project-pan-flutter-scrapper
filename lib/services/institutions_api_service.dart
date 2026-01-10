import 'package:dio/dio.dart';
import 'package:pan_scrapper/models/institution_model.dart';
import 'package:pan_scrapper/models/link_intent_model.dart';

/// Service to fetch institutions and link intents from the API
class InstitutionsApiService {
  final Dio _dio;

  InstitutionsApiService(this._dio);

  static const _baseUrl =
      "https://hw4x6tsju2.execute-api.us-east-1.amazonaws.com/dev";

  /// Fetches institutions from the API
  Future<List<InstitutionModel>> fetchInstitutions({
    required String publicKey,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '$_baseUrl/api/institutions',
        queryParameters: {'includeExperimentalInstitutions': false},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $publicKey',
          },
        ),
      );

      final data = response.data;
      if (data == null) {
        throw Exception('Empty response from institutions API');
      }

      // Handle both cases: direct list or wrapped in an object
      final List<dynamic> institutions;
      if (data is List) {
        // Response is a direct list
        institutions = data;
      } else if (data is Map<String, dynamic>) {
        // Response is wrapped in an object
        institutions =
            (data['institutions'] as List<dynamic>?) ??
            (data['data'] as List<dynamic>?) ??
            <dynamic>[];
        if (institutions.isEmpty) {
          throw Exception('Invalid response format: missing institutions');
        }
      } else {
        throw Exception('Invalid response format: expected list or map');
      }

      return institutions
          .map(
            (inst) => InstitutionModel.fromJson(inst as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          'Failed to fetch institutions: ${e.response?.statusCode} - ${e.response?.statusMessage}',
        );
      }
      throw Exception('Failed to fetch institutions: ${e.message}');
    }
  }

  /// Fetches the current link intent from the API
  Future<LinkIntentResponseModel> fetchLinkIntent({
    required String linkToken,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/api/link-intents/current',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Link-Widget-Token': linkToken,
          },
        ),
      );

      final data = response.data;
      if (data == null) {
        throw Exception('Empty response from link intent API');
      }

      return LinkIntentResponseModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          'Failed to fetch link intent: ${e.response?.statusCode} - ${e.response?.statusMessage}',
        );
      }
      throw Exception('Failed to fetch link intent: ${e.message}');
    }
  }
}
