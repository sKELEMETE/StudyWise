import '../repo/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  Future<void> execute(String email, String password) async {
    await repository.signUp(email: email, password: password);
  }
}