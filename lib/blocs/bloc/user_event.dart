part of 'user_bloc.dart';

@immutable
sealed class UserEvent {}

class UserLoginEvent extends UserEvent {}

class UserLogoutEvent extends UserEvent {}

class UserRegisterEvent extends UserEvent {
  final String email;
  final String password;

  UserRegisterEvent({required this.email, required this.password});
}

class UserLinkWithGoogleEvent extends UserEvent {}
