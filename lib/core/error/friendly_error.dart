import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'app_exceptions.dart';

String friendlyErrorMessage(Object error) {
  if (error is AuthException) {
    return error.message;
  }
  
  if (error is AiException) {
    return 'AI generation is unavailable right now. Please try again.';
  }
  
  if (error is ContentExtractionException) {
    return error.message;
  }

  if (error is ValidationException) {
    return error.message;
  }

  if (error is supabase.AuthException) {
    final lower = error.message.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return 'Invalid email or password.';
    }
    if (lower.contains('already registered')) {
      return 'An account already exists for this email.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Confirm your email before signing in.';
    }
    return 'Authentication failed. Please try again.';
  }

  if (error is supabase.StorageException) {
    return 'Storage operation failed. Check your file and try again.';
  }

  if (error is supabase.PostgrestException) {
    return 'Database connection error. Please try again.';
  }

  return 'Something went wrong. Please try again.';
}