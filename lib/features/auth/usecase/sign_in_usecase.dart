import '../repo/auth_repository.dart';

class SignInUseCase {
  final AuthRepository repository;

  SignInUseCase(this.repository);

  Future<void> execute(String email, String password) async {
    await repository.signIn(email: email, password: password);
  }
}