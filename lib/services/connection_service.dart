import 'package:pan_scrapper/models/product.dart';

abstract class ConnectionService {
  Future<String> auth(String username, String password);
  Future<List<Product>> getProducts(String credentials);
}
