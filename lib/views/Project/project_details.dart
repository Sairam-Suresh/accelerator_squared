import 'package:accelerator_squared/models/projects.dart';
import 'package:accelerator_squared/views/Project/comments/comments_dialog.dart';
import 'package:accelerator_squared/views/Project/milestone_sheet.dart';
import 'package:accelerator_squared/views/Project/project_files.dart';
import 'package:accelerator_squared/views/Project/project_settings.dart';
import 'package:accelerator_squared/views/Project/teacher_ui/create_milestone_dialog.dart';
import 'package:accelerator_squared/views/Project/project_members.dart'
    show ProjectMembersDialog;
import 'package:awesome_side_sheet/Enums/sheet_position.dart';
import 'package:awesome_side_sheet/side_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:accelerator_squared/blocs/projects/projects_bloc.dart';
import 'package:accelerator_squared/blocs/organisations/organisations_bloc.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectDetails extends StatefulWidget {
  final String organisationId;
  final Project project;
  final bool isTeacher;
  const ProjectDetails({
    super.key,
    required this.organisationId,
    required this.project,
    required this.isTeacher,
  });

  @override
  State<ProjectDetails> createState() => _ProjectDetailsState();
}

class _ProjectDetailsState extends State<ProjectDetails> {
  Set<String> _deletingMilestoneIds = {};
  String? _pendingDeleteMilestoneId;
  bool showingCompletedMilestones = false;

  @override
  void initState() {
    super.initState();
    // Debug print to verify event call
    print(
      'Dispatching FetchProjectsEvent with orgId: \\${widget.organisationId}, projectId: \\${widget.project.id}',
    );
    context.read<ProjectsBloc>().add(
      FetchProjectsEvent(widget.organisationId, projectId: widget.project.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProjectsBloc, ProjectsState>(
      listener: (context, state) {
        if (state is ProjectActionSuccess &&
            _pendingDeleteMilestoneId != null) {
          setState(() {
            _deletingMilestoneIds.remove(_pendingDeleteMilestoneId);
            _pendingDeleteMilestoneId = null;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<ProjectsBloc, ProjectsState>(
            key: ValueKey(widget.project.id),
            builder: (context, state) {
              String projectName = widget.project.name;
              if (state is ProjectsLoaded) {
                final project = state.projects.firstWhere(
                  (p) => p.id == widget.project.id,
                  orElse:
                      () => ProjectWithDetails(
                        id: widget.project.id,
                        data: {},
                        milestones: [],
                        comments: [],
                      ),
                );
                projectName = project.data['title'] ?? projectName;
              }
              return Text(
                projectName,
                style: TextStyle(fontWeight: FontWeight.bold),
              );
            },
          ),
          actions: [
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return CommentsDialog(
                      commentsContents: const [],
                      commentsList: const [],
                    );
                  },
                );
              },
              icon: Icon(Icons.chat),
            ),
            SizedBox(width: 10),
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, StateSetter setState) {
                        return ProjectMembersDialog(
                          organisationId: widget.organisationId,
                          projectId: widget.project.id,
                        );
                      },
                    );
                  },
                );
              },
              icon: Icon(Icons.group),
            ),
            SizedBox(width: 10),
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return BlocProvider.value(
                      value: context.read<ProjectsBloc>(),
                      child: StatefulBuilder(
                        builder: (context, setState) {
                          return ProjectSettings(
                            organisationId: widget.organisationId,
                            projectId: widget.project.id,
                            projectName: widget.project.name,
                            projectDescription: widget.project.description,
                            isTeacher: widget.isTeacher,
                            onProjectUpdated: () {
                              // Refresh both project and org data
                              context.read<ProjectsBloc>().add(
                                FetchProjectsEvent(
                                  widget.organisationId,
                                  projectId: widget.project.id,
                                ),
                              );
                              context.read<OrganisationsBloc>().add(
                                FetchOrganisationsEvent(),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                );
              },
              icon: Icon(Icons.settings),
            ),
            SizedBox(width: 20),
          ],
        ),
        floatingActionButton:
            widget.isTeacher
                ? FloatingActionButton.extended(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return BlocProvider.value(
                          value: context.read<ProjectsBloc>(),
                          child: StatefulBuilder(
                            builder: (context, StateSetter setState) {
                              return CreateMilestoneDialog(
                                organisationId: widget.organisationId,
                                projects: [widget.project],
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                  label: Text("Create milestone"),
                  icon: Icon(Icons.add),
                )
                : null,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(30, 10, 30, 10),
            child: BlocBuilder<ProjectsBloc, ProjectsState>(
              key: ValueKey(widget.project.id),
              builder: (context, state) {
                // Get the latest project data from the bloc, fallback to widget.project
                String projectName = widget.project.name;
                String projectDescription = widget.project.description;
                List<Map<String, dynamic>> milestones = [];
                if (state is ProjectsLoaded) {
                  final project = state.projects.firstWhere(
                    (p) => p.id == widget.project.id,
                    orElse:
                        () => ProjectWithDetails(
                          id: widget.project.id,
                          data: {},
                          milestones: [],
                          comments: [],
                        ),
                  );
                  projectName = project.data['title'] ?? projectName;
                  projectDescription =
                      project.data['description'] ?? projectDescription;
                  milestones = project.milestones;
                }

                // Safety check to ensure milestones is not null
                if (milestones == null) {
                  milestones = [];
                }

                List<Map<String, dynamic>> completedMilestones =
                    milestones.where((m) => m['isCompleted'] == true).toList();
                List<Map<String, dynamic>> incompleteMilestones =
                    milestones.where((m) => m['isCompleted'] != true).toList();

                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left column: project info, files, etc. (unchanged)
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 2 - 50,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              BlocBuilder<ProjectsBloc, ProjectsState>(
                                key: ValueKey('header_${widget.project.id}'),
                                builder: (context, state) {
                                  String projectName = widget.project.name;
                                  if (state is ProjectsLoaded) {
                                    ProjectWithDetails? project;
                                    try {
                                      project = state.projects.firstWhere(
                                        (p) => p.id == widget.project.id,
                                      );
                                    } catch (e) {
                                      project = null;
                                    }
                                    if (project != null) {
                                      final updatedName = project.data['title'];
                                      if (updatedName != null &&
                                          updatedName.isNotEmpty) {
                                        projectName = updatedName;
                                      }
                                    }
                                  } else if (state is ProjectActionSuccess) {
                                    context.read<ProjectsBloc>().add(
                                      FetchProjectsEvent(
                                        widget.organisationId,
                                        projectId: widget.project.id,
                                      ),
                                    );
                                  }
                                  return Text(
                                    projectName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 60,
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 10),
                              BlocBuilder<ProjectsBloc, ProjectsState>(
                                key: ValueKey(
                                  'description_${widget.project.id}',
                                ),
                                builder: (context, state) {
                                  String projectDescription =
                                      widget.project.description;
                                  if (state is ProjectsLoaded) {
                                    ProjectWithDetails? project;
                                    try {
                                      project = state.projects.firstWhere(
                                        (p) => p.id == widget.project.id,
                                      );
                                    } catch (e) {
                                      project = null;
                                    }
                                    if (project != null) {
                                      final updatedDescription =
                                          project.data['description'];
                                      if (updatedDescription != null &&
                                          updatedDescription.isNotEmpty) {
                                        projectDescription = updatedDescription;
                                      }
                                    }
                                  } else if (state is ProjectActionSuccess) {
                                    context.read<ProjectsBloc>().add(
                                      FetchProjectsEvent(
                                        widget.organisationId,
                                        projectId: widget.project.id,
                                      ),
                                    );
                                  }
                                  return Container(
                                    child: Text(
                                      projectDescription,
                                      style: TextStyle(fontSize: 17.5),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 15),
                              Text(
                                "Files",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 3,
                                    child: ElevatedButton(
                                      onPressed: () {},
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.fromLTRB(
                                          10,
                                          20,
                                          10,
                                          20,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Icon(Icons.article, size: 30),
                                            SizedBox(width: 20),
                                            Text(
                                              "Project brief",
                                              style: TextStyle(fontSize: 18),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  IconButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return StatefulBuilder(
                                            builder: (
                                              context,
                                              StateSetter setState,
                                            ) {
                                              return ProjectFilesDialog(
                                                isTeacher: widget.isTeacher,
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                    icon: Icon(Icons.add),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 20),
                        // Right column: milestones with expanding-upwards animation
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 2 - 50,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Milestones",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  ),
                                  Spacer(),
                                  if (completedMilestones.isNotEmpty)
                                    Checkbox(
                                      value: showingCompletedMilestones,
                                      onChanged: (value) {
                                        setState(() {
                                          showingCompletedMilestones = value!;
                                        });
                                      },
                                    ),
                                  if (completedMilestones.isNotEmpty)
                                    Text("Show completed milestones"),
                                ],
                              ),
                              SizedBox(height: 10),
                              if (state is ProjectsLoading)
                                Container(
                                  height:
                                      MediaQuery.of(context).size.height - 150,
                                  alignment: Alignment.center,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (state is ProjectsLoaded &&
                                  milestones.isEmpty)
                                Container(
                                  height:
                                      MediaQuery.of(context).size.height - 150,
                                  alignment: Alignment.center,
                                  child: Center(
                                    child: Text('No milestones found.'),
                                  ),
                                )
                              else if (state is ProjectsLoaded)
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height - 130,
                                  child: ListView.separated(
                                    separatorBuilder: (context, index) {
                                      // Add a divider between uncompleted and completed milestones
                                      if (showingCompletedMilestones &&
                                          index ==
                                              incompleteMilestones.length - 1 &&
                                          completedMilestones.isNotEmpty) {
                                        return Column(
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 8,
                                              ),
                                              child: Text(
                                                'Completed milestones',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.green,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                      return SizedBox(height: 10);
                                    },
                                    itemCount:
                                        showingCompletedMilestones
                                            ? incompleteMilestones.length +
                                                completedMilestones.length
                                            : incompleteMilestones.length,
                                    itemBuilder: (context, index) {
                                      if (index < incompleteMilestones.length) {
                                        final milestone =
                                            incompleteMilestones[index];

                                        // Safety check for milestone data
                                        if (milestone == null ||
                                            milestone['id'] == null) {
                                          return SizedBox.shrink();
                                        }

                                        return Card(
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            onTap: () {
                                              aweSideSheet(
                                                footer: SizedBox(height: 10),
                                                sheetWidth:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.width /
                                                    3,
                                                context: context,
                                                sheetPosition:
                                                    SheetPosition.right,
                                                body: Padding(
                                                  padding: EdgeInsets.fromLTRB(
                                                    20,
                                                    10,
                                                    20,
                                                    10,
                                                  ),
                                                  child: MilestoneSheet(
                                                    isTeacher: widget.isTeacher,
                                                    milestone: milestone,
                                                    projectTitle: projectName,
                                                    organisationId:
                                                        widget.organisationId,
                                                    projectId:
                                                        widget.project.id,
                                                    allowEdit:
                                                        milestone['sharedId'] ==
                                                        null,
                                                  ),
                                                ),
                                                header: SizedBox(height: 20),
                                                showHeaderDivider: false,
                                              );
                                            },
                                            child: Padding(
                                              padding: EdgeInsets.all(10),
                                              child: ListTile(
                                                leading: Container(
                                                  padding: EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .primaryContainer,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    Icons.flag,
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).colorScheme.primary,
                                                    size: 24,
                                                  ),
                                                ),

                                                title: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        milestone['name'] ?? '',
                                                        style: TextStyle(
                                                          fontSize: 20,
                                                        ),
                                                      ),
                                                    ),
                                                    if (milestone['sharedId'] !=
                                                        null)
                                                      Container(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.blue
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          border: Border.all(
                                                            color: Colors.blue
                                                                .withOpacity(
                                                                  0.3,
                                                                ),
                                                            width: 1,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          'Organization-wide milestone',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.blue,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                subtitle: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      milestone['description'] ??
                                                          '',
                                                      maxLines: 3,
                                                    ),
                                                    if (milestone['dueDate'] !=
                                                        null)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              top: 2.0,
                                                            ),
                                                        child: Text(
                                                          _formatDueDate(
                                                            milestone['dueDate'],
                                                          ),
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                Colors
                                                                    .grey[600],
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                trailing:
                                                    widget.isTeacher &&
                                                            milestone['sharedId'] ==
                                                                null
                                                        ? (_deletingMilestoneIds
                                                                .contains(
                                                                  milestone['id'],
                                                                )
                                                            ? SizedBox(
                                                              width: 24,
                                                              height: 24,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2,
                                                                    color:
                                                                        Colors
                                                                            .red,
                                                                  ),
                                                            )
                                                            : IconButton(
                                                              icon: Icon(
                                                                Icons.delete,
                                                              ),
                                                              color:
                                                                  Colors.white,
                                                              style: ButtonStyle(
                                                                iconColor:
                                                                    MaterialStateProperty.all<
                                                                      Color
                                                                    >(
                                                                      Colors
                                                                          .red,
                                                                    ),
                                                              ),
                                                              onPressed: () async {
                                                                final confirm = await showDialog<
                                                                  bool
                                                                >(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (
                                                                        context,
                                                                      ) => AlertDialog(
                                                                        title: Text(
                                                                          'Delete Milestone',
                                                                        ),
                                                                        content:
                                                                            Text(
                                                                              'Are you sure you want to delete this milestone?',
                                                                            ),
                                                                        actions: [
                                                                          TextButton(
                                                                            onPressed:
                                                                                () => Navigator.of(
                                                                                  context,
                                                                                ).pop(
                                                                                  false,
                                                                                ),
                                                                            child: Text(
                                                                              'Cancel',
                                                                            ),
                                                                          ),
                                                                          ElevatedButton(
                                                                            style: ElevatedButton.styleFrom(
                                                                              backgroundColor:
                                                                                  Colors.red,
                                                                              foregroundColor:
                                                                                  Colors.white,
                                                                            ),
                                                                            onPressed:
                                                                                () => Navigator.of(
                                                                                  context,
                                                                                ).pop(
                                                                                  true,
                                                                                ),
                                                                            child: Text(
                                                                              'Delete',
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                );
                                                                if (confirm ==
                                                                    true) {
                                                                  setState(() {
                                                                    _deletingMilestoneIds
                                                                        .add(
                                                                          milestone['id'],
                                                                        );
                                                                    _pendingDeleteMilestoneId =
                                                                        milestone['id'];
                                                                  });
                                                                  final bloc =
                                                                      context
                                                                          .read<
                                                                            ProjectsBloc
                                                                          >();
                                                                  late final StreamSubscription
                                                                  subscription;
                                                                  subscription = bloc.stream.listen((
                                                                    state,
                                                                  ) {
                                                                    if (state
                                                                        is ProjectActionSuccess) {
                                                                      bloc.add(
                                                                        FetchProjectsEvent(
                                                                          widget
                                                                              .organisationId,
                                                                          projectId:
                                                                              widget.project.id,
                                                                        ),
                                                                      );
                                                                      subscription
                                                                          .cancel();
                                                                      if (mounted) {
                                                                        setState(() {
                                                                          _deletingMilestoneIds.remove(
                                                                            milestone['id'],
                                                                          );
                                                                          _pendingDeleteMilestoneId =
                                                                              null;
                                                                        });
                                                                      }
                                                                    } else if (state
                                                                        is ProjectsError) {
                                                                      subscription
                                                                          .cancel();
                                                                      if (mounted) {
                                                                        setState(() {
                                                                          _deletingMilestoneIds.remove(
                                                                            milestone['id'],
                                                                          );
                                                                          _pendingDeleteMilestoneId =
                                                                              null;
                                                                        });
                                                                        ScaffoldMessenger.of(
                                                                          context,
                                                                        ).showSnackBar(
                                                                          SnackBar(
                                                                            content: Text(
                                                                              state.message,
                                                                            ),
                                                                            backgroundColor:
                                                                                Colors.red,
                                                                          ),
                                                                        );
                                                                      }
                                                                    }
                                                                  });
                                                                  bloc.add(
                                                                    DeleteMilestoneEvent(
                                                                      organisationId:
                                                                          widget
                                                                              .organisationId,
                                                                      projectId:
                                                                          widget
                                                                              .project
                                                                              .id,
                                                                      milestoneId:
                                                                          milestone['id'],
                                                                    ),
                                                                  );
                                                                }
                                                              },
                                                            ))
                                                        : null,
                                              ),
                                            ),
                                          ),
                                        );
                                      } else {
                                        // Completed milestones
                                        final completedIndex =
                                            index - incompleteMilestones.length;
                                        final milestone =
                                            completedMilestones[completedIndex];
                                        return Card(
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            onTap: () {
                                              aweSideSheet(
                                                footer: SizedBox(height: 10),
                                                sheetWidth:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.width /
                                                    3,
                                                context: context,
                                                sheetPosition:
                                                    SheetPosition.right,
                                                body: Padding(
                                                  padding: EdgeInsets.fromLTRB(
                                                    20,
                                                    10,
                                                    20,
                                                    10,
                                                  ),
                                                  child: MilestoneSheet(
                                                    isTeacher: widget.isTeacher,
                                                    milestone: milestone,
                                                    projectTitle: projectName,
                                                    organisationId:
                                                        widget.organisationId,
                                                    projectId:
                                                        widget.project.id,
                                                    allowEdit: false,
                                                  ),
                                                ),
                                                header: SizedBox(height: 20),
                                                showHeaderDivider: false,
                                              );
                                            },
                                            child: Padding(
                                              padding: EdgeInsets.all(10),
                                              child: ListTile(
                                                leading: Container(
                                                  padding: EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .primaryContainer,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Opacity(
                                                    opacity: 0.5,
                                                    child: Icon(
                                                      Icons.flag,
                                                      color: Colors.green,
                                                      size: 24,
                                                    ),
                                                  ),
                                                ),

                                                title: Opacity(
                                                  opacity: 0.5,
                                                  child: Text(
                                                    milestone['name'] ?? '',
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                    ),
                                                  ),
                                                ),
                                                subtitle: Opacity(
                                                  opacity: 0.5,
                                                  child: Text(
                                                    milestone['description'] ??
                                                        '',
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                )
                              else if (state is ProjectsError)
                                Text('Error: {state.message}')
                              else
                                SizedBox.shrink(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _formatDueDate(dynamic dueDateRaw) {
    if (dueDateRaw == null) return '';
    DateTime? dueDate;
    if (dueDateRaw is DateTime) {
      dueDate = dueDateRaw;
    } else if (dueDateRaw is String) {
      try {
        dueDate = DateTime.parse(dueDateRaw);
      } catch (_) {}
    } else if (dueDateRaw is Timestamp) {
      dueDate = dueDateRaw.toDate();
    }
    if (dueDate != null) {
      return 'Due: 	${dueDate.day.toString().padLeft(2, '0')}/${dueDate.month.toString().padLeft(2, '0')}/${dueDate.year.toString().substring(2)}';
    }
    return '';
  }
}
