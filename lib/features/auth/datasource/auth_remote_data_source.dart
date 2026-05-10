import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRemoteDataSource {
  Future<void> signUp({required String email, required String password});
  Future<void> signIn({required String email, required String password});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;

  AuthRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<void> signUp({required String email, required String password}) async {
    final response = await supabaseClient.auth.signUp(
      email: email,
      password: password,
    );
    final userId = response.user?.id;
    if (userId != null) {
      await _ensureStudentRecord(userId);
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    final response = await supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final userId = response.user?.id;
    if (userId != null) {
      await _ensureStudentRecord(userId);
    }
  }

  Future<void> _ensureStudentRecord(String userId) async {
    try {
      await supabaseClient.from('students').upsert({'id': userId});
    } catch (_) {
      // Uploads and quiz results also enforce the student relationship.
    }
  }
}
