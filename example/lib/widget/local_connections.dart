import 'package:example/screens/connection_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:pan_scrapper/entities/local_connection.dart';
import 'package:pan_scrapper/pan_connect.dart';

class LocalConnections extends StatefulWidget {
  const LocalConnections({super.key});

  @override
  State<LocalConnections> createState() => _LocalConnectionsState();
}

class _LocalConnectionsState extends State<LocalConnections> {
  List<LocalConnection> _localConnections = [];
  late final Future<List<LocalConnection>> _localConnectionsFuture;

  Future<List<LocalConnection>> _fetchLocalConnections() async {
    final connections = await PanConnect.getSavedConnections();
    setState(() {
      _localConnections = connections;
    });
    return connections;
  }

  @override
  void initState() {
    super.initState();
    _localConnectionsFuture = _fetchLocalConnections();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _localConnectionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Column(
            children: _localConnections
                .map(
                  (e) => ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ConnectionDetailsScreen(connection: e),
                        ),
                      );
                    },
                    title: Text(e.institutionCode.name),
                    subtitle: Text(e.rawUsername),
                  ),
                )
                .toList(),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
