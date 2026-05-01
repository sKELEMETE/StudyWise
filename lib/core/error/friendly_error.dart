String friendlyErrorMessage(Object error) {
  final rawMessage = error.toString().replaceFirst('Exception: ', '').trim();
  final lower = rawMessage.toLowerCase();

  if (lower.contains('no study materials') ||
      lower.contains('input text is empty') ||
      lower.contains('no readable text was found in this folder')) {
    return 'Add readable study material to this folder first.';
  }

  if (lower.contains('no readable text')) {
    return 'No readable text was found in this file.';
  }

  if (lower.contains('unauthorized') ||
      lower.contains('authentication') ||
      lower.contains('jwt')) {
    return 'Your session expired. Please sign in again.';
  }

  if (lower.contains('invalid login credentials')) {
    return 'Invalid email or password.';
  }

  if (lower.contains('user already registered') ||
      lower.contains('already exists')) {
    return 'An account already exists for this email.';
  }

  if (lower.contains('email not confirmed')) {
    return 'Confirm your email before signing in.';
  }

  if (lower.contains('unsupported file') ||
      lower.contains('invalid image') ||
      lower.contains('invalid folder') ||
      lower.contains('invalid file') ||
      lower.contains('missing file') ||
      lower.contains('missing folder') ||
      lower.contains('file is too large') ||
      lower.contains('could not read')) {
    return rawMessage;
  }

  if (lower.contains('ml kit')) {
    return 'Could not read text from this image.';
  }

  if (lower.contains('pdf')) {
    return 'Could not read text from this PDF.';
  }

  if (lower.contains('could not create a quiz') ||
      lower.contains('could not create flashcards')) {
    return 'Could not create a quiz from this folder. '
        'Add clearer study material and try again.';
  }

  if (lower.contains('groq') ||
      lower.contains('ai') ||
      lower.contains('socket') ||
      lower.contains('timeout') ||
      lower.contains('connection')) {
    return 'AI generation is unavailable right now. Please try again.';
  }

  if (lower.contains('password') || lower.contains('email')) {
    return rawMessage;
  }

  return 'Something went wrong. Please try again.';
}
