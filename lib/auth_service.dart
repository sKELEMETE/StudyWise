import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  Future<void> signUp(String email, String password) async {
    final res = await supabase.auth.signUp(
      email: email,
      password: password,
    );

    if (res.user == null) {
      throw Exception('Signup failed');
    }
  }

  Future<void> signIn(String email, String password) async {
    final res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (res.user == null) {
      throw Exception('Login failed');
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}