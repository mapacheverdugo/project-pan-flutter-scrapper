import 'package:pan_scrapper/webview/webview.dart';

abstract class ConnectionService {
  Future<String> auth(
    WebviewInstance webview,
    String username,
    String password,
  );
  Future<String> getProducts(WebviewInstance webview, String credentials);
}
