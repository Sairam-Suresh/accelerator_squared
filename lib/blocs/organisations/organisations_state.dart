part of 'organisations_bloc.dart';

@immutable
sealed class OrganisationsState {}

final class OrganisationsInitial extends OrganisationsState {}

class OrganisationsLoading extends OrganisationsState {}

class OrganisationsLoaded extends OrganisationsState {
  final List<Organisation> organisations;

  OrganisationsLoaded(this.organisations);
}

class OrganisationsError extends OrganisationsState {
  final String message;

  OrganisationsError(this.message);
}
