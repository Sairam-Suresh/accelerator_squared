import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';

part 'user_event.dart';
part 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  UserBloc() : super(UserInitial()) {
    on<UserRegisterEvent>(_onUserRegisterEvent);
    on<UserLogsInWithGoogleEvent>(_onUserLogInWithGoogleEvent);
    on<CheckIfUserIsLoggedInEvent>(_checkIfUserIsLoggedIn);

    add(CheckIfUserIsLoggedInEvent());
    // on<UserLoginEvent>(_onUserLoginEvent);
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
      // Handle error
      print("Error during registration: $e");
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
      // Simulate Google Sign-In process
      // In a real app, you would use the Google Sign-In package
      // and get the credential from there.
      credential = await firebaseAuth.signInWithPopup(GoogleAuthProvider());
    } catch (e) {
      // Handle error
      print("Error during Google login: $e");
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
    }
  }

  // Future<void> _onUserLoginEvent(
  //   UserLoginEvent event,
  //   Emitter<UserState> emit,
  // ) async {
  //   late UserCredential credential;

  //   try {
  //     credential = await firebaseAuth.signInWithEmailAndPassword(
  //       email: event.email,
  //       password: event.password,
  //     );
  //   } catch (e) {
  //     // Handle error
  //     print("Error during login: $e");
  //     return;
  //   }

  //   emit(
  //     UserLoggedIn(
  //       userId: credential.user!.uid,
  //       email: credential.user!.email!,
  //       displayName: credential.user!.displayName,
  //       photoUrl: credential.user!.photoURL,
  //     ),
  //   );
  // }
}
