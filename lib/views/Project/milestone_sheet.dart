import 'package:accelerator_squared/views/Project/tasks/create_task_dialog.dart';
import 'package:awesome_side_sheet/Enums/sheet_position.dart';
import 'package:awesome_side_sheet/side_sheet.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:accelerator_squared/blocs/projects/projects_bloc.dart';
import 'dart:async';

class MilestoneSheet extends StatefulWidget {
  const MilestoneSheet({
    super.key,
    required this.milestone,
    required this.projectTitle,
    required this.organisationId,
    required this.projectId,
    required this.isTeacher,
  });

  final bool isTeacher;
  final Map<String, dynamic> milestone;
  final String projectTitle;
  final String organisationId;
  final String projectId;

  @override
  State<MilestoneSheet> createState() => _MilestoneSheetState();
}

class _MilestoneSheetState extends State<MilestoneSheet> {
  bool _isDeleting = false;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUpdatingDate = false;
  bool _tasksLoading = true;

  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController dueDateController = TextEditingController();

  StreamSubscription? _deleteSubscription;
  StreamSubscription? _saveSubscription;
  StreamSubscription? _dateUpdateSubscription;
  List<Map<String, dynamic>> _tasks = [];
  StreamSubscription? _tasksSubscription;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.milestone['name'] ?? '';
    descriptionController.text = widget.milestone['description'] ?? '';
    _listenToTasks();
  }

  void _listenToTasks() {
    _tasksSubscription?.cancel();
    final orgId = widget.organisationId;
    final projectId = widget.projectId;
    setState(() {
      _tasksLoading = true;
    });
    _tasksSubscription = FirebaseFirestore.instance
        .collection('organisations')
        .doc(orgId)
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .snapshots()
        .listen((snapshot) {
          setState(() {
            _tasks =
                snapshot.docs
                    .map((doc) => {...doc.data(), 'id': doc.id})
                    .where(
                      (task) => task['milestoneId'] == widget.milestone['id'],
                    )
                    .toList();
            _tasksLoading = false;
          });
        });
  }

  @override
  void dispose() {
    _deleteSubscription?.cancel();
    _saveSubscription?.cancel();
    _dateUpdateSubscription?.cancel();
    _tasksSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final milestone = widget.milestone;
    final projectTitle = widget.projectTitle;
    // Format due date
    String formattedDueDate = 'Unknown';
    final dueDateRaw = milestone['dueDate'];
    if (dueDateRaw != null) {
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
        formattedDueDate = DateFormat('dd/MM/yy').format(dueDate);
      }
    }
    return BlocListener<ProjectsBloc, ProjectsState>(
      listener: (context, state) {
        if (state is ProjectActionSuccess &&
            state.message == 'Task deleted successfully') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Task deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is ProjectsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.flag_rounded,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _isEditing
                          ? SizedBox(
                            width: MediaQuery.of(context).size.width / 5,
                            child: TextField(
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              controller: nameController,
                              decoration: InputDecoration(
                                hintText: "Enter milestone name",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          )
                          : BlocBuilder<ProjectsBloc, ProjectsState>(
                            builder: (context, state) {
                              // Get the current milestone data from the bloc if available
                              String displayName =
                                  nameController.text.isNotEmpty
                                      ? nameController.text
                                      : (milestone['name'] ?? '');

                              if (state is ProjectsLoaded) {
                                // Try to find updated milestone data
                                ProjectWithDetails? project;
                                try {
                                  project = state.projects.firstWhere(
                                    (p) => p.id == widget.projectId,
                                  );
                                } catch (e) {
                                  project = null;
                                }

                                if (project != null) {
                                  Map<String, dynamic>? updatedMilestone;
                                  try {
                                    updatedMilestone = project.milestones
                                        .firstWhere(
                                          (m) => m['id'] == milestone['id'],
                                        );
                                  } catch (e) {
                                    updatedMilestone = null;
                                  }

                                  if (updatedMilestone != null) {
                                    displayName =
                                        updatedMilestone['name'] ?? displayName;
                                    // Update the controller if the data changed
                                    if (nameController.text != displayName) {
                                      nameController.text = displayName;
                                    }
                                  }
                                }
                              }

                              return Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              );
                            },
                          ),
                      SizedBox(height: 4),
                      Text(
                        "Milestone",
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  !_isEditing
                      ? IconButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                        icon: Icon(Icons.edit, size: 20),
                        tooltip: "Edit milestone",
                      )
                      : IconButton(
                        onPressed:
                            _isSaving
                                ? null
                                : () async {
                                  final name = nameController.text.trim();
                                  final description =
                                      descriptionController.text.trim();

                                  if (name.isEmpty || description.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Name and description cannot be empty',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() {
                                    _isSaving = true;
                                  });

                                  final bloc = context.read<ProjectsBloc>();
                                  _saveSubscription = bloc.stream.listen((
                                    state,
                                  ) {
                                    if (state is ProjectActionSuccess) {
                                      _saveSubscription?.cancel();
                                      if (mounted) {
                                        setState(() {
                                          _isEditing = false;
                                          _isSaving = false;
                                        });
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Milestone updated successfully',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } else if (state is ProjectsError) {
                                      _saveSubscription?.cancel();
                                      if (mounted) {
                                        setState(() {
                                          _isSaving = false;
                                        });
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(state.message),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  });

                                  try {
                                    if (mounted) {
                                      bloc.add(
                                        UpdateMilestoneEvent(
                                          organisationId: widget.organisationId,
                                          projectId: widget.projectId,
                                          milestoneId: milestone['id'],
                                          name: name,
                                          description: description,
                                          dueDate:
                                              milestone['dueDate'] is DateTime
                                                  ? milestone['dueDate']
                                                  : (milestone['dueDate']
                                                          is Timestamp
                                                      ? milestone['dueDate']
                                                          .toDate()
                                                      : DateTime.now()),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    _saveSubscription?.cancel();
                                    if (mounted) {
                                      setState(() {
                                        _isSaving = false;
                                      });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                        icon:
                            _isSaving
                                ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                )
                                : Icon(Icons.save),
                      ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Details section
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info rows
                  _buildInfoRow(
                    Icons.person_rounded,
                    "Assigned by",
                    milestone['createdByEmail'] ?? 'Unknown',
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Due on",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 5),
                  _isEditing
                      ? ElevatedButton.icon(
                        icon:
                            _isUpdatingDate
                                ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                )
                                : Icon(Icons.calendar_month_outlined),
                        onPressed:
                            _isUpdatingDate
                                ? null
                                : () async {
                                  // Get current due date as initial date
                                  DateTime initialDate = DateTime.now();
                                  final dueDateRaw = milestone['dueDate'];
                                  if (dueDateRaw != null) {
                                    if (dueDateRaw is DateTime) {
                                      initialDate = dueDateRaw;
                                    } else if (dueDateRaw is Timestamp) {
                                      initialDate = dueDateRaw.toDate();
                                    }
                                  }

                                  final DateTime? pickedDate =
                                      await showDatePicker(
                                        context: context,
                                        initialDate: initialDate,
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(
                                          Duration(days: 365),
                                        ),
                                      );

                                  if (pickedDate != null) {
                                    setState(() {
                                      _isUpdatingDate = true;
                                    });

                                    final bloc = context.read<ProjectsBloc>();
                                    _dateUpdateSubscription = bloc.stream.listen((
                                      state,
                                    ) {
                                      if (state is ProjectActionSuccess) {
                                        // Don't stop loading yet, wait for the next ProjectsLoaded state
                                        // to verify the date was actually updated
                                      } else if (state is ProjectsLoaded) {
                                        // Check if the date was actually updated by looking at the current state
                                        ProjectWithDetails? project;
                                        try {
                                          project = state.projects.firstWhere(
                                            (p) => p.id == widget.projectId,
                                          );
                                        } catch (e) {
                                          project = null;
                                        }

                                        if (project != null) {
                                          Map<String, dynamic>?
                                          updatedMilestone;
                                          try {
                                            updatedMilestone = project
                                                .milestones
                                                .firstWhere(
                                                  (m) =>
                                                      m['id'] ==
                                                      milestone['id'],
                                                );
                                          } catch (e) {
                                            updatedMilestone = null;
                                          }

                                          if (updatedMilestone != null) {
                                            final updatedDueDateRaw =
                                                updatedMilestone['dueDate'];
                                            if (updatedDueDateRaw != null) {
                                              DateTime? updatedDueDate;
                                              if (updatedDueDateRaw
                                                  is DateTime) {
                                                updatedDueDate =
                                                    updatedDueDateRaw;
                                              } else if (updatedDueDateRaw
                                                  is Timestamp) {
                                                updatedDueDate =
                                                    updatedDueDateRaw.toDate();
                                              }

                                              // Only stop loading if the date matches the picked date
                                              if (updatedDueDate != null &&
                                                  updatedDueDate.year ==
                                                      pickedDate.year &&
                                                  updatedDueDate.month ==
                                                      pickedDate.month &&
                                                  updatedDueDate.day ==
                                                      pickedDate.day) {
                                                _dateUpdateSubscription
                                                    ?.cancel();
                                                if (mounted) {
                                                  setState(() {
                                                    _isUpdatingDate = false;
                                                  });
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Due date updated successfully',
                                                      ),
                                                      backgroundColor:
                                                          Colors.green,
                                                    ),
                                                  );
                                                }
                                              }
                                            }
                                          }
                                        }
                                      } else if (state is ProjectsError) {
                                        _dateUpdateSubscription?.cancel();
                                        if (mounted) {
                                          setState(() {
                                            _isUpdatingDate = false;
                                          });
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(state.message),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    });

                                    try {
                                      if (mounted) {
                                        bloc.add(
                                          UpdateMilestoneEvent(
                                            organisationId:
                                                widget.organisationId,
                                            projectId: widget.projectId,
                                            milestoneId: milestone['id'],
                                            name:
                                                nameController.text.isNotEmpty
                                                    ? nameController.text
                                                    : (milestone['name'] ?? ''),
                                            description:
                                                descriptionController
                                                        .text
                                                        .isNotEmpty
                                                    ? descriptionController.text
                                                    : (milestone['description'] ??
                                                        ''),
                                            dueDate: pickedDate,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      _dateUpdateSubscription?.cancel();
                                      if (mounted) {
                                        setState(() {
                                          _isUpdatingDate = false;
                                        });
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                        label: Padding(
                          padding: EdgeInsets.all(10),
                          child: BlocBuilder<ProjectsBloc, ProjectsState>(
                            builder: (context, state) {
                              // Get the current milestone data from the bloc if available
                              String displayDueDate = formattedDueDate;

                              if (state is ProjectsLoaded) {
                                // Try to find updated milestone data
                                ProjectWithDetails? project;
                                try {
                                  project = state.projects.firstWhere(
                                    (p) => p.id == widget.projectId,
                                  );
                                } catch (e) {
                                  project = null;
                                }

                                if (project != null) {
                                  Map<String, dynamic>? updatedMilestone;
                                  try {
                                    updatedMilestone = project.milestones
                                        .firstWhere(
                                          (m) => m['id'] == milestone['id'],
                                        );
                                  } catch (e) {
                                    updatedMilestone = null;
                                  }

                                  if (updatedMilestone != null) {
                                    // Format the updated due date
                                    final updatedDueDateRaw =
                                        updatedMilestone['dueDate'];
                                    if (updatedDueDateRaw != null) {
                                      DateTime? updatedDueDate;
                                      if (updatedDueDateRaw is DateTime) {
                                        updatedDueDate = updatedDueDateRaw;
                                      } else if (updatedDueDateRaw
                                          is Timestamp) {
                                        updatedDueDate =
                                            updatedDueDateRaw.toDate();
                                      }
                                      if (updatedDueDate != null) {
                                        displayDueDate = DateFormat(
                                          'dd/MM/yy',
                                        ).format(updatedDueDate);
                                      }
                                    }
                                  }
                                }
                              }

                              return Text(
                                displayDueDate,
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                  height: 1.5,
                                ),
                              );
                            },
                          ),
                        ),
                      )
                      : Text(
                        formattedDueDate,
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                  SizedBox(height: 12),
                  // Text(
                  //   "Projects",
                  //   style: TextStyle(
                  //     fontSize: 16,
                  //     fontWeight: FontWeight.w600,
                  //     color: Theme.of(context).colorScheme.onSurface,
                  //   ),
                  // ),
                  // SizedBox(height: 10),

                  // BlocBuilder<OrganisationsBloc, OrganisationsState>(
                  //   builder: (context, orgState) {
                  //     if (orgState is OrganisationsLoaded) {
                  //       final currentOrg = orgState.organisations.firstWhere(
                  //         (org) => org.id == widget.organisationId,
                  //         orElse: () => throw Exception('Organisation not found'),
                  //       );

                  //       // Get the sharedId of this milestone
                  //       final sharedId = milestone['sharedId'];

                  //       if (sharedId != null) {
                  //         // Find all projects that have this milestone
                  //         final assignedProjects =
                  //             currentOrg.projects.where((project) {
                  //               // For now, we'll show all projects since we can't easily check
                  //               // which ones have this specific milestone without additional queries
                  //               // In a real implementation, you might want to store this information
                  //               return true; // Show all projects for now
                  //             }).toList();

                  //         if (assignedProjects.isNotEmpty) {
                  //           return Column(
                  //             crossAxisAlignment: CrossAxisAlignment.start,
                  //             children:
                  //                 assignedProjects.map((project) {
                  //                   return Padding(
                  //                     padding: EdgeInsets.only(bottom: 8),
                  //                     child: Row(
                  //                       children: [
                  //                         Container(
                  //                           padding: EdgeInsets.all(10),
                  //                           decoration: BoxDecoration(
                  //                             color:
                  //                                 Theme.of(context)
                  //                                     .colorScheme
                  //                                     .secondaryContainer,
                  //                             borderRadius: BorderRadius.circular(
                  //                               8,
                  //                             ),
                  //                           ),
                  //                           child: Icon(
                  //                             Icons.folder,
                  //                             color:
                  //                                 Theme.of(context)
                  //                                     .colorScheme
                  //                                     .onSecondaryContainer,
                  //                             size: 20,
                  //                           ),
                  //                         ),
                  //                         SizedBox(width: 12),
                  //                         Expanded(
                  //                           child: Text(
                  //                             project.name,
                  //                             style: TextStyle(
                  //                               fontSize: 16,
                  //                               color:
                  //                                   Theme.of(context)
                  //                                       .colorScheme
                  //                                       .onSurfaceVariant,
                  //                             ),
                  //                           ),
                  //                         ),
                  //                       ],
                  //                     ),
                  //                   );
                  //                 }).toList(),
                  //           );
                  //         } else {
                  //           return Text(
                  //             'No projects assigned',
                  //             style: TextStyle(
                  //               fontSize: 14,
                  //               color:
                  //                   Theme.of(
                  //                     context,
                  //                   ).colorScheme.onSurfaceVariant,
                  //               fontStyle: FontStyle.italic,
                  //             ),
                  //           );
                  //         }
                  //       } else {
                  //         // If no sharedId, show only the current project
                  //         return Row(
                  //           children: [
                  //             Container(
                  //               padding: EdgeInsets.all(8),
                  //               decoration: BoxDecoration(
                  //                 color:
                  //                     Theme.of(
                  //                       context,
                  //                     ).colorScheme.secondaryContainer,
                  //                 borderRadius: BorderRadius.circular(8),
                  //               ),
                  //               child: Icon(
                  //                 Icons.folder,
                  //                 color:
                  //                     Theme.of(
                  //                       context,
                  //                     ).colorScheme.onSecondaryContainer,
                  //                 size: 16,
                  //               ),
                  //             ),
                  //             SizedBox(width: 12),
                  //             Expanded(
                  //               child: Text(
                  //                 widget.projectTitle,
                  //                 style: TextStyle(
                  //                   fontSize: 14,
                  //                   color:
                  //                       Theme.of(
                  //                         context,
                  //                       ).colorScheme.onSurfaceVariant,
                  //                 ),
                  //               ),
                  //             ),
                  //           ],
                  //         );
                  //       }
                  //     }

                  //     // Loading state
                  //     return Row(
                  //       children: [
                  //         SizedBox(
                  //           width: 16,
                  //           height: 16,
                  //           child: CircularProgressIndicator(strokeWidth: 2),
                  //         ),
                  //         SizedBox(width: 12),
                  //         Text(
                  //           'Loading projects...',
                  //           style: TextStyle(
                  //             fontSize: 14,
                  //             color:
                  //                 Theme.of(context).colorScheme.onSurfaceVariant,
                  //           ),
                  //         ),
                  //       ],
                  //     );
                  //   },
                  // ),

                  // Description
                  Text(
                    "Description:",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 5),
                  _isEditing
                      ? SizedBox(
                        width: MediaQuery.of(context).size.width / 3 - 50,
                        child: TextField(
                          minLines: 3,
                          maxLines: 5,
                          controller: descriptionController,
                          decoration: InputDecoration(
                            hintText: "Enter milestone description",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      )
                      : BlocBuilder<ProjectsBloc, ProjectsState>(
                        builder: (context, state) {
                          // Get the current milestone data from the bloc if available
                          String displayDescription =
                              descriptionController.text.isNotEmpty
                                  ? descriptionController.text
                                  : (milestone['description'] ?? '');

                          if (state is ProjectsLoaded) {
                            // Try to find updated milestone data
                            ProjectWithDetails? project;
                            try {
                              project = state.projects.firstWhere(
                                (p) => p.id == widget.projectId,
                              );
                            } catch (e) {
                              project = null;
                            }

                            if (project != null) {
                              Map<String, dynamic>? updatedMilestone;
                              try {
                                updatedMilestone = project.milestones
                                    .firstWhere(
                                      (m) => m['id'] == milestone['id'],
                                    );
                              } catch (e) {
                                updatedMilestone = null;
                              }

                              if (updatedMilestone != null) {
                                displayDescription =
                                    updatedMilestone['description'] ??
                                    displayDescription;
                                // Update the controller if the data changed
                                if (descriptionController.text !=
                                    displayDescription) {
                                  descriptionController.text =
                                      displayDescription;
                                }
                              }
                            }
                          }

                          return Text(
                            displayDescription,
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          );
                        },
                      ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Action button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: () {
                  // Navigator.of(context).pop();
                },
                icon: Icon(Icons.send_rounded, size: 20),
                label: Text(
                  "Send for review",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            SizedBox(height: 20),

            widget.isTeacher
                ? SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    onPressed:
                        _isDeleting
                            ? null
                            : () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: Text('Delete Milestone'),
                                      content: Text(
                                        'Are you sure you want to delete this milestone?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(false),
                                          child: Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(true),
                                          child: Text('Delete'),
                                        ),
                                      ],
                                    ),
                              );
                              if (confirm == true) {
                                setState(() => _isDeleting = true);
                                final bloc = context.read<ProjectsBloc>();
                                _deleteSubscription?.cancel();
                                _deleteSubscription = bloc.stream.listen((
                                  state,
                                ) {
                                  if (state is ProjectActionSuccess) {
                                    _deleteSubscription?.cancel();
                                    if (mounted) {
                                      bloc.add(
                                        FetchProjectsEvent(
                                          widget.organisationId,
                                          projectId: widget.projectId,
                                        ),
                                      );
                                      Navigator.of(context).pop();
                                    }
                                  } else if (state is ProjectsError) {
                                    _deleteSubscription?.cancel();
                                    if (mounted) {
                                      setState(() => _isDeleting = false);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(state.message),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                });
                                try {
                                  if (mounted) {
                                    bloc.add(
                                      DeleteMilestoneEvent(
                                        organisationId: widget.organisationId,
                                        projectId: widget.projectId,
                                        milestoneId: milestone['id'],
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  _deleteSubscription?.cancel();
                                  if (mounted) {
                                    setState(() => _isDeleting = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                    icon:
                        _isDeleting
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : Icon(Icons.delete, size: 20),
                    label: Text(
                      "Delete milestone",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                : SizedBox(),

            SizedBox(height: 24),

            // Tasks section
            Row(
              children: [
                Icon(
                  Icons.checklist_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  "Tasks",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(width: 24),
                SizedBox(
                  height: 35,
                  width: 175,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () async {
                      final result = await showDialog(
                        context: context,
                        builder: (context) {
                          return CreateTaskDialog(
                            organisationId: widget.organisationId,
                            projectId: widget.projectId,
                            milestoneId: widget.milestone['id'],
                          );
                        },
                      );
                      // Optionally, refresh tasks here if not using real-time
                    },
                    icon: Icon(Icons.add, size: 20),
                    label: Text(
                      "Create task",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            if (_tasksLoading)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_tasks.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'No tasks found for this milestone.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.task_rounded,
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        _tasks[index]['name'] ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          _tasks[index]['content'] ?? '',
                          maxLines: 2,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      trailing: IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Delete Task'),
                                content: Text(
                                  'Are you sure you want to delete this task? This action cannot be undone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      context.read<ProjectsBloc>().add(
                                        DeleteTaskEvent(
                                          organisationId: widget.organisationId,
                                          projectId: widget.projectId,
                                          taskId: _tasks[index]['id'],
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                    child: Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        icon: Icon(Icons.delete, color: Colors.red),
                      ),
                      onTap: () {
                        aweSideSheet(
                          footer: SizedBox(height: 10),
                          sheetPosition: SheetPosition.right,
                          sheetWidth: MediaQuery.of(context).size.width / 3,
                          context: context,
                          body: Padding(
                            padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                            child: _buildTaskDetailSheet(index, _tasks),
                          ),
                          header: SizedBox(height: 20),
                          onCancel: () => Navigator.of(context).pop(),
                        );
                      },
                    ),
                  );
                },
                separatorBuilder: (context, index) => SizedBox(height: 8),
                itemCount: _tasks.length,
                shrinkWrap: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            SizedBox(width: 12),
            Text(
              "$label: ",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskDetailSheet(int index, [List? tasksOverride]) {
    final milestone = widget.milestone;
    final tasks = tasksOverride ?? _tasks;
    final task = tasks[index];
    String formattedDueDate = 'Unknown';
    final dueDateRaw = task['deadline'];
    if (dueDateRaw != null) {
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
        formattedDueDate =
            '${dueDate.day.toString().padLeft(2, '0')}/${dueDate.month.toString().padLeft(2, '0')}/${dueDate.year.toString().substring(2)}';
      }
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Task header
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.task_rounded,
                  color: Theme.of(context).colorScheme.onSecondary,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['name'] ?? '',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Task",
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24),

        // Task details
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(
                Icons.calendar_today_rounded,
                "Due on",
                formattedDueDate,
              ),
              SizedBox(height: 20),

              Text(
                "Description",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 8),
              Text(
                task['content'] ?? '',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            onPressed: () {
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Delete Task'),
                    content: Text(
                      'Are you sure you want to delete this task? This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Delete the task
                          context.read<ProjectsBloc>().add(
                            DeleteTaskEvent(
                              organisationId: widget.organisationId,
                              projectId: widget.projectId,
                              taskId: task['id'],
                            ),
                          );
                          // Close the task detail sheet
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        child: Text('Delete'),
                      ),
                    ],
                  );
                },
              );
            },
            label: Text(
              "Delete Task",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            icon: Icon(Icons.delete, size: 20),
          ),
        ),
        SizedBox(height: 20),
        // Complete button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            onPressed: () {
              var navigator = Navigator.of(context);
              navigator.pop();
            },
            icon: Icon(Icons.check_rounded, size: 20),
            label: Text(
              "Mark as Completed",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
