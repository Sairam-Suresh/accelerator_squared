import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:accelerator_squared/blocs/projects/projects_bloc.dart';

class ProjectSettings extends StatefulWidget {
  final String organisationId;
  final String projectId;
  final String projectName;
  final String projectDescription;
  final bool isTeacher;
  final VoidCallback? onProjectUpdated;

  const ProjectSettings({
    super.key,
    required this.organisationId,
    required this.projectId,
    required this.projectName,
    required this.projectDescription,
    required this.isTeacher,
    this.onProjectUpdated,
  });

  @override
  State<ProjectSettings> createState() => _ProjectSettingsState();
}

class _ProjectSettingsState extends State<ProjectSettings> {
  bool editingName = false;
  bool editingDescription = false;
  bool isSaving = false;
  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    nameController.text = widget.projectName;
    descriptionController.text = widget.projectDescription;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProjectsBloc, ProjectsState>(
      listener: (context, state) {
        if (state is ProjectActionSuccess && isSaving) {
          setState(() {
            isSaving = false;
            editingName = false;
            editingDescription = false;
          });
          Navigator.of(context).pop();
          if (widget.onProjectUpdated != null) {
            widget.onProjectUpdated!();
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Project "${nameController.text}" updated successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is ProjectsError && isSaving) {
          setState(() {
            isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.settings_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Project Info",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
              ),
            ),
            if (widget.isTeacher && (editingName || editingDescription))
              IconButton(
                onPressed:
                    isSaving
                        ? null
                        : () {
                          setState(() {
                            isSaving = true;
                          });
                          context.read<ProjectsBloc>().add(
                            UpdateProjectEvent(
                              organisationId: widget.organisationId,
                              projectId: widget.projectId,
                              title: nameController.text,
                              description: descriptionController.text,
                            ),
                          );
                        },
                icon:
                    isSaving
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        )
                        : Icon(
                          Icons.save,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                tooltip: "Save changes",
              ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width / 2.5,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project Name
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.label,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Project Name",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            Spacer(),
                            if (widget.isTeacher)
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    editingName = true;
                                  });
                                },
                                icon: Icon(Icons.edit, size: 20),
                                tooltip: "Edit name",
                              ),
                          ],
                        ),
                        SizedBox(height: 8),
                        editingName
                            ? Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: nameController,
                                    decoration: InputDecoration(
                                      hintText: "Enter project name",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      editingName = false;
                                      nameController.text = widget.projectName;
                                    });
                                  },
                                  icon: Icon(Icons.close, color: Colors.red),
                                  tooltip: "Cancel",
                                ),
                              ],
                            )
                            : Text(
                              widget.projectName,
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Description
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.description,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Description",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            Spacer(),
                            if (widget.isTeacher)
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    editingDescription = true;
                                  });
                                },
                                icon: Icon(Icons.edit, size: 20),
                                tooltip: "Edit description",
                              ),
                          ],
                        ),
                        SizedBox(height: 8),
                        editingDescription
                            ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: descriptionController,
                                        minLines: 3,
                                        maxLines: 5,
                                        decoration: InputDecoration(
                                          hintText: "Enter project description",
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          editingDescription = false;
                                          descriptionController.text =
                                              widget.projectDescription;
                                        });
                                      },
                                      icon: Icon(
                                        Icons.close,
                                        color: Colors.red,
                                      ),
                                      tooltip: "Cancel",
                                    ),
                                  ],
                                ),
                              ],
                            )
                            : Text(
                              widget.projectDescription.isEmpty
                                  ? "No description provided"
                                  : widget.projectDescription,
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    widget.projectDescription.isEmpty
                                        ? Theme.of(
                                          context,
                                        ).colorScheme.onSurface.withOpacity(0.6)
                                        : Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
