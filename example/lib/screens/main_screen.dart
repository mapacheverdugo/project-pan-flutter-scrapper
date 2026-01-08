import 'package:example/models/access_credentials.dart';
import 'package:example/models/institution_ext.dart';
import 'package:example/screens/connection_details_screen.dart';
import 'package:example/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:pan_scrapper/models/institution.dart';
import 'package:pan_scrapper/pan_connect.dart';
import 'package:pan_scrapper/pan_scrapper_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Institutions')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(10),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              ElevatedButton(
                onPressed: () async {
                  await PanConnect.launch(
                    context,
                    selectedInstitution: Institution.santander,
                  );
                },
                child: Text('Launch'),
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: Institution.values.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    child: Card(
                      child: ListTile(
                        title: Text(Institution.values[index].label),
                      ),
                    ),
                    onTap: () async {
                      final service = PanScrapperService(
                        context: context,
                        institution: Institution.values[index],
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
