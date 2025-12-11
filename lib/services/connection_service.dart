import 'package:pan_scrapper/models/product.dart';
import 'package:pan_scrapper/webview/webview.dart';

abstract class ConnectionService {
  Future<String> auth(
    WebviewInstance webview,
    String username,
    String password,
  );
  Future<List<Product>> getProducts(
    WebviewInstance webview,
    String credentials,
  );
}
