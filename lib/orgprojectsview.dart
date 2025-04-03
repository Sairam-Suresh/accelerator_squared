import 'package:accelerator_squared/projectdetails.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProjectPage extends StatefulWidget {
  ProjectPage({super.key, required this.orgName});

  String orgName;

  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  var sampleProjectList = ['Project 1', 'Project 2', 'Project 3', 'Project 4'];
  var sampleProjectDescriptions = [
    'This project is killing me',
    'Why did i decide to do this',
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
    'Sigma sigma boy sigma boy sigma sigma boy',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              TextEditingController projectNameController =
                  TextEditingController();
              TextEditingController descriptionController =
                  TextEditingController();

              bool? backupFileHistory = false;

              return StatefulBuilder(
                builder: (context, StateSetter setState) {
                  return AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Create new project",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 30,
                          ),
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
                                    Image.asset(
                                      "../assets/drive.png",
                                      height: 30,
                                    ),
                                    SizedBox(width: 15),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
        child: Icon(Icons.add),
      ),
      appBar: AppBar(
        title: Text(
          widget.orgName,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 15),
            child: IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text(
                        "Organisation settings",
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
                              hintText: "Enter organisation name",
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
                              hintText: "Enter organisation description",
                              label: Text("Organisation description"),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text("Members"),
                          SizedBox(height: 10),
                          Text("placeholder"),
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
              icon: Icon(Icons.settings),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: GridView.count(
                  childAspectRatio: 1.5,
                  crossAxisCount: 3,
                  children: List.generate(sampleProjectList.length, (index) {
                    return Card(
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: ListTile(
                          onTap: () {
                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (context) {
                                  return ProjectDetails(
                                    projectName: sampleProjectList[index],
                                    projectDescription:
                                        sampleProjectDescriptions[index],
                                  );
                                },
                              ),
                            );
                          },
                          title: Text(
                            sampleProjectList[index],
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            sampleProjectDescriptions[index],
                            maxLines: 5,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
