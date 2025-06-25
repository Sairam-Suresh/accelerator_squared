import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

part 'projects_event.dart';
part 'projects_state.dart';

class ProjectsBloc extends Bloc<ProjectsEvent, ProjectsState> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  StreamSubscription? _milestonesSubscription;
  String? _currentOrgId;
  String? _currentProjectId;

  ProjectsBloc() : super(ProjectsInitial()) {
    on<FetchProjectsEvent>(_onFetchProjects);
    on<CreateProjectEvent>(_onCreateProject);
    on<UpdateProjectEvent>(_onUpdateProject);
    on<DeleteProjectEvent>(_onDeleteProject);
    on<AddMilestoneEvent>(_onAddMilestone);
    on<UpdateMilestoneEvent>(_onUpdateMilestone);
    on<DeleteMilestoneEvent>(_onDeleteMilestone);
    on<AddCommentEvent>(_onAddComment);
    on<UpdateCommentEvent>(_onUpdateComment);
    on<DeleteCommentEvent>(_onDeleteComment);
    on<_EmitProjectsLoaded>(
      (event, emit) => emit(ProjectsLoaded(event.projects)),
    );
    on<_EmitProjectsError>((event, emit) => emit(ProjectsError(event.message)));
  }

  Future<void> _onFetchProjects(
    FetchProjectsEvent event,
    Emitter<ProjectsState> emit,
  ) async {
    emit(ProjectsLoading());
    // Cancel previous subscription if any
    await _milestonesSubscription?.cancel();
    _currentOrgId = event.organisationId;
    _currentProjectId = event.projectId;
    if (event.projectId != null) {
      // Listen to milestones for a specific project
      final path =
          'organisations/${event.organisationId}/projects/${event.projectId}/milestones';
      print('[ProjectsBloc] Listening to milestones at: $path');
      _milestonesSubscription = firestore
          .collection('organisations')
          .doc(event.organisationId)
          .collection('projects')
          .doc(event.projectId)
          .collection('milestones')
          .snapshots()
          .listen((milestonesSnapshot) async {
            try {
              print(
                '[ProjectsBloc] Milestones snapshot docs: ${milestonesSnapshot.docs.length}',
              );
              final projectDoc =
                  await firestore
                      .collection('organisations')
                      .doc(event.organisationId)
                      .collection('projects')
                      .doc(event.projectId)
                      .get();
              if (!projectDoc.exists) {
                add(_EmitProjectsError('Project not found.'));
                return;
              }
              final milestones =
                  milestonesSnapshot.docs.isNotEmpty
                      ? milestonesSnapshot.docs.map((m) => m.data()).toList()
                      : <Map<String, dynamic>>[];
              print('[ProjectsBloc] Milestones fetched: $milestones');
              final project = ProjectWithDetails(
                id: event.projectId!,
                data: projectDoc.data() ?? {},
                milestones: milestones,
                comments: [],
              );
              add(_EmitProjectsLoaded([project]));
            } catch (e) {
              print('[ProjectsBloc] Error fetching milestones: $e');
              add(_EmitProjectsError('Failed to fetch milestones: $e'));
            }
          });
    } else {
      // Fallback: fetch all projects (no real-time for all)
      try {
        final orgId = event.organisationId;
        final projectsSnapshot =
            await firestore
                .collection('organisations')
                .doc(orgId)
                .collection('projects')
                .get();
        final projects = <ProjectWithDetails>[];
        for (final doc in projectsSnapshot.docs) {
          final projectId = doc.id;
          final milestonesSnapshot =
              await firestore
                  .collection('organisations')
                  .doc(orgId)
                  .collection('projects')
                  .doc(projectId)
                  .collection('milestones')
                  .get();
          final commentsSnapshot =
              await firestore
                  .collection('organisations')
                  .doc(orgId)
                  .collection('projects')
                  .doc(projectId)
                  .collection('comments')
                  .get();
          print(
            '[ProjectsBloc] Fetched project $projectId with ${milestonesSnapshot.docs.length} milestones',
          );
          projects.add(
            ProjectWithDetails(
              id: projectId,
              data: doc.data(),
              milestones: milestonesSnapshot.docs.map((m) => m.data()).toList(),
              comments: commentsSnapshot.docs.map((c) => c.data()).toList(),
            ),
          );
        }
        emit(ProjectsLoaded(projects));
      } catch (e) {
        print('[ProjectsBloc] Error fetching all projects: $e');
        emit(ProjectsError(e.toString()));
      }
    }
  }

  Future<void> _onCreateProject(
    CreateProjectEvent event,
    Emitter<ProjectsState> emit,
  ) async {
    emit(ProjectsLoading());
    try {
      final uid = auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        emit(ProjectsError('User not authenticated'));
        return;
      }
      final orgId = event.organisationId;
      final projectId = const Uuid().v4();
      final projectRef = firestore
          .collection('organisations')
          .doc(orgId)
          .collection('projects')
          .doc(projectId);
      await projectRef.set({
        'title': event.title,
        'description': event.description,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': uid,
      });
      emit(ProjectActionSuccess('Project created successfully'));
      add(FetchProjectsEvent(orgId));
    } catch (e) {
      emit(ProjectsError(e.toString()));
    }
  }

  Future<void> _onUpdateProject(
    UpdateProjectEvent event,
    Emitter<ProjectsState> emit,
  ) async {
    emit(ProjectsLoading());
    try {
      final orgId = event.organisationId;
      final projectId = event.projectId;
      await firestore
          .collection('organisations')
          .doc(orgId)
          .collection('projects')
          .doc(projectId)
          .update({
            'title': event.title,
            'description': event.description,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      emit(ProjectActionSuccess('Project updated successfully'));
      add(FetchProjectsEvent(orgId));
    } catch (e) {
      emit(ProjectsError(e.toString()));
    }
  }

  Future<void> _onDeleteProject(
    DeleteProjectEvent event,
    Emitter<ProjectsState> emit,
  ) async {
    emit(ProjectsLoading());
    try {
      final orgId = event.organisationId;
      final projectId = event.projectId;
      // Delete milestones
      final milestones =
          await firestore
              .collection('organisations')
              .doc(orgId)
              .collection('projects')
              .doc(projectId)
              .collection('milestones')
              .get();
      for (final doc in milestones.docs) {
        await doc.reference.delete();
      }
      // Delete comments
      final comments =
          await firestore
              .collection('organisations')
              .doc(orgId)
              .collection('projects')
              .doc(projectId)
              .collection('comments')
              .get();
      for (final doc in comments.docs) {
        await doc.reference.delete();
      }
      // Delete project
      await firestore
          .collection('organisations')
          .doc(orgId)
          .collection('projects')
          .doc(projectId)
          .delete();
      emit(ProjectActionSuccess('Project deleted successfully'));
      add(FetchProjectsEvent(orgId));
    } catch (e) {
      emit(ProjectsError(e.toString()));
    }
  }

  Future<void> _onAddMilestone(
    AddMilestoneEvent event,
    Emitter<ProjectsState> emit,
  ) async {
    emit(ProjectsLoading());
    try {
      final uid = auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        emit(ProjectsError('User not authenticated'));
        return;
      }
      final orgId = event.organisationId;
      final projectId = event.projectId;
      final milestoneId = const Uuid().v4();
      await firestore
          .collection('organisations')
          .doc(orgId)
          .collection('projects')
          .doc(projectId)
          .collection('milestones')
          .doc(milestoneId)
          .set({
            'name': event.name,
            'description': event.description,
            'dueDate': event.dueDate,
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': uid,
          });
      emit(ProjectActionSuccess('Milestone added successfully'));
      add(FetchProjectsEvent(orgId));
    } catch (e) {
      emit(ProjectsError(e.toString()));
    }
  }

  Future<void> _onUpdateMilestone(
    UpdateMilestoneEvent event,
    Emitter<ProjectsState> emit,
  ) async {
    emit(ProjectsLoading());
    try {
      final orgId = event.organisationId;
      final projectId = event.projectId;
      final milestoneId = event.milestoneId;
      await firestore
          .collection('organisations')
          .doc(orgId)
          .collection('projects')
          .doc(projectId)
          .collection('milestones')
          .doc(milestoneId)
          .update({
            'name': event.name,
            'description': event.description,
            'dueDate': event.dueDate,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      emit(ProjectActionSuccess('Milestone updated successfully'));
      add(FetchProjectsEvent(orgId));
    } catch (e) {
      emit(ProjectsError(e.toString()));
    }
  }

  Future<void> _onDeleteMilestone(
    DeleteMilestoneEvent event,
    Emitter<ProjectsState> emit,
  ) async {
    emit(ProjectsLoading());
    try {
      final orgId = event.organisationId;
      final projectId = event.projectId;
      final milestoneId = event.milestoneId;
      await firestore
          .collection('organisations')
          .doc(orgId)
          .collection('projects')
          .doc(projectId)
          .collection('milestones')
          .doc(milestoneId)
          .delete();
      emit(ProjectActionSuccess('Milestone deleted successfully'));
      add(FetchProjectsEvent(orgId));
    } catch (e) {
      emit(ProjectsError(e.toString()));
    }
  }

  Future<void> _onAddComment(
    AddCommentEvent event,
    Emitter<ProjectsState> emit,
  ) async {
    emit(ProjectsLoading());
    try {
      final uid = auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        emit(ProjectsError('User not authenticated'));
        return;
      }
      final orgId = event.organisationId;
      final projectId = event.projectId;
      final commentId = const Uuid().v4();
      await firestore
          .collection('organisations')
          .doc(orgId)
          .collection('projects')
          .doc(projectId)
          .collection('comments')
          .doc(commentId)
          .set({
            'text': event.text,
            'author': uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
      emit(ProjectActionSuccess('Comment added successfully'));
      add(FetchProjectsEvent(orgId));
    } catch (e) {
      emit(ProjectsError(e.toString()));
    }
  }

  Future<void> _onUpdateComment(
    UpdateCommentEvent event,
    Emitter<ProjectsState> emit,
  ) async {
    emit(ProjectsLoading());
    try {
      final orgId = event.organisationId;
      final projectId = event.projectId;
      final commentId = event.commentId;
      await firestore
          .collection('organisations')
          .doc(orgId)
          .collection('projects')
          .doc(projectId)
          .collection('comments')
          .doc(commentId)
          .update({
            'text': event.text,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      emit(ProjectActionSuccess('Comment updated successfully'));
      add(FetchProjectsEvent(orgId));
    } catch (e) {
      emit(ProjectsError(e.toString()));
    }
  }

  Future<void> _onDeleteComment(
    DeleteCommentEvent event,
    Emitter<ProjectsState> emit,
  ) async {
    emit(ProjectsLoading());
    try {
      final orgId = event.organisationId;
      final projectId = event.projectId;
      final commentId = event.commentId;
      await firestore
          .collection('organisations')
          .doc(orgId)
          .collection('projects')
          .doc(projectId)
          .collection('comments')
          .doc(commentId)
          .delete();
      emit(ProjectActionSuccess('Comment deleted successfully'));
      add(FetchProjectsEvent(orgId));
    } catch (e) {
      emit(ProjectsError(e.toString()));
    }
  }
}

class ProjectWithDetails {
  final String id;
  final Map<String, dynamic> data;
  final List<Map<String, dynamic>> milestones;
  final List<Map<String, dynamic>> comments;
  ProjectWithDetails({
    required this.id,
    required this.data,
    required this.milestones,
    required this.comments,
  });
}

class _EmitProjectsLoaded extends ProjectsEvent {
  final List<ProjectWithDetails> projects;
  _EmitProjectsLoaded(this.projects);
}

class _EmitProjectsError extends ProjectsEvent {
  final String message;
  _EmitProjectsError(this.message);
}
