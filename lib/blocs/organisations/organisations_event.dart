part of 'organisations_bloc.dart';

@immutable
sealed class OrganisationsEvent {}

class CreateOrganisationEvent extends OrganisationsEvent {
  final String name;
  final String description;
  final List<String> memberEmails;

  CreateOrganisationEvent({
    required this.name,
    required this.description,
    required this.memberEmails,
  });
}

class JoinOrganisationEvent extends OrganisationsEvent {
  final String organisationId;

  JoinOrganisationEvent({required this.organisationId});
}

class JoinOrganisationByCodeEvent extends OrganisationsEvent {
  final String joinCode;

  JoinOrganisationByCodeEvent({required this.joinCode});
}

class DeleteOrganisationEvent extends OrganisationsEvent {
  final String organisationId;

  DeleteOrganisationEvent({required this.organisationId});
}

class LeaveOrganisationEvent extends OrganisationsEvent {
  final String organisationId;

  LeaveOrganisationEvent({required this.organisationId});
}

class FetchOrganisationsEvent extends OrganisationsEvent {}