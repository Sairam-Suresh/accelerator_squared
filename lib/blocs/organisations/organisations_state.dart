part of 'organisations_bloc.dart';

@immutable
sealed class OrganisationsState {}

final class OrganisationsInitial extends OrganisationsState {}

class OrganisationsLoading extends OrganisationsState {}

enum OrganisationsNotificationType { none, success, info, warning, error }

class OrganisationsLoaded extends OrganisationsState {
  final List<Organisation> organisations;
  final OrganisationsNotificationType notificationType;
  final String? notificationMessage;

  OrganisationsLoaded(
    this.organisations, {
    this.notificationType = OrganisationsNotificationType.none,
    this.notificationMessage,
  });
}

class OrganisationsError extends OrganisationsState {
  final String message;

  OrganisationsError(this.message);
}
