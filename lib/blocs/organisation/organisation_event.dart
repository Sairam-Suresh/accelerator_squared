part of 'organisation_bloc.dart';

sealed class OrganisationEvent extends Equatable {
  const OrganisationEvent();

  @override
  List<Object> get props => [];
}

class CreateProjectEvent extends OrganisationEvent {
  // final String organisationId;
  final String title;
  final String description;
  final List<String> memberEmails;

  const CreateProjectEvent({
    // required this.organisationId,
    required this.title,
    required this.description,
    required this.memberEmails,
  });
}

class SubmitProjectRequestEvent extends OrganisationEvent {
  // final String organisationId;
  final String title;
  final String description;
  final List<String> memberEmails;

  const SubmitProjectRequestEvent({
    // required this.organisationId,
    required this.title,
    required this.description,
    required this.memberEmails,
  });
}

class SubmitMilestoneReviewRequestEvent extends OrganisationEvent {
  // final String organisationId;
  final String projectId;
  final String milestoneId;
  final String milestoneName;
  final String projectName;
  final bool isOrgWide;
  final DateTime dueDate;

  const SubmitMilestoneReviewRequestEvent({
    // required this.organisationId,
    required this.projectId,
    required this.milestoneId,
    required this.milestoneName,
    required this.projectName,
    required this.isOrgWide,
    required this.dueDate,
  });
}

class ApproveProjectRequestEvent extends OrganisationEvent {
  // final String organisationId;
  final String requestId;

  const ApproveProjectRequestEvent({
    // required this.organisationId,
    required this.requestId,
  });
}

class RejectProjectRequestEvent extends OrganisationEvent {
  // final String organisationId;
  final String requestId;

  const RejectProjectRequestEvent({
    // required this.organisationId,
    required this.requestId,
  });
}

class RemoveMemberEvent extends OrganisationEvent {
  final String memberId;

  const RemoveMemberEvent({required this.memberId});
}

class RefreshJoinCodeEvent extends OrganisationEvent {
  // final String organisationId;

  const RefreshJoinCodeEvent(
    // {required this.organisationId}
  );
}

class DeleteProjectEvent extends OrganisationEvent {
  // final String organisationId;
  final String projectId;

  const DeleteProjectEvent({
    // required this.organisationId,
    required this.projectId,
  });
}

class UpdateOrganisationEvent extends OrganisationEvent {
  // final String organisationId;
  final String name;
  final String description;

  const UpdateOrganisationEvent({
    // required this.organisationId,
    required this.name,
    required this.description,
  });
}

class UnsendMilestoneReviewRequestEvent extends OrganisationEvent {
  final String projectId;
  final String milestoneId;
  const UnsendMilestoneReviewRequestEvent({
    required this.projectId,
    required this.milestoneId,
  });
}

class ChangeMemberRoleEvent extends OrganisationEvent {
  // final String organisationId;
  final String memberId;
  final String newRole;

  const ChangeMemberRoleEvent({
    // required this.organisationId,
    required this.memberId,
    required this.newRole,
  });
}

class FetchOrganisationEvent extends OrganisationEvent {
  // For when the OrganisationsBloc calls this bloc, then it probably already has some data
  // that we can use to avoid unnecessary firestore reads.
  final Organisation? initialData;

  const FetchOrganisationEvent({
    this.initialData,
    // {required this.organisationId}
  });
}

class UpdateUserRoleEvent extends OrganisationEvent {
  final String newRole;

  const UpdateUserRoleEvent({required this.newRole});
}

// Internal-only event to signal deletion from stream
class _OrganisationDeletedInternalEvent extends OrganisationEvent {}
