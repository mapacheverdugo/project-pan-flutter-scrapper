import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class StorageService {
  Future<void> saveString(String key, String value);
  Future<String?> getString(String key);
  Future<void> delete(String key);
}

class StorageServiceImpl extends StorageService {
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  StorageServiceImpl();

  @override
  Future<void> saveString(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  @override
  Future<String?> getString(String key) async {
    return await _storage.read(key: key);
  }

  @override
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }
}
