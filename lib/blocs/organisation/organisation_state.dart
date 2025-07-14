part of 'organisation_bloc.dart';

sealed class OrganisationState extends Equatable {
  const OrganisationState();

  @override
  List<Object> get props => [];
}

final class OrganisationInitial extends OrganisationState {}

class OrganisationLoading extends OrganisationState {}

class OrganisationError extends OrganisationState {
  final String message;

  const OrganisationError(this.message);
}

class OrganisationLoaded extends OrganisationState {
  final String id;
  final String name;
  final String description;
  final List<StudentInOrganisation> students;
  final List<Project> projects;
  final List<ProjectRequest> projectRequests;
  final List<MilestoneReviewRequest> milestoneReviewRequests;
  final List<TaskReviewRequest> taskReviewRequests;
  final int memberCount;
  final String userRole; // 'teacher', 'student_teacher', or 'member'
  final String joinCode; // 6-character join code

  const OrganisationLoaded({
    required this.id,
    required this.name,
    required this.description,
    required this.students,
    required this.projects,
    required this.projectRequests,
    required this.milestoneReviewRequests,
    required this.taskReviewRequests,
    required this.memberCount,
    required this.userRole,
    required this.joinCode,
  });

  factory OrganisationLoaded.fromOrganisationObject(Organisation organisation) {
    return OrganisationLoaded(
      id: organisation.id,
      name: organisation.name,
      description: organisation.description,
      students: organisation.students,
      projects: organisation.projects,
      projectRequests: organisation.projectRequests,
      milestoneReviewRequests: organisation.milestoneReviewRequests,
      taskReviewRequests: organisation.taskReviewRequests,
      memberCount: organisation.memberCount,
      userRole: organisation.userRole,
      joinCode: organisation.joinCode,
    );
  }

  @override
  List<Object> get props => [
    id,
    name,
    description,
    students,
    projects,
    projectRequests,
    milestoneReviewRequests,
    taskReviewRequests,
    memberCount,
    userRole,
    joinCode,
  ];
}
