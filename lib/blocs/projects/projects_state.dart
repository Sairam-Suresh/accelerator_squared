part of 'projects_bloc.dart';

@immutable
abstract class ProjectsState {}

class ProjectsInitial extends ProjectsState {}

class ProjectsLoading extends ProjectsState {}

class ProjectsLoaded extends ProjectsState {
  final List<ProjectWithDetails> projects;
  ProjectsLoaded(this.projects);
}

class ProjectsError extends ProjectsState {
  final String message;
  ProjectsError(this.message);
}

class ProjectActionSuccess extends ProjectsState {
  final String message;
  ProjectActionSuccess(this.message);
}
