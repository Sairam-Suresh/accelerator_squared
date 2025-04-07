import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NewProjectDialog extends StatefulWidget {
  const NewProjectDialog({super.key});

  @override
  State<NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<NewProjectDialog> {
  TextEditingController projectNameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  bool? backupFileHistory = false;

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, StateSetter setState) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Create new project",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
              ),
              SizedBox(height: 20),
              Column(
                children: [
                  TextField(
                    controller: projectNameController,
                    decoration: InputDecoration(
                      label: Text("Project Name"),
                      hintText: "Enter project name",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: descriptionController,
                    minLines: 3,
                    maxLines: 20,
                    decoration: InputDecoration(
                      label: Text("Project description"),
                      hintText: "Enter project description",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                    ),
                    onPressed: () {
                      // open google account selector
                    },
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(0, 20, 0, 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset("../assets/drive.png", height: 30),
                          SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "dummyemail@gmail.com",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "Click to change account",
                                style: TextStyle(fontSize: 15),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
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
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // create project
                  Navigator.of(context).pop();
                },
                child: Padding(
                  padding: EdgeInsets.fromLTRB(5, 15, 5, 15),
                  child: Text(
                    "Create project",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
