import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:pan_scrapper/entities/extraction.dart';
import 'package:pan_scrapper/models/connection/extracted_connection_result_model.dart';
import 'package:pan_scrapper/models/execute_link_token_result_model.dart';
import 'package:pan_scrapper/models/institution_model.dart';
import 'package:pan_scrapper/models/link_intent_model.dart';

abstract class ApiService {
  Future<List<InstitutionModel>> fetchInstitutions({required String publicKey});
  Future<LinkIntentResponseModel> fetchLinkIntent({
    required String linkToken,
    required String publicKey,
  });
  Future<ExecuteLinkTokenResultModel> executeLinkToken({
    required String linkToken,
    required ExtractedConnectionResultModel connectionResult,
    required String publicKey,
  });
  Future<void> submitExtractions({
    required List<Extraction> extractions,
    required String connectionId,
    required String publicKey,
  });
}

class ApiServiceImpl extends ApiService {
  final Dio _dio;

  ApiServiceImpl(this._dio);

  static const _baseUrl =
      "https://hw4x6tsju2.execute-api.us-east-1.amazonaws.com/dev";

  @override
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

  @override
  /// Fetches the current link intent from the API
  Future<LinkIntentResponseModel> fetchLinkIntent({
    required String linkToken,
    required String publicKey,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$_baseUrl/api/link-intents/current',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Link-Widget-Token': linkToken,
            'Authorization': 'Bearer $publicKey',
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

  @override
  Future<ExecuteLinkTokenResultModel> executeLinkToken({
    required String linkToken,
    required ExtractedConnectionResultModel connectionResult,
    required String publicKey,
  }) async {
    final body = connectionResult.toJson();

    log('body: ${jsonEncode(body)}');

    final response = await _dio.post<Map<String, dynamic>>(
      '$_baseUrl/api/link-intents/execute',
      data: body,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'X-Link-Widget-Token': linkToken,
          'Authorization': 'Bearer $publicKey',
        },
      ),
    );

    final data = response.data?['data'];
    if (data == null) {
      throw Exception('Empty response from execute link token API');
    }

    return ExecuteLinkTokenResultModel.fromJson(data);
  }

  @override
  Future<void> submitExtractions({
    required List<Extraction> extractions,
    required String publicKey,
    required String connectionId,
  }) async {
    final body = {
      'extractions': extractions.map((e) => e.toJson()).toList(),
      'connectionId': connectionId,
    };

    log('submitExtractions body: ${jsonEncode(body)}');

    final response = await _dio.post<Map<String, dynamic>>(
      '$_baseUrl/api/institution/extractions',
      data: body,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $publicKey',
        },
      ),
    );

    final data = response.data?['data'];
    if (data == null) {
      throw Exception('Empty response from submit extractions API');
    }

    return data;
  }
}
