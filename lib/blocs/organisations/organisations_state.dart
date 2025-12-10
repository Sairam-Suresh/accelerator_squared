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

/// Special state to indicate leaving is blocked because user is last teacher.
/// Extends OrganisationsLoaded so the UI can continue to render the list.
class OrganisationsLeaveBlockedLastTeacher extends OrganisationsLoaded {
  OrganisationsLeaveBlockedLastTeacher(
    List<Organisation> organisations, {
    OrganisationsNotificationType notificationType =
        OrganisationsNotificationType.none,
    String? notificationMessage,
  }) : super(
          organisations,
          notificationType: notificationType,
          notificationMessage: notificationMessage,
        );
}
