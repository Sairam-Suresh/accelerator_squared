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

class CreateProjectEvent extends OrganisationsEvent {
  final String organisationId;
  final String title;
  final String description;

  CreateProjectEvent({
    required this.organisationId,
    required this.title,
    required this.description,
  });
}

class SubmitProjectRequestEvent extends OrganisationsEvent {
  final String organisationId;
  final String title;
  final String description;
  final List<String> memberEmails;

  SubmitProjectRequestEvent({
    required this.organisationId,
    required this.title,
    required this.description,
    required this.memberEmails,
  });
}

class ApproveProjectRequestEvent extends OrganisationsEvent {
  final String organisationId;
  final String requestId;

  ApproveProjectRequestEvent({
    required this.organisationId,
    required this.requestId,
  });
}

class RejectProjectRequestEvent extends OrganisationsEvent {
  final String organisationId;
  final String requestId;

  RejectProjectRequestEvent({
    required this.organisationId,
    required this.requestId,
  });
}

class ChangeMemberRoleEvent extends OrganisationsEvent {
  final String organisationId;
  final String memberId;
  final String newRole;

  ChangeMemberRoleEvent({
    required this.organisationId,
    required this.memberId,
    required this.newRole,
  });
}

class RemoveMemberEvent extends OrganisationsEvent {
  final String organisationId;
  final String memberId;

  RemoveMemberEvent({
    required this.organisationId,
    required this.memberId,
  });
}

class JoinOrganisationEvent extends OrganisationsEvent {
  final String organisationId;

  JoinOrganisationEvent({
    required this.organisationId,
  });
}
