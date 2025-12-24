import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';
import 'dart:async';

part 'user_event.dart';
part 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// Saves or updates user data in Firestore users collection
  Future<void> _saveUserToFirestore(User user) async {
    try {
      await firestore.collection('users').doc(user.uid).set({
        'email': user.email ?? '',
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Log error but don't fail the login process
      print('Error saving user to Firestore: $e');
    }
  }

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

    final user = credential.user!;
    // Save user data to Firestore
    await _saveUserToFirestore(user);

    emit(
      UserLoggedIn(
        userId: user.uid,
        email: user.email!,
        displayName: user.displayName,
        photoUrl: user.photoURL,
      ),
    );
  }

  Future<void> _onUserLogInWithGoogleEvent(
    UserLogsInWithGoogleEvent event,
    Emitter<UserState> emit,
  ) async {
    try {
      final credential = await firebaseAuth.signInWithPopup(GoogleAuthProvider());
      
      if (credential.user != null) {
        final user = credential.user!;
        // Save user data to Firestore
        await _saveUserToFirestore(user);

        emit(
          UserLoggedIn(
            userId: user.uid,
            email: user.email!,
            displayName: user.displayName,
            photoUrl: user.photoURL,
          ),
        );
      } else {
        // No user returned, treat as cancellation - silently return to login
        emit(UserInitial());
      }
    } catch (e) {
      // Check if the error is due to user cancelling the popup
      bool isUserCancellation = false;
      
      if (e is FirebaseAuthException) {
        final errorCode = e.code.toLowerCase();
        final errorMessage = e.message?.toLowerCase() ?? '';
        
        // Common error codes/messages for user cancellation:
        // 'popup-closed-by-user', 'cancelled-popup-request', 'popup-blocked'
        // 'user cancelled', 'popup closed'
        if (errorCode.contains('popup-closed') || 
            errorCode.contains('cancelled') ||
            errorCode.contains('popup-blocked') ||
            errorMessage.contains('cancelled') ||
            errorMessage.contains('popup closed') ||
            errorMessage.contains('user closed')) {
          isUserCancellation = true;
        }
      }
      
      // Check error string for common cancellation patterns
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('cancelled') || 
          errorString.contains('popup closed') ||
          errorString.contains('user closed') ||
          errorString.contains('popup-blocked')) {
        isUserCancellation = true;
      }
      
      if (isUserCancellation) {
        // User cancelled, silently return to initial state (login page)
        emit(UserInitial());
      } else {
        // For other errors, check if user is still logged in
        // If not logged in, just return to login page (no error message)
        // If somehow logged in but error occurred, show error
        final currentUser = firebaseAuth.currentUser;
        if (currentUser == null) {
          // User not logged in and it's not a cancellation - just return to login
          emit(UserInitial());
        } else {
          // Unexpected state - user is logged in but we got an error
          // This shouldn't happen, but handle it gracefully
          // Save user data to Firestore
          await _saveUserToFirestore(currentUser);

          emit(
            UserLoggedIn(
              userId: currentUser.uid,
              email: currentUser.email ?? '',
              displayName: currentUser.displayName,
              photoUrl: currentUser.photoURL,
            ),
          );
        }
      }
    }
  }

  Future<void> _checkIfUserIsLoggedIn(
    CheckIfUserIsLoggedInEvent event,
    Emitter<UserState> emit,
  ) async {
    User? user = firebaseAuth.currentUser;
    if (user != null) {
      // Save user data to Firestore (in case it wasn't saved before)
      await _saveUserToFirestore(user);

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
