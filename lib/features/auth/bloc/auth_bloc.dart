import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:studywise/core/error/friendly_error.dart';
import '../usecase/sign_in_usecase.dart';
import '../usecase/sign_up_usecase.dart';

// Events
abstract class AuthEvent {}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  AuthSignUpRequested(this.email, this.password);
}

class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;
  AuthSignInRequested(this.email, this.password);
}

// States
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String message;
  AuthSuccess(this.message);
}

class AuthFailure extends AuthState {
  final String error;
  AuthFailure(this.error);
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInUseCase signInUseCase;
  final SignUpUseCase signUpUseCase;

  AuthBloc({
    required this.signInUseCase,
    required this.signUpUseCase,
  }) : super(AuthInitial()) {
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthSignInRequested>(_onSignInRequested);
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (event.email.trim().isEmpty || event.password.isEmpty) {
      emit(AuthFailure('Enter email and password.'));
      return;
    }

    if (event.password.length < 6) {
      emit(AuthFailure('Password must be at least 6 characters.'));
      return;
    }

    emit(AuthLoading());
    try {
      await signUpUseCase.execute(event.email, event.password);
      emit(AuthSuccess('Account created.'));
    } catch (e) {
      emit(AuthFailure(friendlyErrorMessage(e)));
    }
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (event.email.trim().isEmpty || event.password.isEmpty) {
      emit(AuthFailure('Enter email and password.'));
      return;
    }

    emit(AuthLoading());
    try {
      await signInUseCase.execute(event.email, event.password);
      emit(AuthSuccess('Login successful!'));
    } catch (e) {
      emit(AuthFailure(friendlyErrorMessage(e)));
    }
  }
}
