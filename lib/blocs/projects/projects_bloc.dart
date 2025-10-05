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
  StreamSubscription? _projectSubscription;
  StreamSubscription? _filesSubscription;
  String? _currentOrgId;
  String? _currentProjectId;

  Map<String, dynamic> _liveProjectData = {};
  List<Map<String, dynamic>> _liveMilestones = [];
  List<Map<String, dynamic>> _liveFiles = [];

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
    on<AddTaskEvent>(_onAddTask);
    on<DeleteTaskEvent>(_onDeleteTask);
    on<UpdateTaskEvent>(_onUpdateTask);
    on<CompleteMilestoneEvent>(_onCompleteMilestone);
    on<CreateFileLinkEvent>(_onCreateFileLinkEvent);
    on<DeleteFileLinkEvent>(_onDeleteFileLinkEvent);
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
    await _projectSubscription?.cancel();
    await _filesSubscription?.cancel();
    _currentOrgId = event.organisationId;
    _currentProjectId = event.projectId;
    if (event.projectId != null) {
      // Listen to project, milestones and files for a specific project (real-time)
      final path =
          'organisations/${event.organisationId}/projects/${event.projectId}/milestones';
      print('[ProjectsBloc] Listening to milestones at: $path');
      // Project document listener
      _projectSubscription = firestore
          .collection('organisations')
          .doc(event.organisationId)
          .collection('projects')
          .doc(event.projectId)
          .snapshots()
          .listen((projectDoc) {
            if (!projectDoc.exists) {
              add(_EmitProjectsError('Project not found.'));
              return;
            }
            _liveProjectData = projectDoc.data() ?? {};
            // Emit combined state when project changes
            final project = ProjectWithDetails(
              id: event.projectId!,
              data: _liveProjectData,
              milestones: _liveMilestones,
              comments: const [],
              files: _liveFiles,
            );
            add(_EmitProjectsLoaded([project]));
          });
      // Files collection listener
      _filesSubscription = firestore
          .collection('organisations')
          .doc(event.organisationId)
          .collection('projects')
          .doc(event.projectId)
          .collection('files')
          .snapshots()
          .listen((linksSnapshot) {
            _liveFiles =
                linksSnapshot.docs
                    .map((m) => {...m.data(), 'id': m.id})
                    .toList();
            final project = ProjectWithDetails(
              id: event.projectId!,
              data: _liveProjectData,
              milestones: _liveMilestones,
              comments: const [],
              files: _liveFiles,
            );
            add(_EmitProjectsLoaded([project]));
          });
      // Milestones collection listener
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
              final milestones =
                  milestonesSnapshot.docs.isNotEmpty
                      ? milestonesSnapshot.docs
                          .map((m) => {...m.data(), 'id': m.id})
                          .toList()
                      : <Map<String, dynamic>>[];
              print('[ProjectsBloc] Milestones fetched: $milestones');
              _liveMilestones = milestones;
              final project = ProjectWithDetails(
                id: event.projectId!,
                data: _liveProjectData,
                milestones: _liveMilestones,
                comments: const [],
                files: _liveFiles,
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
          final linksSnapshot =
              await firestore
                  .collection('organisations')
                  .doc(orgId)
                  .collection('projects')
                  .doc(projectId)
                  .collection('files')
                  .get();
          print(
            '[ProjectsBloc] Fetched project $projectId with ${milestonesSnapshot.docs.length} milestones',
          );
          projects.add(
            ProjectWithDetails(
              id: projectId,
              data: doc.data(),
              milestones:
                  milestonesSnapshot.docs
                      .map((m) => {...m.data(), 'id': m.id})
                      .toList(),
              comments: commentsSnapshot.docs.map((c) => c.data()).toList(),
              files:
                  linksSnapshot.docs
                      .map((m) => {...m.data(), 'id': m.id})
                      .toList(),
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

      // Copy existing organisation-wide milestones to the new project
      // Add a small delay to ensure the project document is fully written
      await Future.delayed(Duration(milliseconds: 100));
      await _copyOrgWideMilestonesToNewProject(orgId, projectId);

      // Add another small delay to ensure milestones are written before fetching
      await Future.delayed(Duration(milliseconds: 100));

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
      // Emit optimistic state with updated project info
      final optimisticProject = ProjectWithDetails(
        id: projectId,
        data: {
          'id': projectId,
          'title': event.title,
          'description': event.description,
          // Optionally add more fields if needed
        },
        milestones: [],
        comments: [],
        files: [],
      );
      emit(ProjectsLoaded([optimisticProject]));
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
      final milestoneId = event.sharedId ?? const Uuid().v4();
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
            'createdByEmail': auth.currentUser?.email ?? '',
            'sharedId': event.sharedId,
            'isCompleted': false,
          });
      emit(ProjectActionSuccess('Milestone added successfully'));
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

      // Get the milestone to check if it has a sharedId
      final milestoneDoc =
          await firestore
              .collection('organisations')
              .doc(orgId)
              .collection('projects')
              .doc(projectId)
              .collection('milestones')
              .doc(milestoneId)
              .get();

      if (milestoneDoc.exists) {
        final milestoneData = milestoneDoc.data();
        final sharedId = milestoneData?['sharedId'];

        if (sharedId != null) {
          // Update in all projects that have this shared milestone
          final projectsSnapshot =
              await firestore
                  .collection('organisations')
                  .doc(orgId)
                  .collection('projects')
                  .get();

          for (final projectDoc in projectsSnapshot.docs) {
            final projectMilestoneDoc =
                await firestore
                    .collection('organisations')
                    .doc(orgId)
                    .collection('projects')
                    .doc(projectDoc.id)
                    .collection('milestones')
                    .doc(sharedId)
                    .get();

            if (projectMilestoneDoc.exists) {
              await firestore
                  .collection('organisations')
                  .doc(orgId)
                  .collection('projects')
                  .doc(projectDoc.id)
                  .collection('milestones')
                  .doc(sharedId)
                  .update({
                    'name': event.name,
                    'description': event.description,
                    'dueDate': event.dueDate,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
            }
          }
        } else {
          // Update only in the current project
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
        }
      }

      emit(ProjectActionSuccess('Milestone updated successfully'));
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

      // Get the milestone to check if it has a sharedId
      final milestoneDoc =
          await firestore
              .collection('organisations')
              .doc(orgId)
              .collection('projects')
              .doc(projectId)
              .collection('milestones')
              .doc(milestoneId)
              .get();

      if (milestoneDoc.exists) {
        final milestoneData = milestoneDoc.data();
        final sharedId = milestoneData?['sharedId'];

        if (sharedId != null) {
          // Delete from all projects that have this shared milestone
          final projectsSnapshot =
              await firestore
                  .collection('organisations')
                  .doc(orgId)
                  .collection('projects')
                  .get();

          for (final projectDoc in projectsSnapshot.docs) {
            final projectMilestoneDoc =
                await firestore
                    .collection('organisations')
                    .doc(orgId)
                    .collection('projects')
                    .doc(projectDoc.id)
                    .collection('milestones')
                    .doc(sharedId)
                    .get();

            if (projectMilestoneDoc.exists) {
              await firestore
                  .collection('organisations')
                  .doc(orgId)
                  .collection('projects')
                  .doc(projectDoc.id)
                  .collection('milestones')
                  .doc(sharedId)
                  .delete();
            }
          }
        } else {
          // Delete only from the current project
          await firestore
              .collection('organisations')
              .doc(orgId)
              .collection('projects')
              .doc(projectId)
              .collection('milestones')
              .doc(milestoneId)
              .delete();
        }
      }

      emit(ProjectActionSuccess('Milestone deleted successfully'));
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

  Future<void> _onAddTask(
    AddTaskEvent event,
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
      final taskId = const Uuid().v4();
      await firestore
          .collection('organisations')
          .doc(orgId)
          .collection('projects')
          .doc(projectId)
          .collection('tasks')
          .doc(taskId)
          .set({
            'name': event.name,
            'content': event.content,
            'deadline': event.deadline,
            'isCompleted': event.isCompleted,
            'milestoneId': event.milestoneId,
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': uid,
          });
      emit(ProjectActionSuccess('Task added successfully'));
    } catch (e) {
      emit(ProjectsError(e.toString()));
    }
  }

  Future<void> _onDeleteTask(
    DeleteTaskEvent event,
    Emitter<ProjectsState> emit,
  ) async {
    emit(ProjectsLoading());
    try {
      final orgId = event.organisationId;
      final projectId = event.projectId;
      final taskId = event.taskId;
      await firestore
          .collection('organisations')
          .doc(orgId)
          .collection('projects')
          .doc(projectId)
          .collection('tasks')
          .doc(taskId)
          .delete();
      emit(ProjectActionSuccess('Task deleted successfully'));
    } catch (e) {
      emit(ProjectsError(e.toString()));
    }
  }

  Future<void> _onUpdateTask(
    UpdateTaskEvent event,
    Emitter<ProjectsState> emit,
  ) async {
    emit(ProjectsLoading());
    try {
      final updateData = {
        'name': event.name,
        'content': event.content,
        'deadline': event.deadline,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (event.isCompleted != null) {
        updateData['isCompleted'] = event.isCompleted as bool;
      }
      await firestore
          .collection('organisations')
          .doc(event.organisationId)
          .collection('projects')
          .doc(event.projectId)
          .collection('tasks')
          .doc(event.taskId)
          .update(updateData);
      emit(ProjectActionSuccess('Task updated successfully'));
    } catch (e) {
      emit(ProjectsError(e.toString()));
    }
  }

  Future<void> _onCompleteMilestone(
    CompleteMilestoneEvent event,
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
          .update({'isCompleted': event.isCompleted});
      emit(
        ProjectActionSuccess(
          'Milestone marked as ${event.isCompleted ? 'completed' : 'incomplete'}',
        ),
      );
    } catch (e) {
      emit(ProjectsError(e.toString()));
    }
  }

  Future<void> _onCreateFileLinkEvent(
    CreateFileLinkEvent event,
    Emitter<ProjectsState> emit,
  ) async {
    emit(ProjectsLoading());
    try {
      final orgId = event.organisationId;
      final projectId = event.projectId;
      final fileId = const Uuid().v4();
      await firestore
          .collection('organisations')
          .doc(orgId)
          .collection('projects')
          .doc(projectId)
          .collection('files')
          .doc(fileId)
          .set({
            'link': event.link,
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': auth.currentUser?.uid ?? '',
            'createdByEmail': auth.currentUser?.email ?? '',
          });
      emit(ProjectActionSuccess('File link created successfully'));
    } catch (e) {
      emit(ProjectsError(e.toString()));
    }
  }

  Future<void> _onDeleteFileLinkEvent(
    DeleteFileLinkEvent event,
    Emitter<ProjectsState> emit,
  ) async {
    emit(ProjectsLoading());
    try {
      final orgId = event.organisationId;
      final projectId = event.projectId;
      final fileId = event.fileId;
      await firestore
          .collection('organisations')
          .doc(orgId)
          .collection('projects')
          .doc(projectId)
          .collection('files')
          .doc(fileId)
          .delete();
      emit(ProjectActionSuccess('File link deleted successfully'));
    } catch (e) {
      emit(ProjectsError(e.toString()));
    }
  }

  /// Copies existing organisation-wide milestones to a new project
  Future<void> _copyOrgWideMilestonesToNewProject(
    String orgId,
    String newProjectId,
  ) async {
    try {
      print(
        '[ProjectsBloc] Copying org-wide milestones to new project: $newProjectId',
      );

      // Get all existing projects in the organisation (excluding the new one)
      final projectsSnapshot =
          await firestore
              .collection('organisations')
              .doc(orgId)
              .collection('projects')
              .where(FieldPath.documentId, isNotEqualTo: newProjectId)
              .get();

      print(
        '[ProjectsBloc] Found ${projectsSnapshot.docs.length} existing projects',
      );

      if (projectsSnapshot.docs.isEmpty) {
        print('[ProjectsBloc] No existing projects, nothing to copy');
        return; // No existing projects, nothing to copy
      }

      // Collect all milestones from all existing projects
      final allMilestones = <Map<String, dynamic>>[];
      for (final projectDoc in projectsSnapshot.docs) {
        final milestonesSnapshot =
            await firestore
                .collection('organisations')
                .doc(orgId)
                .collection('projects')
                .doc(projectDoc.id)
                .collection('milestones')
                .get();

        print(
          '[ProjectsBloc] Project ${projectDoc.id} has ${milestonesSnapshot.docs.length} milestones',
        );

        for (final milestoneDoc in milestonesSnapshot.docs) {
          final milestoneData = milestoneDoc.data();
          milestoneData['projectId'] = projectDoc.id;
          allMilestones.add(milestoneData);
        }
      }

      print(
        '[ProjectsBloc] Total milestones collected: ${allMilestones.length}',
      );

      // Find sharedId values that appear in every existing project
      final sharedIdCounts = <String, int>{};
      for (final milestone in allMilestones) {
        final sharedId = milestone['sharedId'];
        if (sharedId != null && sharedId.toString().isNotEmpty) {
          sharedIdCounts[sharedId] = (sharedIdCounts[sharedId] ?? 0) + 1;
        }
      }

      print('[ProjectsBloc] SharedId counts: $sharedIdCounts');

      // Only include milestones that appear in every existing project (org-wide)
      final orgWideSharedIds =
          sharedIdCounts.entries
              .where((entry) => entry.value == projectsSnapshot.docs.length)
              .map((entry) => entry.key)
              .toSet();

      print('[ProjectsBloc] Org-wide sharedIds: $orgWideSharedIds');

      // Get one representative milestone for each org-wide sharedId
      final orgWideMilestones = <Map<String, dynamic>>[];
      final seenSharedIds = <String>{};

      for (final milestone in allMilestones) {
        final sharedId = milestone['sharedId'];
        if (sharedId != null &&
            orgWideSharedIds.contains(sharedId) &&
            !seenSharedIds.contains(sharedId)) {
          seenSharedIds.add(sharedId);
          orgWideMilestones.add(milestone);
        }
      }

      // Copy each org-wide milestone to the new project
      print(
        '[ProjectsBloc] Copying ${orgWideMilestones.length} org-wide milestones to new project',
      );
      for (final milestone in orgWideMilestones) {
        final milestoneData = Map<String, dynamic>.from(milestone);
        // Remove projectId as it's not part of the milestone document
        milestoneData.remove('projectId');

        print(
          '[ProjectsBloc] Copying milestone: ${milestone['name']} with sharedId: ${milestone['sharedId']}',
        );

        await firestore
            .collection('organisations')
            .doc(orgId)
            .collection('projects')
            .doc(newProjectId)
            .collection('milestones')
            .doc(milestone['sharedId'])
            .set(milestoneData);
      }

      // If no org-wide milestones found, copy all milestones from the first project as a fallback
      if (orgWideMilestones.isEmpty && allMilestones.isNotEmpty) {
        print(
          '[ProjectsBloc] No org-wide milestones found, copying all milestones from first project as fallback',
        );
        final firstProjectMilestones =
            allMilestones
                .where((m) => m['projectId'] == projectsSnapshot.docs.first.id)
                .toList();

        for (final milestone in firstProjectMilestones) {
          final milestoneData = Map<String, dynamic>.from(milestone);
          milestoneData.remove('projectId');

          // Generate a new sharedId for these milestones
          final newSharedId = const Uuid().v4();
          milestoneData['sharedId'] = newSharedId;

          print(
            '[ProjectsBloc] Copying fallback milestone: ${milestone['name']} with new sharedId: $newSharedId',
          );

          await firestore
              .collection('organisations')
              .doc(orgId)
              .collection('projects')
              .doc(newProjectId)
              .collection('milestones')
              .doc(newSharedId)
              .set(milestoneData);
        }
      }

      print(
        '[ProjectsBloc] Successfully copied ${orgWideMilestones.length} milestones to new project',
      );
    } catch (e) {
      print('Error copying org-wide milestones: $e');
      // Don't throw - this shouldn't fail project creation
    }
  }
}

class ProjectWithDetails {
  final String id;
  final Map<String, dynamic> data;
  final List<Map<String, dynamic>> milestones;
  final List<Map<String, dynamic>> comments;
  final List<Map<String, dynamic>> files;
  ProjectWithDetails({
    required this.id,
    required this.data,
    required this.milestones,
    required this.comments,
    required this.files,
  });

  /// Gets the project name from the data map
  String get name =>
      data['name'] as String? ?? data['title'] as String? ?? 'Unknown Project';
}

class _EmitProjectsLoaded extends ProjectsEvent {
  final List<ProjectWithDetails> projects;
  _EmitProjectsLoaded(this.projects);
}

class _EmitProjectsError extends ProjectsEvent {
  final String message;
  _EmitProjectsError(this.message);
}
