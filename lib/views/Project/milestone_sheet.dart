import 'package:accelerator_squared/views/Project/tasks/create_task_dialog.dart';
import 'package:awesome_side_sheet/Enums/sheet_position.dart';
import 'package:awesome_side_sheet/side_sheet.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:accelerator_squared/blocs/projects/projects_bloc.dart';
import 'package:accelerator_squared/blocs/organisations/organisations_bloc.dart';
import 'dart:async';

class MilestoneSheet extends StatefulWidget {
  const MilestoneSheet({
    super.key,
    required this.milestone,
    required this.projectTitle,
    required this.organisationId,
    required this.projectId,
    required this.isTeacher,
    this.allowEdit = false,
  });

  final bool isTeacher;
  final Map<String, dynamic> milestone;
  final String projectTitle;
  final String organisationId;
  final String projectId;
  final bool allowEdit;

  @override
  State<MilestoneSheet> createState() => _MilestoneSheetState();
}

class _MilestoneSheetState extends State<MilestoneSheet> {
  bool _isDeleting = false;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUpdatingDate = false;
  bool _tasksLoading = true;
  bool _isSendingTaskReview = false;
  bool _isUnsendTaskReview = false;
  bool _showCompletedTasks = false;

  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController dueDateController = TextEditingController();
  TextEditingController taskNameController = TextEditingController();
  TextEditingController taskDescriptionController = TextEditingController();
  DateTime? taskDueDate;
  int? editingTaskIndex;

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
    final bool isCompleted = widget.milestone['isCompleted'] == true;
    // Compute completed/incomplete tasks
    final completedTasks =
        _tasks.where((t) => t['isCompleted'] == true).toList();
    final incompleteTasks =
        _tasks.where((t) => t['isCompleted'] != true).toList();
    final allTasksCompleted = incompleteTasks.isEmpty && _tasks.isNotEmpty;
    // Automatically show completed tasks if there are no incomplete tasks
    if (!_tasksLoading &&
        incompleteTasks.isEmpty &&
        completedTasks.isNotEmpty &&
        !_showCompletedTasks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _showCompletedTasks = true);
      });
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

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                    ),
                                  ),
                                  widget.milestone['sharedId'] != null
                                      ? Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.blue.withOpacity(
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
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      )
                                      : Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.blue.withOpacity(
                                                0.3,
                                              ),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            'Milestone',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                ],
                              );
                            },
                          ),
                    ],
                  ),
                  Spacer(),
                  // Only show edit button if milestone is not organization-wide (no sharedId) or allowEdit is true
                  (widget.milestone['sharedId'] == null || widget.allowEdit)
                      ? (!_isEditing
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
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
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
                                              organisationId:
                                                  widget.organisationId,
                                              projectId: widget.projectId,
                                              milestoneId: milestone['id'],
                                              name: name,
                                              description: description,
                                              dueDate:
                                                  milestone['dueDate']
                                                          is DateTime
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
                                            Theme.of(
                                              context,
                                            ).colorScheme.onPrimary,
                                      ),
                                    )
                                    : Icon(Icons.save),
                          ))
                      : SizedBox(), // Hide edit button for organization-wide milestones
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
                  if (widget.milestone['sharedId'] != null &&
                      !widget.allowEdit) ...[
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This is an organization-wide milestone. It can only be edited or deleted from the organization milestones page.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                                  final DateTime initialDate =
                                      taskDueDate ?? DateTime.now();
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: initialDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      taskDueDate = picked;
                                    });
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

            SizedBox(height: 12),
            // Action button
            widget.isTeacher
                ? SizedBox(
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
                      final bloc = context.read<ProjectsBloc>();
                      bloc.add(
                        CompleteMilestoneEvent(
                          organisationId: widget.organisationId,
                          projectId: widget.projectId,
                          milestoneId: widget.milestone['id'],
                          isCompleted: !isCompleted,
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                    icon:
                        widget.isTeacher
                            ? Icon(
                              isCompleted ? Icons.undo : Icons.check,
                              size: 20,
                            )
                            : Icon(Icons.send_rounded, size: 20),
                    label: Text(
                      isCompleted ? "Mark as incomplete" : "Mark as completed",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                : SizedBox.shrink(),

            if (!isCompleted &&
                (widget.milestone['pendingReview'] != true &&
                    !widget.isTeacher)) ...[
              if (!isCompleted &&
                  (widget.milestone['pendingReview'] != true &&
                      !widget.isTeacher)) ...[
                BlocProvider<OrganisationsBloc>(
                  create: (context) => OrganisationsBloc(),
                  child: Builder(
                    builder: (context) {
                      bool _isSending = false;
                      return StatefulBuilder(
                        builder: (context, setState) {
                          return SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              onPressed:
                                  !_tasksLoading &&
                                          (_tasks.isEmpty ||
                                              allTasksCompleted) &&
                                          !_isSending
                                      ? () async {
                                        setState(() => _isSending = true);
                                        final orgBloc =
                                            context.read<OrganisationsBloc>();
                                        orgBloc.add(
                                          SubmitMilestoneReviewRequestEvent(
                                            organisationId:
                                                widget.organisationId,
                                            projectId: widget.projectId,
                                            milestoneId: widget.milestone['id'],
                                            milestoneName:
                                                widget.milestone['name'] ?? '',
                                            projectName: widget.projectTitle,
                                            isOrgWide:
                                                widget.milestone['sharedId'] !=
                                                null,
                                            dueDate:
                                                (widget.milestone['dueDate']
                                                        is DateTime)
                                                    ? widget
                                                        .milestone['dueDate']
                                                    : (widget.milestone['dueDate']
                                                            is Timestamp
                                                        ? widget
                                                            .milestone['dueDate']
                                                            .toDate()
                                                        : DateTime.now()),
                                          ),
                                        );
                                        orgBloc.stream
                                            .firstWhere(
                                              (state) =>
                                                  state
                                                      is OrganisationsLoaded ||
                                                  state is OrganisationsError,
                                            )
                                            .then((state) {
                                              setState(
                                                () => _isSending = false,
                                              );
                                              if (state
                                                  is OrganisationsLoaded) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Milestone sent for review!',
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                );
                                                Navigator.of(context).pop();
                                              } else if (state
                                                  is OrganisationsError) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      state.message,
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            });
                                      }
                                      : null,
                              icon:
                                  _isSending
                                      ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : Icon(Icons.send_rounded),
                              label: Text('Send for review'),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                if (!_tasksLoading && !allTasksCompleted && _tasks.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'All tasks must be completed before sending the milestone for review.',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ],

            if (!isCompleted &&
                widget.milestone['pendingReview'] == true &&
                !widget.isTeacher) ...[
              SizedBox(height: 12),
              BlocProvider<OrganisationsBloc>(
                create: (context) => OrganisationsBloc(),
                child: Builder(
                  builder: (context) {
                    bool _isUnsend = false;
                    return StatefulBuilder(
                      builder: (context, setState) {
                        return SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed:
                                _isUnsend
                                    ? null
                                    : () async {
                                      setState(() => _isUnsend = true);
                                      final orgBloc =
                                          context.read<OrganisationsBloc>();
                                      orgBloc.add(
                                        UnsendMilestoneReviewRequestEvent(
                                          organisationId: widget.organisationId,
                                          projectId: widget.projectId,
                                          milestoneId: widget.milestone['id'],
                                        ),
                                      );
                                      orgBloc.stream
                                          .firstWhere(
                                            (state) =>
                                                state is OrganisationsLoaded ||
                                                state is OrganisationsError,
                                          )
                                          .then((state) {
                                            setState(() => _isUnsend = false);
                                            if (state is OrganisationsLoaded) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Milestone review request unsent.',
                                                  ),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                              Navigator.of(context).pop();
                                            } else if (state
                                                is OrganisationsError) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(state.message),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          });
                                    },
                            icon:
                                _isUnsend
                                    ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : Icon(Icons.undo),
                            label: Text('Unsend for review'),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],

            widget.isTeacher ? SizedBox(height: 12) : SizedBox.shrink(),

            // Only show delete button if milestone is not organization-wide (no sharedId) and user is teacher
            widget.isTeacher &&
                    (widget.milestone['sharedId'] == null || widget.allowEdit)
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
            SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _showCompletedTasks,
                  onChanged: (val) {
                    setState(() {
                      _showCompletedTasks = val ?? false;
                    });
                  },
                ),
                Text('Show completed tasks'),
              ],
            ),

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
            else ...[
              // Incomplete tasks first
              ListView.separated(
                itemBuilder: (context, index) {
                  final isTaskPendingReview =
                      incompleteTasks[index]['pendingReview'] == true;
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
                              isTaskPendingReview
                                  ? Colors.orange.shade100
                                  : Theme.of(
                                    context,
                                  ).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.task_rounded,
                          color:
                              isTaskPendingReview
                                  ? Colors.amber
                                  : Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                          size: 20,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              incompleteTasks[index]['name'] ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (isTaskPendingReview)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Pending review',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          incompleteTasks[index]['content'] ?? '',
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
                                          taskId: incompleteTasks[index]['id'],
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
                          sheetWidth:
                              MediaQuery.of(context).size.width / 3 - 40,
                          context: context,
                          body: Padding(
                            padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                            child: _buildTaskDetailSheet(
                              _tasks.indexOf(incompleteTasks[index]),
                              widget.projectTitle,
                              widget.milestone['name'] ?? '',
                              _tasks,
                            ),
                          ),
                          header: SizedBox(height: 20),
                          onCancel: () => Navigator.of(context).pop(),
                        );
                      },
                    ),
                  );
                },
                separatorBuilder: (context, index) => SizedBox(height: 8),
                itemCount: incompleteTasks.length,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
              ),
              if (_showCompletedTasks && completedTasks.isNotEmpty) ...[
                SizedBox(height: 16),
                Text(
                  'Completed tasks',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ListView.separated(
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        leading: Icon(Icons.check_circle, color: Colors.green),
                        title: Text(
                          completedTasks[index]['name'] ?? '',
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        subtitle: Text(
                          completedTasks[index]['content'] ?? '',
                          maxLines: 2,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Delete completed task',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: Text('Delete Task'),
                                    content: Text(
                                      'Are you sure you want to delete this completed task? This action cannot be undone.',
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
                                            () =>
                                                Navigator.of(context).pop(true),
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  ),
                            );
                            if (confirm == true) {
                              context.read<ProjectsBloc>().add(
                                DeleteTaskEvent(
                                  organisationId: widget.organisationId,
                                  projectId: widget.projectId,
                                  taskId: completedTasks[index]['id'],
                                ),
                              );
                            }
                          },
                        ),
                        onTap: () {
                          aweSideSheet(
                            footer: SizedBox(height: 10),
                            sheetPosition: SheetPosition.right,
                            sheetWidth:
                                MediaQuery.of(context).size.width / 3 - 40,
                            context: context,
                            body: Padding(
                              padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                              child: _buildTaskDetailSheet(
                                _tasks.indexOf(completedTasks[index]),
                                widget.projectTitle,
                                widget.milestone['name'] ?? '',
                                _tasks,
                              ),
                            ),
                            header: SizedBox(height: 20),
                            onCancel: () => Navigator.of(context).pop(),
                          );
                        },
                      ),
                    );
                  },
                  separatorBuilder: (context, index) => SizedBox(height: 8),
                  itemCount: completedTasks.length,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                ),
              ],
            ],

            // Action button for milestone review (student)
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

  Widget _buildTaskDetailSheet(
    int index,
    String projectName,
    String milestoneName, [
    List? tasksOverride,
  ]) {
    final tasks = tasksOverride ?? _tasks;
    final task = tasks[index];
    final dueDateRaw = task['deadline'];
    // Update controllers if switching tasks or if data changed
    if (editingTaskIndex != index ||
        taskNameController.text != (task['name'] ?? '') ||
        taskDescriptionController.text != (task['content'] ?? '')) {
      taskNameController.text = task['name'] ?? '';
      taskDescriptionController.text = task['content'] ?? '';
      if (dueDateRaw is DateTime) {
        taskDueDate = dueDateRaw;
      } else if (dueDateRaw is Timestamp) {
        taskDueDate = dueDateRaw.toDate();
      } else if (dueDateRaw is String) {
        taskDueDate = DateTime.tryParse(dueDateRaw);
      } else {
        taskDueDate = DateTime.now();
      }
      editingTaskIndex = index;
    }
    String formattedDueDate = 'Unknown';
    if (taskDueDate != null) {
      formattedDueDate =
          '${taskDueDate!.day.toString().padLeft(2, '0')}/${taskDueDate!.month.toString().padLeft(2, '0')}/${taskDueDate!.year.toString().substring(2)}';
    }
    bool isEditingTask = false;
    bool isSavingTask = false;
    final isTaskCompleted = task['isCompleted'] == true;
    final isTaskPendingReview = task['pendingReview'] == true;
    return BlocListener<ProjectsBloc, ProjectsState>(
      listener: (context, state) {
        if (state is ProjectsLoaded) {
          final updatedTasks =
              state.projects
                  .expand(
                    (p) =>
                        p.id == widget.projectId ? p.data['tasks'] ?? [] : [],
                  )
                  .toList();
          if (updatedTasks.isNotEmpty && index < updatedTasks.length) {
            final updatedTask = updatedTasks[index];
            if (taskNameController.text != (updatedTask['name'] ?? '')) {
              taskNameController.text = updatedTask['name'] ?? '';
            }
            if (taskDescriptionController.text !=
                (updatedTask['content'] ?? '')) {
              taskDescriptionController.text = updatedTask['content'] ?? '';
            }
          }
        }
      },
      child: Column(
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isEditingTask
                        ? SizedBox(
                          width: MediaQuery.of(context).size.width / 5,
                          child: TextField(
                            controller: taskNameController,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Task name',
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
                        : Text(
                          task['name'] ?? '',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                    SizedBox(height: 4),
                    Text("Task"),
                  ],
                ),
                Spacer(),
                if (!isEditingTask)
                  IconButton(
                    icon: Icon(Icons.edit, size: 20),
                    tooltip: 'Edit task',
                    onPressed: () {
                      setState(() {
                        isEditingTask = true;
                      });
                    },
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
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Due on: ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (isEditingTask)
                      TextButton(
                        onPressed: () async {
                          final DateTime initialDate =
                              taskDueDate ?? DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: initialDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              taskDueDate = picked;
                            });
                          }
                        },
                        child: Text(
                          '${taskDueDate!.day.toString().padLeft(2, '0')}/${taskDueDate!.month.toString().padLeft(2, '0')}/${taskDueDate!.year.toString().substring(2)}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )
                    else
                      Text(
                        formattedDueDate,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  'Project',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  projectName,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Milestone',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  milestoneName,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 6),
                isEditingTask
                    ? TextField(
                      controller: taskDescriptionController,
                      minLines: 3,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: 'Task description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )
                    : Text(
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
          if (isEditingTask)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed:
                        isSavingTask
                            ? null
                            : () async {
                              final name = taskNameController.text.trim();
                              final content =
                                  taskDescriptionController.text.trim();
                              if (name.isEmpty || content.isEmpty) {
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
                                isSavingTask = true;
                              });
                              final bloc = context.read<ProjectsBloc>();
                              StreamSubscription? subscription;
                              subscription = bloc.stream.listen((state) {
                                if (state is ProjectActionSuccess &&
                                    state.message ==
                                        'Task updated successfully') {
                                  subscription?.cancel();
                                  if (mounted) {
                                    setState(() {
                                      isEditingTask = false;
                                      isSavingTask = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Task updated successfully',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } else if (state is ProjectsError) {
                                  subscription?.cancel();
                                  if (mounted) {
                                    setState(() {
                                      isSavingTask = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
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
                                    UpdateTaskEvent(
                                      organisationId: widget.organisationId,
                                      projectId: widget.projectId,
                                      taskId: task['id'],
                                      name: name,
                                      content: content,
                                      deadline: taskDueDate ?? DateTime.now(),
                                    ),
                                  );
                                }
                              } catch (e) {
                                subscription.cancel();
                                if (mounted) {
                                  setState(() {
                                    isSavingTask = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                    icon:
                        isSavingTask
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : Icon(Icons.save, size: 20),
                    label: Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextButton(
                    onPressed:
                        isSavingTask
                            ? null
                            : () {
                              setState(() {
                                isEditingTask = false;
                              });
                            },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          if (!isTaskCompleted && !widget.isTeacher) ...[
            SizedBox(height: 12),
            BlocProvider<OrganisationsBloc>(
              create: (context) => OrganisationsBloc(),
              child: Builder(
                builder: (context) {
                  if (!isTaskPendingReview) {
                    bool _isSending = false;
                    return StatefulBuilder(
                      builder: (context, setState) {
                        return SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed:
                                _isSending
                                    ? null
                                    : () async {
                                      setState(() => _isSending = true);
                                      final orgBloc =
                                          context.read<OrganisationsBloc>();
                                      orgBloc.add(
                                        SubmitTaskReviewRequestEvent(
                                          organisationId: widget.organisationId,
                                          projectId: widget.projectId,
                                          milestoneId: widget.milestone['id'],
                                          milestoneName:
                                              widget.milestone['name'] ?? '',
                                          taskId: task['id'],
                                          taskName: task['name'] ?? '',
                                          projectName: widget.projectTitle,
                                          dueDate:
                                              (task['deadline'] is DateTime)
                                                  ? task['deadline']
                                                  : (task['deadline']
                                                          is Timestamp
                                                      ? task['deadline']
                                                          .toDate()
                                                      : DateTime.now()),
                                        ),
                                      );
                                      orgBloc.stream
                                          .firstWhere(
                                            (state) =>
                                                state is OrganisationsLoaded ||
                                                state is OrganisationsError,
                                          )
                                          .then((state) {
                                            setState(() => _isSending = false);
                                            if (state is OrganisationsLoaded) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Task sent for review!',
                                                  ),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                              Navigator.of(context).pop();
                                            } else if (state
                                                is OrganisationsError) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(state.message),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          });
                                    },
                            icon:
                                _isSending
                                    ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : Icon(Icons.send_rounded),
                            label: Text('Send for review'),
                          ),
                        );
                      },
                    );
                  } else {
                    bool _isUnsend = false;
                    return StatefulBuilder(
                      builder: (context, setState) {
                        return SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed:
                                _isUnsend
                                    ? null
                                    : () async {
                                      setState(() => _isUnsend = true);
                                      final orgBloc =
                                          context.read<OrganisationsBloc>();
                                      orgBloc.add(
                                        UnsendTaskReviewRequestEvent(
                                          organisationId: widget.organisationId,
                                          projectId: widget.projectId,
                                          taskId: task['id'],
                                        ),
                                      );
                                      orgBloc.stream
                                          .firstWhere(
                                            (state) =>
                                                state is OrganisationsLoaded ||
                                                state is OrganisationsError,
                                          )
                                          .then((state) {
                                            setState(() => _isUnsend = false);
                                            if (state is OrganisationsLoaded) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Task review request unsent.',
                                                  ),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                              Navigator.of(context).pop();
                                            } else if (state
                                                is OrganisationsError) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(state.message),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          });
                                    },
                            icon:
                                _isUnsend
                                    ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : Icon(Icons.undo),
                            label: Text('Unsend for review'),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
          if (widget.isTeacher) ...[
            SizedBox(height: 12),
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
                  final bloc = context.read<ProjectsBloc>();
                  bloc.add(
                    UpdateTaskEvent(
                      organisationId: widget.organisationId,
                      projectId: widget.projectId,
                      taskId: task['id'],
                      name: task['name'] ?? '',
                      content: task['content'] ?? '',
                      deadline:
                          task['deadline'] is DateTime
                              ? task['deadline']
                              : (task['deadline'] is Timestamp
                                  ? task['deadline'].toDate()
                                  : DateTime.now()),
                      isCompleted: !isTaskCompleted,
                    ),
                  );
                  Navigator.of(context).pop();
                },
                icon: Icon(
                  isTaskCompleted ? Icons.undo : Icons.check,
                  size: 20,
                ),
                label: Text(
                  isTaskCompleted ? "Mark as incomplete" : "Mark as completed",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            if (isTaskCompleted) ...[
              SizedBox(height: 12),
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
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text('Delete Task'),
                            content: Text(
                              'Are you sure you want to delete this completed task? This action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(false),
                                child: Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed:
                                    () => Navigator.of(context).pop(true),
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                    );
                    if (confirm == true) {
                      context.read<ProjectsBloc>().add(
                        DeleteTaskEvent(
                          organisationId: widget.organisationId,
                          projectId: widget.projectId,
                          taskId: task['id'],
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  icon: Icon(Icons.delete, size: 20),
                  label: Text(
                    "Delete completed task",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
