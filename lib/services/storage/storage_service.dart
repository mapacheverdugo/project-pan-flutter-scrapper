import 'dart:convert';
import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pan_scrapper/constants/storage_keys.dart';
import 'package:pan_scrapper/models/local_connection_model.dart';

abstract class StorageService {
  Future<List<LocalConnectionModel>> saveNewConnection(
    LocalConnectionModel connection,
  );
  Future<List<LocalConnectionModel>> getSavedConnections();
  Future<LocalConnectionModel?> getConnectionById(String id);
  Future<bool> hasConnections();
  Future<void> deleteConnection(String id);
  Future<void> updateLastSyncDateTime(String connectionId, DateTime dateTime);

  Future<void> saveConnectionCredentials(
    String connectionId,
    String credentials,
  );
  Future<String?> getConnectionCredentials(String connectionId);
  Future<void> deleteConnectionCredentials(String connectionId);
}

class StorageServiceImpl extends StorageService {
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  StorageServiceImpl();

  @override
  Future<List<LocalConnectionModel>> saveNewConnection(
    LocalConnectionModel connection,
  ) async {
    final currentConnections = await getSavedConnections();

    currentConnections.add(connection);

    final newConnectionsJson = jsonEncode(currentConnections);
    await _storage.write(key: connectionsKey, value: newConnectionsJson);

    return currentConnections;
  }

  @override
  Future<List<LocalConnectionModel>> getSavedConnections() async {
    var currentConnections = <LocalConnectionModel>[];

    final connectionsJsonString = await _storage.read(key: connectionsKey);
    if (connectionsJsonString != null && connectionsJsonString.isNotEmpty) {
      final connectionsJson = jsonDecode(connectionsJsonString);
      try {
        currentConnections = connectionsJson
            .map<LocalConnectionModel>((e) => LocalConnectionModel.fromJson(e))
            .toList();
      } catch (e) {
        log('Error parsing connections: ${e.toString()}');
      }
    }

    return currentConnections;
  }

  @override
  Future<LocalConnectionModel?> getConnectionById(String id) async {
    final currentConnections = await getSavedConnections();
    return currentConnections.firstWhereOrNull((e) => e.id == id);
  }

  @override
  Future<bool> hasConnections() async {
    final currentConnections = await getSavedConnections();
    return currentConnections.isNotEmpty;
  }

  @override
  Future<void> deleteConnection(String id) async {
    final currentConnections = await getSavedConnections();
    final newConnections = currentConnections.where((e) => e.id != id).toList();
    final newConnectionsJson = jsonEncode(newConnections);
    await _storage.write(key: connectionsKey, value: newConnectionsJson);
  }

  @override
  Future<void> updateLastSyncDateTime(String connectionId, DateTime dateTime) async {
    final currentConnections = await getSavedConnections();
    final connectionIndex = currentConnections.indexWhere((e) => e.id == connectionId);
    
    if (connectionIndex == -1) {
      throw Exception('Connection not found');
    }

    final updatedConnection = LocalConnectionModel(
      id: currentConnections[connectionIndex].id,
      institutionCode: currentConnections[connectionIndex].institutionCode,
      rawUsername: currentConnections[connectionIndex].rawUsername,
      password: currentConnections[connectionIndex].password,
      lastSyncDateTime: dateTime,
    );

    currentConnections[connectionIndex] = updatedConnection;
    final newConnectionsJson = jsonEncode(currentConnections);
    await _storage.write(key: connectionsKey, value: newConnectionsJson);
  }

  @override
  Future<void> saveConnectionCredentials(
    String connectionId,
    String credentials,
  ) async {
    await _storage.write(
      key: '$connectionCredentialsKeyPreffix$connectionId',
      value: credentials,
    );
  }

  @override
  Future<String?> getConnectionCredentials(String connectionId) async {
    return await _storage.read(
      key: '$connectionCredentialsKeyPreffix$connectionId',
    );
  }

  @override
  Future<void> deleteConnectionCredentials(String connectionId) async {
    await _storage.delete(key: '$connectionCredentialsKeyPreffix$connectionId');
  }
}
