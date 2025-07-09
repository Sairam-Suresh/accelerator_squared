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
  final List<String> memberEmails;

  CreateProjectEvent({
    required this.organisationId,
    required this.title,
    required this.description,
    required this.memberEmails,
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

class SubmitMilestoneReviewRequestEvent extends OrganisationsEvent {
  final String organisationId;
  final String projectId;
  final String milestoneId;
  final String milestoneName;
  final String projectName;
  final bool isOrgWide;
  final DateTime dueDate;

  SubmitMilestoneReviewRequestEvent({
    required this.organisationId,
    required this.projectId,
    required this.milestoneId,
    required this.milestoneName,
    required this.projectName,
    required this.isOrgWide,
    required this.dueDate,
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

  RemoveMemberEvent({required this.organisationId, required this.memberId});
}

class JoinOrganisationEvent extends OrganisationsEvent {
  final String organisationId;

  JoinOrganisationEvent({required this.organisationId});
}

class RefreshJoinCodeEvent extends OrganisationsEvent {
  final String organisationId;

  RefreshJoinCodeEvent({required this.organisationId});
}

class JoinOrganisationByCodeEvent extends OrganisationsEvent {
  final String joinCode;

  JoinOrganisationByCodeEvent({required this.joinCode});
}

class DeleteProjectEvent extends OrganisationsEvent {
  final String organisationId;
  final String projectId;

  DeleteProjectEvent({required this.organisationId, required this.projectId});
}

class DeleteOrganisationEvent extends OrganisationsEvent {
  final String organisationId;

  DeleteOrganisationEvent({required this.organisationId});
}

class LeaveOrganisationEvent extends OrganisationsEvent {
  final String organisationId;

  LeaveOrganisationEvent({required this.organisationId});
}

class UpdateOrganisationEvent extends OrganisationsEvent {
  final String organisationId;
  final String name;
  final String description;

  UpdateOrganisationEvent({
    required this.organisationId,
    required this.name,
    required this.description,
  });
}

class UnsendMilestoneReviewRequestEvent extends OrganisationsEvent {
  final String organisationId;
  final String projectId;
  final String milestoneId;
  UnsendMilestoneReviewRequestEvent({
    required this.organisationId,
    required this.projectId,
    required this.milestoneId,
  });
}

class SubmitTaskReviewRequestEvent extends OrganisationsEvent {
  final String organisationId;
  final String projectId;
  final String milestoneId;
  final String milestoneName;
  final String taskId;
  final String taskName;
  final String projectName;
  final DateTime dueDate;

  SubmitTaskReviewRequestEvent({
    required this.organisationId,
    required this.projectId,
    required this.milestoneId,
    required this.milestoneName,
    required this.taskId,
    required this.taskName,
    required this.projectName,
    required this.dueDate,
  });
}

class UnsendTaskReviewRequestEvent extends OrganisationsEvent {
  final String organisationId;
  final String projectId;
  final String taskId;
  UnsendTaskReviewRequestEvent({
    required this.organisationId,
    required this.projectId,
    required this.taskId,
  });
}

class AcceptTaskReviewRequestEvent extends OrganisationsEvent {
  final String organisationId;
  final String projectId;
  final String taskId;
  AcceptTaskReviewRequestEvent({
    required this.organisationId,
    required this.projectId,
    required this.taskId,
  });
}

class DeclineTaskReviewRequestEvent extends OrganisationsEvent {
  final String organisationId;
  final String projectId;
  final String taskId;
  final String? feedback;
  DeclineTaskReviewRequestEvent({
    required this.organisationId,
    required this.projectId,
    required this.taskId,
    this.feedback,
  });
}
