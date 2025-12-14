import 'package:example/models/access_credentials.dart';
import 'package:example/widget/rut_form_field.dart';
import 'package:flutter/material.dart';
import 'package:pan_scrapper/pan_scrapper_service.dart';

class LoginScreen extends StatefulWidget {
  final PanScrapperService service;

  const LoginScreen({super.key, required this.service});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(10),
          child: SafeArea(
            child: Column(
              children: [
                Text(
                  'Login ${widget.service.institution.name}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 10),
                AutofillGroup(
                  child: Column(
                    children: [
                      RutFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username or RUT',
                        ),
                      ),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(labelText: 'Password'),
                        obscureText: true,
                        enableSuggestions: true,
                        autofillHints: [AutofillHints.password],
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () async {
                          final credentials = await widget.service.auth(
                            _usernameController.text,
                            _passwordController.text,
                          );
                          if (context.mounted) {
                            Navigator.pop(
                              context,
                              AccessCredentials(
                                username: _usernameController.text,
                                password: _passwordController.text,
                                resultCredentials: credentials,
                              ),
                            );
                          }
                        },
                        child: Text('Login'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
