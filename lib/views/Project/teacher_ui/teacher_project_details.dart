import 'package:accelerator_squared/views/Project/comments_sheet.dart';
import 'package:accelerator_squared/views/Project/milestone_sheet.dart';
import 'package:accelerator_squared/views/Project/teacher_ui/teacher_project_details.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:side_sheet_material3/side_sheet_material3.dart';

class TeacherProjectDetails extends StatefulWidget {
  const TeacherProjectDetails({
    super.key,
    required this.projectName,
    required this.projectDescription,
  });

  final String projectName;
  final String projectDescription;

  @override
  State<TeacherProjectDetails> createState() => _TeacherProjectDetailsState();
}

class _TeacherProjectDetailsState extends State<TeacherProjectDetails> {
  var sampleMilestoneList = ['Milestone 1', 'Milestone 2'];
  var sampleMilestoneDescriptions = [
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat',
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat',
  ];

  var sampleTasksList = ["Task 1", "Task 2"];
  var sampleCommentsList = ["Comment 1", "Comment 2", "Comment 3"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Project (teacher)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  bool? backupFileHistory = false;

                  return StatefulBuilder(
                    builder: (context, setState) {
                      return AlertDialog(
                        title: Text(
                          "Project settings",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 30,
                          ),
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
                                    Text(
                                      "Back up version history to Google Drive",
                                    ),
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
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
            icon: Icon(Icons.settings),
          ),
          SizedBox(width: 20),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(30, 10, 30, 10),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.projectName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 60,
                          ),
                        ),
                        SizedBox(height: 10),
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width / 1.5,
                          ),
                          child: Text(
                            widget.projectDescription,
                            style: TextStyle(fontSize: 17.5),
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    SizedBox(width: 20),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          // width: MediaQuery.of(context).size.width / 4,
                          child: ElevatedButton(
                            onPressed: () {},
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(10, 20, 10, 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(Icons.folder, size: 30),
                                  SizedBox(width: 20),
                                  Text(
                                    "View project files",
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          // width: MediaQuery.of(context).size.width / 4,
                          child: ElevatedButton(
                            onPressed: () {},
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(10, 20, 10, 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(Icons.add, size: 30),
                                  SizedBox(width: 20),
                                  Text(
                                    "Upload deliverables",
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          // width: MediaQuery.of(context).size.width / 4,
                          child: ElevatedButton(
                            onPressed: () {
                              //_launchUrl();
                            },
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(10, 20, 10, 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(Icons.article, size: 30),
                                  SizedBox(width: 20),
                                  Text(
                                    "View project brief",
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 15),
                Divider(),
                SizedBox(height: 15),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 2 - 50,
                      child: Column(
                        children: [
                          Text(
                            "Milestones",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          SizedBox(height: 10),
                          ListView.builder(
                            itemBuilder: (context, index) {
                              return Card(
                                child: Padding(
                                  padding: EdgeInsets.all(10),
                                  child: ListTile(
                                    onTap: () async {
                                      await showModalSideSheet(
                                        context,
                                        body: Padding(
                                          padding: EdgeInsets.fromLTRB(
                                            20,
                                            10,
                                            20,
                                            10,
                                          ),
                                          child: MilestoneSheet(
                                            sampleMilestoneDescriptions:
                                                sampleMilestoneDescriptions,
                                            sampleMilestoneList:
                                                sampleMilestoneList,
                                            sampleTasksList: sampleTasksList,
                                            index: index,
                                          ),
                                        ),
                                        header: "Milestone",
                                      );
                                    },
                                    title: Text(
                                      sampleMilestoneList[index],
                                      style: TextStyle(fontSize: 20),
                                    ),
                                    subtitle: Text(
                                      sampleMilestoneDescriptions[index],
                                      maxLines: 3,
                                    ),
                                  ),
                                ),
                              );
                            },
                            itemCount: sampleMilestoneList.length,
                            shrinkWrap: true,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 20),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 2 - 50,
                      child: Column(
                        children: [
                          Text(
                            "Comments",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          SizedBox(height: 10),
                          ListView.builder(
                            itemBuilder: (context, index) {
                              return Card(
                                child: Padding(
                                  padding: EdgeInsets.all(10),
                                  child: ListTile(
                                    onTap: () async {
                                      showModalSideSheet(
                                        context,
                                        body: Padding(
                                          padding: EdgeInsets.fromLTRB(
                                            20,
                                            10,
                                            20,
                                            10,
                                          ),
                                          child: CommentsSheet(
                                            sampleCommentsList:
                                                sampleCommentsList,
                                            sampleMilestoneDescriptions:
                                                sampleMilestoneDescriptions,
                                            index: index,
                                          ),
                                        ),
                                        header: "Comment",
                                      );
                                    },
                                    title: Text(
                                      sampleCommentsList[index],
                                      style: TextStyle(fontSize: 20),
                                    ),
                                    subtitle: Text(
                                      sampleMilestoneDescriptions[0],
                                      maxLines: 3,
                                    ),
                                  ),
                                ),
                              );
                            },
                            itemCount: sampleCommentsList.length,
                            shrinkWrap: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
