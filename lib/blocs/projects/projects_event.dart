part of 'projects_bloc.dart';

@immutable
abstract class ProjectsEvent {}

class FetchProjectsEvent extends ProjectsEvent {
  final String organisationId;
  final String? projectId;
  FetchProjectsEvent(this.organisationId, {this.projectId});
}

class CreateProjectEvent extends ProjectsEvent {
  final String organisationId;
  final String title;
  final String description;
  CreateProjectEvent({
    required this.organisationId,
    required this.title,
    required this.description,
  });
}

class UpdateProjectEvent extends ProjectsEvent {
  final String organisationId;
  final String projectId;
  final String title;
  final String description;
  UpdateProjectEvent({
    required this.organisationId,
    required this.projectId,
    required this.title,
    required this.description,
  });
}

class DeleteProjectEvent extends ProjectsEvent {
  final String organisationId;
  final String projectId;
  DeleteProjectEvent({required this.organisationId, required this.projectId});
}

class AddMilestoneEvent extends ProjectsEvent {
  final String organisationId;
  final String projectId;
  final String name;
  final String description;
  final DateTime dueDate;
  final String? sharedId;
  AddMilestoneEvent({
    required this.organisationId,
    required this.projectId,
    required this.name,
    required this.description,
    required this.dueDate,
    this.sharedId,
  });
}

class UpdateMilestoneEvent extends ProjectsEvent {
  final String organisationId;
  final String projectId;
  final String milestoneId;
  final String name;
  final String description;
  final DateTime dueDate;
  UpdateMilestoneEvent({
    required this.organisationId,
    required this.projectId,
    required this.milestoneId,
    required this.name,
    required this.description,
    required this.dueDate,
  });
}

class DeleteMilestoneEvent extends ProjectsEvent {
  final String organisationId;
  final String projectId;
  final String milestoneId;
  DeleteMilestoneEvent({
    required this.organisationId,
    required this.projectId,
    required this.milestoneId,
  });
}

class AddCommentEvent extends ProjectsEvent {
  final String organisationId;
  final String projectId;
  final String text;
  AddCommentEvent({
    required this.organisationId,
    required this.projectId,
    required this.text,
  });
}

class UpdateCommentEvent extends ProjectsEvent {
  final String organisationId;
  final String projectId;
  final String commentId;
  final String text;
  UpdateCommentEvent({
    required this.organisationId,
    required this.projectId,
    required this.commentId,
    required this.text,
  });
}

class DeleteCommentEvent extends ProjectsEvent {
  final String organisationId;
  final String projectId;
  final String commentId;
  DeleteCommentEvent({
    required this.organisationId,
    required this.projectId,
    required this.commentId,
  });
}

class AddTaskEvent extends ProjectsEvent {
  final String organisationId;
  final String projectId;
  final String milestoneId;
  final String name;
  final String content;
  final DateTime deadline;
  final bool isCompleted;
  AddTaskEvent({
    required this.organisationId,
    required this.projectId,
    required this.milestoneId,
    required this.name,
    required this.content,
    required this.deadline,
    required this.isCompleted,
  });
}

class DeleteTaskEvent extends ProjectsEvent {
  final String organisationId;
  final String projectId;
  final String taskId;
  DeleteTaskEvent({
    required this.organisationId,
    required this.projectId,
    required this.taskId,
  });
}
