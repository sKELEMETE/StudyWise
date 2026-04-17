import 'package:flutter/material.dart';
import 'auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String _message = '';

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      setState(() => _message = 'Signup successful!');
    } catch (e) {
      setState(() => _message = e.toString());
    }

    setState(() => _isLoading = false);
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      setState(() => _message = 'Login successful!');
    } catch (e) {
      setState(() => _message = e.toString());
    }

    setState(() => _isLoading = false);
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    setState(() => _message = 'Logged out');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Auth Test',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          if (_isLoading) const CircularProgressIndicator(),

          if (!_isLoading) ...[
            ElevatedButton(
              onPressed: _signUp,
              child: const Text('Sign Up'),
            ),
            ElevatedButton(
              onPressed: _signIn,
              child: const Text('Sign In'),
            ),
            ElevatedButton(
              onPressed: _signOut,
              child: const Text('Sign Out'),
            ),
          ],

          const SizedBox(height: 20),

          Text(
            _message,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}