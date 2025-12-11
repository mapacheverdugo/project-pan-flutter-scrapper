import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pan_scrapper/models/institution.dart';
import 'package:pan_scrapper/services/connection_service.dart';
import 'package:pan_scrapper/webview/webview.dart';

import 'services/index.dart';

class PanScrapperService {
  final Institution institution;
  final BuildContext context;
  final bool headless;

  late final ConnectionService _client;
  late final Dio _dio;
  WebviewInstance? _webview;

  PanScrapperService({
    required this.context,
    required this.institution,
    this.headless = true,
  }) {
    _dio = Dio();

    switch (institution) {
      case Institution.bci:
        _client = ClBciPersonasConnectionService(_dio);
        break;
      case Institution.santander:
        _client = ClSantanderPersonasConnectionService(_dio);
        break;
      case Institution.scotiabank:
        _client = ClScotiabankPersonasConnectionService(_dio);
        break;
    }
  }

  Future<WebviewInstance> _getWebview() async {
    _webview ??= await Webview.run(
      headless: headless,
      context: context,
      builder: (context, webview) => Scaffold(appBar: AppBar(), body: webview),
    );
    return _webview!;
  }

  Future<String> auth(String username, String password) async {
    return _client.auth(await _getWebview(), username, password);
  }

  Future<String> getProducts(String credentials) async {
    return _client.getProducts(await _getWebview(), credentials);
  }
}
