import 'package:flutter/material.dart';
import 'package:pan_scrapper/models/institution.dart';
import 'package:pan_scrapper/presentation/screens/connection_screen.dart';

class PanConnect {
  PanConnect();

  static Future<void> launch(
    BuildContext context, {
    Institution? selectedInstitution,
  }) async {
    if (selectedInstitution == null) {
      throw Exception('Selected institution is required');
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ConnectionFlowScreen(selectedInstitution: selectedInstitution),
      ),
    );
  }
}
