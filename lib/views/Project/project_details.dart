import 'package:flutter/material.dart';
import 'package:side_sheet_material3/side_sheet_material3.dart';

class ProjectDetails extends StatefulWidget {
  const ProjectDetails({
    super.key,
    required this.projectName,
    required this.projectDescription,
  });

  final String projectName;
  final String projectDescription;

  @override
  State<ProjectDetails> createState() => _ProjectDetailsState();
}

class _ProjectDetailsState extends State<ProjectDetails> {
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
        title: Text('Project', style: TextStyle(fontWeight: FontWeight.bold)),
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
          padding: EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width / 2 - 30,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.projectName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 60,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 2,
                        child: Text(
                          widget.projectDescription,
                          style: TextStyle(fontSize: 17.5),
                        ),
                      ),
                      SizedBox(height: 25),
                      Divider(),
                      SizedBox(height: 10),
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
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            sampleMilestoneList[index],
                                            style: TextStyle(
                                              fontSize: 30,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                          Divider(),
                                          SizedBox(height: 10),
                                          Text(
                                            "Assigned by placeholder",
                                            style: TextStyle(fontSize: 18),
                                          ),
                                          Text(
                                            "Due on placeholder",
                                            style: TextStyle(fontSize: 18),
                                          ),
                                          Text(
                                            "Inside Project 1",
                                            style: TextStyle(fontSize: 18),
                                          ),
                                          SizedBox(height: 15),
                                          Text(
                                            sampleMilestoneDescriptions[index],
                                          ),
                                          SizedBox(height: 15),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Padding(
                                              padding: EdgeInsets.fromLTRB(
                                                10,
                                                20,
                                                10,
                                                20,
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.arrow_back),
                                                  SizedBox(width: 10),
                                                  Text("Send for review"),
                                                ],
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                          Divider(),
                                          SizedBox(height: 10),
                                          Text(
                                            "Tasks",
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                          Expanded(
                                            child: ListView.separated(
                                              itemBuilder: (context, index) {
                                                return Card(
                                                  child: ListTile(
                                                    onTap: () async {
                                                      Navigator.of(
                                                        context,
                                                      ).pop();

                                                      await showModalSideSheet(
                                                        context,
                                                        body: Padding(
                                                          padding:
                                                              EdgeInsets.fromLTRB(
                                                                20,
                                                                10,
                                                                20,
                                                                10,
                                                              ),
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .start,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                sampleTasksList[index],
                                                                style: TextStyle(
                                                                  fontSize: 30,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                height: 10,
                                                              ),
                                                              Text(
                                                                sampleMilestoneDescriptions[index],
                                                              ),
                                                              SizedBox(
                                                                height: 10,
                                                              ),
                                                              Divider(),
                                                              SizedBox(
                                                                height: 10,
                                                              ),
                                                              Text(
                                                                "Due on X April 2025",
                                                              ),
                                                              SizedBox(
                                                                height: 10,
                                                              ),
                                                              ElevatedButton(
                                                                onPressed: () {
                                                                  var navigator =
                                                                      Navigator.of(
                                                                        context,
                                                                      );
                                                                  navigator
                                                                      .pop();
                                                                },
                                                                child: Padding(
                                                                  padding:
                                                                      EdgeInsets.fromLTRB(
                                                                        20,
                                                                        10,
                                                                        20,
                                                                        10,
                                                                      ),
                                                                  child: Row(
                                                                    children: [
                                                                      Icon(
                                                                        Icons
                                                                            .check,
                                                                      ),
                                                                      SizedBox(
                                                                        width:
                                                                            10,
                                                                      ),
                                                                      Text(
                                                                        "Mark as completed",
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                height: 10,
                                                              ),
                                                              Divider(),
                                                              SizedBox(
                                                                height: 10,
                                                              ),
                                                              // Text(
                                                              //   "Comments",
                                                              //   style: TextStyle(
                                                              //     fontSize: 22,
                                                              //     fontWeight:
                                                              //         FontWeight
                                                              //             .bold,
                                                              //   ),
                                                              // ),
                                                            ],
                                                          ),
                                                        ),
                                                        header:
                                                            "Sample task view",
                                                      );
                                                    },
                                                    title: Text(
                                                      sampleTasksList[index],
                                                    ),
                                                    subtitle: Text(
                                                      sampleMilestoneDescriptions[index],
                                                      maxLines: 2,
                                                    ),
                                                  ),
                                                );
                                              },
                                              separatorBuilder: (
                                                context,
                                                index,
                                              ) {
                                                return SizedBox(height: 10);
                                              },
                                              itemCount: sampleTasksList.length,
                                            ),
                                          ),
                                        ],
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
                                  maxLines: 1,
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
                SizedBox(
                  width: MediaQuery.of(context).size.width / 2 - 30,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(40, 0, 0, 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 4,
                          child: ElevatedButton(
                            onPressed: () {},
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(10, 20, 10, 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.folder, size: 30),
                                  SizedBox(width: 20),
                                  Text(
                                    "View project files",
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 4,
                          child: ElevatedButton(
                            onPressed: () {},
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(10, 20, 10, 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add, size: 30),
                                  SizedBox(width: 20),
                                  Text(
                                    "Upload deliverables",
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 4,
                          child: ElevatedButton(
                            onPressed: () {
                              //_launchUrl();
                            },
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(10, 20, 10, 20),
                              child: Text(
                                "View project brief",
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Divider(),
                        SizedBox(height: 10),
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
                                        child: Column(
                                          children: [
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  sampleCommentsList[index],
                                                  style: TextStyle(
                                                    fontSize: 30,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(height: 10),
                                                Text(
                                                  sampleMilestoneDescriptions[0],
                                                ),
                                                SizedBox(height: 10),
                                                Divider(),
                                                SizedBox(height: 10),
                                                Text("Due on X April 2025"),
                                                SizedBox(height: 10),
                                                Text("Assigned by X"),
                                                SizedBox(height: 10),
                                                Text("Directed to X"),
                                                SizedBox(height: 10),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    var navigator =
                                                        Navigator.of(context);
                                                    navigator.pop();
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsets.fromLTRB(
                                                          20,
                                                          10,
                                                          20,
                                                          10,
                                                        ),
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.check),
                                                        SizedBox(width: 10),
                                                        Text(
                                                          "Mark as completed",
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: 10),
                                                Divider(),
                                                SizedBox(height: 10),
                                                // Text(
                                                //   "Comments",
                                                //   style: TextStyle(
                                                //     fontSize: 22,
                                                //     fontWeight:
                                                //         FontWeight
                                                //             .bold,
                                                //   ),
                                                // ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      header: "Comment",
                                    );
                                  },
                                  title: Text(sampleCommentsList[index]),
                                  subtitle: Text(
                                    sampleMilestoneDescriptions[0],
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
