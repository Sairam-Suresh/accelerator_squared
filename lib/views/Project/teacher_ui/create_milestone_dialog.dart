import 'package:flutter/material.dart';

class CreateMilestoneDialog extends StatefulWidget {
  const CreateMilestoneDialog({super.key});

  @override
  State<CreateMilestoneDialog> createState() => _CreateMilestoneDialogState();
}

class _CreateMilestoneDialogState extends State<CreateMilestoneDialog> {
  var projectsList = ["Project 1", "Project 2"];
  var projectStates = {};
  var allSelected = false;

  DateTime? selectedDate = DateTime.now();
  TextEditingController dateFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (var x in projectsList) {
      projectStates[x] = false;
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
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
              ),
              SizedBox(height: 16),

              // Milestone description input
              TextField(
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
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
              ),
              SizedBox(height: 16),

              // Due date input
              TextField(
                controller: dateFieldController,
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now().subtract(Duration(days: 30)),
                    lastDate: DateTime.now().add(Duration(days: 30)),
                  );

                  setState(() {
                    selectedDate = pickedDate;
                    dateFieldController.text =
                        "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}";
                  });
                },
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
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                  return Card(
                    elevation: 1,
                    margin: EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CheckboxListTile(
                      title: Text(
                        projectsList[index],
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      value: projectStates[projectsList[index]],
                      onChanged: (value) {
                        setState(() {
                          projectStates[projectsList[index]] = value;

                          // Update select all state
                          bool allChecked = true;
                          for (var state in projectStates.values) {
                            if (!state) {
                              allChecked = false;
                              break;
                            }
                          }
                          allSelected = allChecked;
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
                itemCount: projectsList.length,
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
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Row(
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
