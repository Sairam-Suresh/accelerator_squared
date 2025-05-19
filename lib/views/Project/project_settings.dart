import 'package:flutter/material.dart';

class ProjectSettings extends StatefulWidget {
  const ProjectSettings({super.key});

  @override
  State<ProjectSettings> createState() => _ProjectSettingsState();
}

class _ProjectSettingsState extends State<ProjectSettings> {
  bool? backupFileHistory = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        "Project settings",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: "Edit project name",
              label: Text("Organisation name"),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            minLines: 3,
            maxLines: 1000,
            decoration: InputDecoration(
              hintText: "Edit project description",
              label: Text("Project description"),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          SizedBox(height: 10),
          Card(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Row(
                children: [
                  Text("Back up version history to Google Drive"),
                  SizedBox(width: 10),
                  Checkbox(
                    value: backupFileHistory,
                    onChanged: (value) {
                      setState(() {
                        backupFileHistory = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Padding(
              padding: EdgeInsets.fromLTRB(5, 15, 5, 15),
              child: Text(
                "Update settings",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
