import 'dart:developer';

import 'package:example/screens/connection_details_screen.dart';
import 'package:example/widget/local_connections.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pan_scrapper/entities/local_connection.dart';
import 'package:pan_scrapper/pan_connect.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _publicKeyController = TextEditingController();
  final TextEditingController _linkWidgetTokenController =
      TextEditingController();
  static const _storage = FlutterSecureStorage();
  static const _publicKeyStorageKey = 'public_key';

  @override
  void initState() {
    super.initState();
    _publicKeyController.addListener(_onPublicKeyChanged);
    _loadPublicKey();
  }

  void _onPublicKeyChanged() {
    setState(() {});
  }

  Future<void> _loadPublicKey() async {
    final publicKey = await _storage.read(key: _publicKeyStorageKey);
    if (publicKey != null && mounted) {
      setState(() {
        _publicKeyController.text = publicKey;
      });
    }
  }

  Future<void> _savePublicKey() async {
    final publicKey = _publicKeyController.text.trim();
    if (publicKey.isNotEmpty) {
      await _storage.write(key: _publicKeyStorageKey, value: publicKey);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Public Key saved')));
      }
    }
  }

  Future<void> _clearPublicKey() async {
    setState(() {
      _publicKeyController.clear();
    });
    await _storage.delete(key: _publicKeyStorageKey);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Public Key cleared')));
    }
  }

  Future<void> _onConnectionTap(LocalConnection localConnection) async {
    final publicKey = _publicKeyController.text.trim();
    if (publicKey.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Public Key is required')));
      }
      return;
    }
    await _storage.write(key: _publicKeyStorageKey, value: publicKey);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConnectionDetailsScreen(
            connection: localConnection,
            publicKey: publicKey,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _publicKeyController.removeListener(_onPublicKeyChanged);
    _publicKeyController.dispose();
    _linkWidgetTokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Institutions')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(10),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _publicKeyController,
                      decoration: InputDecoration(
                        labelText: 'Public Key',
                        border: OutlineInputBorder(),
                        hintText: 'Enter your Public Key',
                        suffixIcon: _publicKeyController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: _clearPublicKey,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: _savePublicKey,
                    tooltip: 'Save Public Key',
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: _linkWidgetTokenController,
                decoration: InputDecoration(
                  labelText: 'Link Widget Token',
                  border: OutlineInputBorder(),
                  hintText: 'Enter your Link Widget Token',
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final publicKey = _publicKeyController.text.trim();
                  final linkWidgetToken = _linkWidgetTokenController.text
                      .trim();

                  if (publicKey.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Public Key is required')),
                    );
                    return;
                  }

                  if (linkWidgetToken.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Link Widget Token is required')),
                    );
                    return;
                  }

                  await PanConnect.launch(
                    context,
                    publicKey,
                    linkWidgetToken,
                    onSuccess: (exchangeToken, username) {
                      log('exchangeToken: $exchangeToken');
                      log('username: $username');
                    },
                    headless: kDebugMode,
                  );
                },
                child: Text('Launch'),
              ),
              LocalConnections(onConnectionTap: _onConnectionTap),
            ],
          ),
        ),
      ),
    );
  }
}
