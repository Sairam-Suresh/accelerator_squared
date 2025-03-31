import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';

part 'user_event.dart';
part 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  UserBloc() : super(UserInitial()) {
    on<UserRegisterEvent>(_onUserRegisterEvent);
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

    print("hi");
  }
}
