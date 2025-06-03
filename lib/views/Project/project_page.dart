import 'package:accelerator_squared/views/Project/create_new_project.dart';
import 'package:accelerator_squared/views/organisations/org_settings.dart';
import 'package:accelerator_squared/views/Project/project_card.dart';
import 'package:accelerator_squared/views/Project/teacher_ui/teacher_project_page.dart';
import 'package:flutter/cupertino.dart';
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
    'I should stop procrastinating this project',
    'Very fun project trust',
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
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
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) {
                    return TeacherProjectPage(orgName: widget.orgName);
                  },
                ),
              );
            },
            icon: Icon(Icons.school),
          ),
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
