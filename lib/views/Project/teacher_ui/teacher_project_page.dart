import 'package:accelerator_squared/models/projects.dart';
import 'package:flutter/material.dart';
import 'package:accelerator_squared/views/Project/project_card.dart';
import 'package:accelerator_squared/views/Project/teacher_ui/teacher_project_details.dart';

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_off_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 16),
            Text(
              'No projects found',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Create your first project to get started',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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
          return ProjectCard(
            project: project,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TeacherProjectDetails(
                    projectName: project.name,
                    projectDescription: project.description,
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
