import 'package:accelerator_squared/views/Project/create_new_project.dart';
import 'package:accelerator_squared/views/Project/org_settings.dart';
import 'package:accelerator_squared/views/Project/project_card.dart';
import 'package:flutter/material.dart';

class ProjectPage extends StatefulWidget {
  const ProjectPage({super.key, required this.orgName});

  final String orgName;

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
              return NewProjectDialog();
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
                    return OrgSettingsDialog();
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
                    return ProjectCard(
                      sampleProjectDescriptions: sampleProjectDescriptions,
                      sampleProjectList: sampleProjectList,
                      index: index,
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
