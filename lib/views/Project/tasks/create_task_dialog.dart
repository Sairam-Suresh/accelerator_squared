import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:accelerator_squared/blocs/projects/projects_bloc.dart';

String formatDateDdMmYy(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString().substring(2);
  return '$day/$month/$year';
}

class CreateTaskDialog extends StatefulWidget {
  final String organisationId;
  final String projectId;
  final String milestoneId;
  const CreateTaskDialog({
    super.key,
    required this.organisationId,
    required this.projectId,
    required this.milestoneId,
  });

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  TextEditingController taskNameController = TextEditingController();
  TextEditingController taskDescriptionController = TextEditingController();
  DateTime dueDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Container(
        padding: EdgeInsets.all(24),
        width: MediaQuery.of(context).size.width / 2,
        height: MediaQuery.of(context).size.height / 1.3,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.checklist_rounded,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      "Create New Task",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 32),
                    TextField(
                      controller: taskNameController,
                      decoration: InputDecoration(
                        hintText: "Enter task name",
                        label: Text("Task Name"),
                        prefixIcon: Icon(Icons.checklist_rounded),
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
                    TextField(
                      minLines: 3,
                      maxLines: 6,
                      controller: taskDescriptionController,
                      decoration: InputDecoration(
                        hintText: "Enter task description",
                        label: Text("Task Description"),
                        prefixIcon: Icon(Icons.edit_document),
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
                    Row(
                      children: [
                        Text("Due date: "),
                        Text(
                          formatDateDdMmYy(dueDate),
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: () async {
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 30)),
                            );

                            setState(() {
                              dueDate = pickedDate!;
                            });
                          },
                          icon: Icon(Icons.calendar_month),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    // Align(
                    //   alignment: Alignment.centerLeft,
                    //   child: SizedBox(
                    //     height: 60,
                    //     child: ElevatedButton.icon(
                    //       style: ElevatedButton.styleFrom(
                    //         backgroundColor:
                    //             Theme.of(context).colorScheme.primary,
                    //         foregroundColor:
                    //             Theme.of(context).colorScheme.onPrimary,
                    //         shape: RoundedRectangleBorder(
                    //           borderRadius: BorderRadius.circular(12),
                    //         ),
                    //         elevation: 2,
                    //       ),
                    //       onPressed: () {
                    //         // Navigator.of(context).pop();
                    //       },
                    //       icon: Icon(Icons.add, size: 20),
                    //       label: Text(
                    //         "Add images",
                    //         style: TextStyle(
                    //           fontSize: 16,
                    //           fontWeight: FontWeight.w600,
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      final name = taskNameController.text.trim();
                      final content = taskDescriptionController.text.trim();
                      if (name.isEmpty || content.isEmpty) return;
                      context.read<ProjectsBloc>().add(
                        AddTaskEvent(
                          organisationId: widget.organisationId,
                          projectId: widget.projectId,
                          milestoneId: widget.milestoneId,
                          name: name,
                          content: content,
                          deadline: dueDate,
                          isCompleted: false,
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Create task",
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
  }
}
