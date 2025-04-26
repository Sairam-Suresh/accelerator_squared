import 'package:accelerator_squared/views/Project/comments_dialog.dart';
import 'package:accelerator_squared/views/Project/comments_sheet.dart';
import 'package:accelerator_squared/views/Project/milestone_sheet.dart';
import 'package:accelerator_squared/views/Project/project_files.dart';
import 'package:accelerator_squared/views/Project/project_settings.dart';
import 'package:accelerator_squared/views/Project/teacher_ui/create_milestone_dialog.dart';
import 'package:accelerator_squared/views/Project/teacher_ui/project_members.dart';
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
          SizedBox(width: 10),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return CommentsDialog(
                    commentsContents: sampleMilestoneDescriptions,
                    commentsList: sampleCommentsList,
                  );
                },
              );
            },
            icon: Icon(Icons.chat),
          ),
          SizedBox(width: 10),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, StateSetter setState) {
                      return ProjectMembersDialog();
                    },
                  );
                },
              );
            },
            icon: Icon(Icons.group),
          ),
          SizedBox(width: 10),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return ProjectSettings();
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return StatefulBuilder(
                builder: (context, StateSetter setState) {
                  return CreateMilestoneDialog();
                },
              );
            },
          );
        },
        label: Text("Create milestone"),
        icon: Icon(Icons.add),
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
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 2 - 50,
                      child: Column(
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
                          SizedBox(height: 15),
                          Text(
                            "Files",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width / 3,
                                child: ElevatedButton(
                                  onPressed: () {
                                    //_launchUrl();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      10,
                                      20,
                                      10,
                                      20,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Icon(Icons.article, size: 30),
                                        SizedBox(width: 20),
                                        Text(
                                          "Project brief",
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              IconButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return StatefulBuilder(
                                        builder: (
                                          context,
                                          StateSetter setState,
                                        ) {
                                          return ProjectFilesDialog();
                                        },
                                      );
                                    },
                                  );
                                },
                                icon: Icon(Icons.add),
                              ),
                            ],
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
