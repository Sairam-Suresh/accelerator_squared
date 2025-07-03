import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:accelerator_squared/blocs/projects/projects_bloc.dart';
import 'package:accelerator_squared/models/projects.dart';
import 'package:accelerator_squared/blocs/organisations/organisations_bloc.dart';
import 'package:uuid/uuid.dart';

class CreateMilestoneDialog extends StatefulWidget {
  final String organisationId;
  final List<Project> projects;
  final bool isOrgWide;

  const CreateMilestoneDialog({
    super.key,
    required this.organisationId,
    required this.projects,
    this.isOrgWide = false,
  });

  @override
  State<CreateMilestoneDialog> createState() => _CreateMilestoneDialogState();
}

class _CreateMilestoneDialogState extends State<CreateMilestoneDialog> {
  late Map<String, String> projectIdToName;
  late Map<String, bool> projectStates;
  bool allSelected = false;

  DateTime? selectedDate = DateTime.now();
  TextEditingController dateFieldController = TextEditingController();
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    projectIdToName = {for (var p in widget.projects) p.id: p.name};
    projectStates = {
      for (var p in widget.projects) p.id: widget.isOrgWide ? true : false,
    };
    if (widget.isOrgWide) {
      allSelected = true;
    }
  }

  void _updateProjectStates() {
    if (projectIdToName.isNotEmpty) {
      // Ensure all projects have a boolean state
      for (var projectId in projectIdToName.keys) {
        if (!projectStates.containsKey(projectId)) {
          projectStates[projectId] = false;
        }
      }
      // Remove any projects that no longer exist
      projectStates.removeWhere(
        (key, value) => !projectIdToName.containsKey(key),
      );
    }
  }

  void _createMilestone(BuildContext context) async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final dueDate = selectedDate;

    if (title.isEmpty || description.isEmpty || dueDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please fill all fields.')));
      return;
    }

    setState(() {
      isLoading = true;
    });
    final bloc = BlocProvider.of<ProjectsBloc>(context);
    bool errorOccurred = false;

    if (widget.isOrgWide) {
      // Org-wide: assign to all projects, generate sharedId
      final selectedProjects = projectIdToName.keys.toList();
      final sharedMilestoneId = const Uuid().v4();
      int completed = 0;
      int total = selectedProjects.length;
      void onDone() {
        completed++;
        if (completed == total) {
          setState(() {
            isLoading = false;
          });
          final bloc = BlocProvider.of<ProjectsBloc>(context);
          bloc.add(
            FetchProjectsEvent(
              widget.organisationId,
              projectId: widget.projects.first.id,
            ),
          );
          if (!errorOccurred) Navigator.of(context).pop();
        }
      }

      for (final projectId in selectedProjects) {
        bloc.add(
          AddMilestoneEvent(
            organisationId: widget.organisationId,
            projectId: projectId,
            name: title,
            description: description,
            dueDate: dueDate,
            sharedId: sharedMilestoneId,
          ),
        );
        bloc.stream
            .firstWhere(
              (state) =>
                  state is ProjectActionSuccess || state is ProjectsError,
            )
            .then((state) {
              if (state is ProjectsError) {
                errorOccurred = true;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              onDone();
            });
      }
    } else {
      // Project-level: assign to current project only, no sharedId
      final projectId = widget.projects.first.id;
      bloc.add(
        AddMilestoneEvent(
          organisationId: widget.organisationId,
          projectId: projectId,
          name: title,
          description: description,
          dueDate: dueDate,
          sharedId: null,
        ),
      );
      bloc.stream
          .firstWhere(
            (state) => state is ProjectActionSuccess || state is ProjectsError,
          )
          .then((state) {
            setState(() {
              isLoading = false;
            });
            if (state is ProjectsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            } else {
              final bloc = BlocProvider.of<ProjectsBloc>(context);
              bloc.add(
                FetchProjectsEvent(widget.organisationId, projectId: projectId),
              );
              Navigator.of(context).pop();
            }
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrganisationsBloc, OrganisationsState>(
      builder: (context, orgState) {
        if (orgState is OrganisationsLoaded) {
          // Get the current organisation and its projects
          final currentOrg = orgState.organisations.firstWhere(
            (org) => org.id == widget.organisationId,
            orElse: () => throw Exception('Organisation not found'),
          );

          // Update project list with all projects in the organisation
          projectIdToName = {for (var p in currentOrg.projects) p.id: p.name};
          // Update project states
          _updateProjectStates();
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Container(
            width: MediaQuery.of(context).size.width / 2,
            height: MediaQuery.of(context).size.height / 1.3,
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Header with icon
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.flag_rounded,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: 24),
                        // Title
                        Text(
                          "Create New Milestone",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 32),
                        // Milestone title input
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            hintText: "Enter milestone title",
                            label: Text("Milestone Title"),
                            prefixIcon: Icon(Icons.flag_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest.withAlpha(77),
                          ),
                        ),
                        SizedBox(height: 16),
                        // Milestone description input
                        TextField(
                          controller: descriptionController,
                          minLines: 3,
                          maxLines: 6,
                          decoration: InputDecoration(
                            hintText: "Enter milestone description",
                            label: Text("Milestone Description"),
                            prefixIcon: Icon(Icons.description_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest.withAlpha(77),
                          ),
                        ),
                        SizedBox(height: 16),
                        // Due date input
                        TextField(
                          onTap: () async {
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 365)),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                selectedDate = pickedDate;
                                dateFieldController.text =
                                    "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}";
                              });
                            }
                          },
                          controller: dateFieldController,
                          decoration: InputDecoration(
                            hintText: "dd/mm/yyyy",
                            label: Text("Due Date"),
                            prefixIcon: Icon(Icons.calendar_today_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest.withAlpha(77),
                          ),
                        ),
                        SizedBox(height: 16),
                        if (!widget.isOrgWide) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Creating milestone in: ${projectIdToName[widget.projects.first.id]}",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // (remove project selection UI here)
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed:
                            isLoading ? null : () => _createMilestone(context),
                        child:
                            isLoading
                                ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                                : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      "Create Milestone",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
