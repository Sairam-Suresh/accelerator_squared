import 'package:accelerator_squared/views/Project/project_card.dart';
import 'package:accelerator_squared/models/projects.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TeacherProjectPage extends StatefulWidget {
  const TeacherProjectPage({
    super.key,
    required this.orgName,
    required this.projects,
  });

  final String orgName;
  final List<Project> projects;

  @override
  State<TeacherProjectPage> createState() => _TeacherProjectPageState();
}

class _TeacherProjectPageState extends State<TeacherProjectPage> {
  @override
  Widget build(BuildContext context) {
    if (widget.projects.isEmpty) {
      return Center(
        child: Text(
          'No projects found',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(10),
      child: GridView.count(
        childAspectRatio: 1.5,
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        children: widget.projects.map((project) {
          return ProjectCardNew(project: project);
        }).toList(),
      ),
    );
  }
}
