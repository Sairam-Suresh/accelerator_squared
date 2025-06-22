import 'package:accelerator_squared/models/projects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:accelerator_squared/blocs/organisations/organisations_bloc.dart';
import 'package:accelerator_squared/views/Project/project_card.dart';
import 'package:accelerator_squared/views/Project/teacher_ui/teacher_project_details.dart';

class TeacherProjectPage extends StatefulWidget {
  const TeacherProjectPage({
    super.key,
    required this.orgName,
    required this.projects,
    required this.organisationId,
  });

  final String orgName;
  final List<Project> projects;
  final String organisationId;

  @override
  State<TeacherProjectPage> createState() => _TeacherProjectPageState();
}

class _TeacherProjectPageState extends State<TeacherProjectPage> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<OrganisationsBloc, OrganisationsState>(
      listener: (context, state) {
        if (state is OrganisationsLoaded) {
          // Refresh data when organisation data is updated
          // The parent widget will handle the refresh
        }
      },
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
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
            organisationId: widget.organisationId,
            isTeacher: true,
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
