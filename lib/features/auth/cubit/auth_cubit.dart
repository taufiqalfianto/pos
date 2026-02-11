import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/model/user_model.dart';
import '../repository/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit(this._authRepository) : super(AuthInitial());

  Future<void> checkAuth() async {
    emit(AuthLoading());
    // Give native channels a moment to stabilize
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      // Don't emit AuthError for silent checks to avoid toast on startup
      // and log the error for debugging.
      print('CheckAuth Error: $e');
      emit(Unauthenticated());
    }
  }

  Future<void> login(String username, String password) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.login(username, password);
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const AuthError('Username atau password salah'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> register(UserModel user) async {
    emit(AuthLoading());
    try {
      await _authRepository.register(user);
      await _authRepository.saveSession(user.id); // Persist session
      emit(Authenticated(user)); // Auto login after register for UX
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    final currentState = state;
    if (currentState is Authenticated) {
      emit(AuthLoading());
      try {
        await _authRepository.changePassword(
          currentState.user.id,
          oldPassword,
          newPassword,
        );
        emit(Authenticated(currentState.user)); // Keep authenticated
      } catch (e) {
        emit(AuthError(e.toString()));
        emit(Authenticated(currentState.user)); // Restore state after error
      }
    }
  }

  Future<void> updateProfile(UserModel user) async {
    emit(AuthLoading());
    try {
      await _authRepository.updateProfile(user);
      emit(Authenticated(user)); // Update with new user data
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());
    await _authRepository.logout();
    emit(Unauthenticated());
  }
}
