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
  var sampleProjectList = ['Project 1', 'Project 2', 'Project 3'];
  var sampleProjectDescriptions = [
    'This project is killing me',
    'Why did i decide to do this',
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
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

              return AlertDialog(
                content: SizedBox(
                  width: MediaQuery.of(context).size.width / 2,
                  height: MediaQuery.of(context).size.height / 1.5,
                  child: Column(
                    children: [
                      Text(
                        "Create new project",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                        ),
                      ),
                      Spacer(),
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
                        ],
                      ),
                      Spacer(),
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
                ),
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
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemBuilder: (context, index) {
                    return Card(
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: Container(
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
                              style: TextStyle(fontSize: 24),
                            ),
                            subtitle: Text(
                              sampleProjectDescriptions[index],
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  itemCount: sampleProjectList.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
