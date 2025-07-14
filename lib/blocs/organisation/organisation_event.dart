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

  const RemoveMemberEvent({
    required this.memberId,
  });
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

class SubmitTaskReviewRequestEvent extends OrganisationEvent {
  final String projectId;
  final String milestoneId;
  final String milestoneName;
  final String taskId;
  final String taskName;
  final String projectName;
  final DateTime dueDate;

  const SubmitTaskReviewRequestEvent({
    required this.projectId,
    required this.milestoneId,
    required this.milestoneName,
    required this.taskId,
    required this.taskName,
    required this.projectName,
    required this.dueDate,
  });
}

class UnsendTaskReviewRequestEvent extends OrganisationEvent {
  final String projectId;
  final String taskId;
  const UnsendTaskReviewRequestEvent({
    required this.projectId,
    required this.taskId,
  });
}

class AcceptTaskReviewRequestEvent extends OrganisationEvent {
  final String organisationId;
  final String projectId;
  final String taskId;
  const AcceptTaskReviewRequestEvent({
    required this.organisationId,
    required this.projectId,
    required this.taskId,
  });
}

class DeclineTaskReviewRequestEvent extends OrganisationEvent {
  final String organisationId;
  final String projectId;
  final String taskId;
  final String? feedback;
  const DeclineTaskReviewRequestEvent({
    required this.organisationId,
    required this.projectId,
    required this.taskId,
    this.feedback,
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

  const FetchOrganisationEvent(
    {this.initialData}
    // {required this.organisationId}
  );
}
