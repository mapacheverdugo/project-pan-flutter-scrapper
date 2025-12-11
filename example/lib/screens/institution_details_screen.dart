import 'package:example/widget/code_block.dart';
import 'package:flutter/material.dart';
import 'package:pan_scrapper/pan_scrapper_service.dart';

class InstitutionDetailsScreen extends StatefulWidget {
  const InstitutionDetailsScreen({
    super.key,
    required this.service,
    required this.credentials,
  });

  final PanScrapperService service;
  final String credentials;

  @override
  State<InstitutionDetailsScreen> createState() =>
      _InstitutionDetailsScreenState();
}

class _InstitutionDetailsScreenState extends State<InstitutionDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Institution Details')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(10),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Credentials',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              CodeBlock(text: widget.credentials),
            ],
          ),
        ),
      ),
    );
  }
}
