import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginPageState();
}

class _LoginPageState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final url = Uri.parse("https://customprint.deodap.com/api_dropshipper_tracker/login_dropshipper.php");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": _usernameController.text.trim(),
        "password": _passwordController.text.trim(),
      }),
    );

    setState(() => _loading = false);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        // Save user data locally
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(data['data']));

        // Navigate to Dashboard or Home page
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Login failed')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.statusCode}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: "Username"),
                validator: (value) =>
                value == null || value.isEmpty ? "Enter username" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (value) =>
                value == null || value.isEmpty ? "Enter password" : null,
              ),
              const SizedBox(height: 24),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                  onPressed: login, child: const Text("Login")),
            ],
          ),
        ),
      ),
    );
  }
}
