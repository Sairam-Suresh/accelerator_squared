import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';
import 'dart:async';

part 'user_event.dart';
part 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  UserBloc() : super(UserLoading()) {
    on<UserRegisterEvent>(_onUserRegisterEvent);
    on<UserLogsInWithGoogleEvent>(_onUserLogInWithGoogleEvent);
    on<CheckIfUserIsLoggedInEvent>(_checkIfUserIsLoggedIn);
    on<UserLogoutEvent>(_onUserLogoutEvent);

    Timer.run(() {
      add(CheckIfUserIsLoggedInEvent());
    });
  }

  Future<void> _onUserRegisterEvent(
    UserRegisterEvent event,
    Emitter<UserState> emit,
  ) async {
    late UserCredential credential;

    try {
      credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
    } catch (e) {
      emit(UserError("Registration failed: $e"));
      return;
    }

    emit(
      UserLoggedIn(
        userId: credential.user!.uid,
        email: credential.user!.email!,
        displayName: credential.user!.displayName,
        photoUrl: credential.user!.photoURL,
      ),
    );
  }

  Future<void> _onUserLogInWithGoogleEvent(
    UserLogsInWithGoogleEvent event,
    Emitter<UserState> emit,
  ) async {
    late UserCredential credential;

    try {
      credential = await firebaseAuth.signInWithPopup(GoogleAuthProvider());
    } catch (e) {
      emit(UserError("Google login failed: $e"));
      return;
    }

    emit(
      UserLoggedIn(
        userId: credential.user!.uid,
        email: credential.user!.email!,
        displayName: credential.user!.displayName,
        photoUrl: credential.user!.photoURL,
      ),
    );
  }

  Future<void> _checkIfUserIsLoggedIn(
    CheckIfUserIsLoggedInEvent event,
    Emitter<UserState> emit,
  ) async {
    User? user = firebaseAuth.currentUser;
    if (user != null) {
      emit(
        UserLoggedIn(
          userId: user.uid,
          email: user.email!,
          displayName: user.displayName,
          photoUrl: user.photoURL,
        ),
      );
    } else {
      emit(UserInitial());
    }
  }

  Future<void> _onUserLogoutEvent(
    UserLogoutEvent event,
    Emitter<UserState> emit,
  ) async {
    try {
      await firebaseAuth.signOut();
      emit(UserInitial());
    } catch (e) {
      emit(UserInitial());
    }
  }
}
