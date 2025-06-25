import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:accelerator_squared/blocs/projects/projects_bloc.dart';
import 'package:accelerator_squared/models/projects.dart';

class CreateMilestoneDialog extends StatefulWidget {
  final String organisationId;
  final List<Project> projects;
  const CreateMilestoneDialog({
    super.key,
    required this.organisationId,
    required this.projects,
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
    projectStates = {for (var p in widget.projects) p.id: false};
  }

  void _createMilestone(BuildContext context) async {
    final selectedProjects =
        projectStates.entries.where((e) => e.value).map((e) => e.key).toList();
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final dueDate = selectedDate;

    if (title.isEmpty ||
        description.isEmpty ||
        dueDate == null ||
        selectedProjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill all fields and select at least one project.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });
    final bloc = BlocProvider.of<ProjectsBloc>(context);
    int completed = 0;
    int total = selectedProjects.length;
    bool errorOccurred = false;

    void onDone() {
      completed++;
      if (completed == total) {
        setState(() {
          isLoading = false;
        });
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
        ),
      );
      bloc.stream
          .firstWhere(
            (state) => state is ProjectActionSuccess || state is ProjectsError,
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
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Container(
        width: MediaQuery.of(context).size.width / 2,
        height: MediaQuery.of(context).size.height / 1.3,
        padding: EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with icon
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
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
                maxLines: 4,
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
                    firstDate: DateTime.now().subtract(Duration(days: 30)),
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
              SizedBox(height: 24),

              // Projects section
              Row(
                children: [
                  Icon(
                    Icons.folder_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Assign to Projects",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Select all checkbox
              CheckboxListTile(
                title: Text(
                  "Select All",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                value: allSelected,
                onChanged: (value) {
                  setState(() {
                    allSelected = value!;
                    for (var project in projectStates.keys) {
                      projectStates[project] = value;
                    }
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              SizedBox(height: 12),

              // Projects list
              ListView.builder(
                itemBuilder: (context, index) {
                  final projectId = projectIdToName.keys.elementAt(index);
                  return Card(
                    elevation: 1,
                    margin: EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CheckboxListTile(
                      title: Text(
                        projectIdToName[projectId] ?? projectId,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      value: projectStates[projectId],
                      onChanged: (value) {
                        setState(() {
                          projectStates[projectId] = value!;
                          // Update select all state
                          allSelected = projectStates.values.every((v) => v);
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  );
                },
                itemCount: projectIdToName.length,
                shrinkWrap: true,
              ),
              SizedBox(height: 24),

              // Action buttons
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
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
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
      ),
    );
  }
}
