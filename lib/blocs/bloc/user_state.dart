part of 'user_bloc.dart';

@immutable
sealed class UserState {}

final class UserInitial extends UserState {}

final class UserLoggedIn extends UserState {
  final String userId;
  final String email;
  final String? displayName;
  final String? photoUrl;

  UserLoggedIn({
    required this.userId,
    required this.email,
    this.displayName,
    this.photoUrl,
  });
}
