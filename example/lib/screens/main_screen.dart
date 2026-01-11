import 'package:example/models/access_credentials.dart';
import 'package:example/screens/connection_details_screen.dart';
import 'package:example/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:pan_scrapper/entities/institution_code.dart';
import 'package:pan_scrapper/pan_connect.dart';
import 'package:pan_scrapper/pan_scrapper_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _publicKeyController = TextEditingController();
  final TextEditingController _linkTokenController = TextEditingController();

  @override
  void dispose() {
    _publicKeyController.dispose();
    _linkTokenController.dispose();
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
              TextField(
                controller: _publicKeyController,
                decoration: InputDecoration(
                  labelText: 'Public Key',
                  border: OutlineInputBorder(),
                  hintText: 'Enter your public key',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _linkTokenController,
                decoration: InputDecoration(
                  labelText: 'Link Token',
                  border: OutlineInputBorder(),
                  hintText: 'Enter your link token',
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final publicKey = _publicKeyController.text.trim();
                  final linkToken = _linkTokenController.text.trim();

                  if (publicKey.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Public Key is required')),
                    );
                    return;
                  }

                  if (linkToken.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Link Token is required')),
                    );
                    return;
                  }

                  await PanConnect.launch(context, publicKey, linkToken);
                },
                child: Text('Launch'),
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: InstitutionCode.values.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    child: Card(
                      child: ListTile(
                        title: Text(InstitutionCode.values[index].name),
                      ),
                    ),
                    onTap: () async {
                      final service = PanScrapperService(
                        context: context,
                        institutionCode: InstitutionCode.values[index],
                        headless: false,
                      );

                      final credentials = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginScreen(service: service),
                        ),
                      );

                      if (credentials != null &&
                          credentials is AccessCredentials &&
                          context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ConnectionDetailsScreen(
                              service: service,
                              credentials: credentials,
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
