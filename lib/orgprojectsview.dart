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
