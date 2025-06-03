import 'package:accelerator_squared/views/Project/create_new_project.dart';
import 'package:accelerator_squared/views/Project/org_settings.dart';
import 'package:accelerator_squared/views/Project/project_card.dart';
import 'package:accelerator_squared/views/Project/teacher_ui/teacher_project_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:accelerator_squared/blocs/organisations/organisations_bloc.dart';

class ProjectPage extends StatefulWidget {
  const ProjectPage({super.key, required this.orgName});

  final String orgName;

  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  @override
  void initState() {
    super.initState();
    // Fetch organisations when the page initializes
    context.read<OrganisationsBloc>().add(FetchOrganisationsEvent());
  }

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
          child: BlocBuilder<OrganisationsBloc, OrganisationsState>(
            builder: (context, state) {
              if (state is OrganisationsLoading) {
                return Center(child: CircularProgressIndicator());
              } else if (state is OrganisationsLoaded) {
                // Find the organisation matching the name
                final organisation =
                    state.organisations
                        .where((org) => org.name == widget.orgName)
                        .toList();

                // If no organisation found with the given name
                if (organisation.isEmpty) {
                  return Center(
                    child: Text(
                      'Organisation not found',
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                // Get the projects from the organisation
                final projects = organisation.first.projects;

                if (projects.isEmpty) {
                  return Center(
                    child: Text(
                      'No projects found',
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: GridView.count(
                        childAspectRatio: 1.5,
                        crossAxisCount: 3,
                        children:
                            projects.map((project) {
                              return ProjectCardNew(project: project);
                            }).toList(),
                      ),
                    ),
                  ],
                );
              } else if (state is OrganisationsError) {
                return Center(
                  child: Text(
                    'Error: ${state.message}',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }

              // Initial state or unknown state
              return Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }
}
