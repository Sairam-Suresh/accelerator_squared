import 'package:accelerator_squared/views/Project/create_new_project.dart';
import 'package:accelerator_squared/views/Project/teacher_ui/project_requests.dart';
import 'package:accelerator_squared/views/organisations/org_members.dart';
import 'package:accelerator_squared/views/organisations/org_settings.dart';
import 'package:accelerator_squared/views/Project/project_card.dart';
import 'package:accelerator_squared/views/Project/teacher_ui/teacher_project_page.dart';
import 'package:accelerator_squared/views/organisations/org_stats.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:accelerator_squared/blocs/organisations/organisations_bloc.dart';

class ProjectPage extends StatefulWidget {
  const ProjectPage({
    super.key,
    required this.orgName,
    required this.orgDescription,
  });

  final String orgName;
  final String orgDescription;

  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  var sampleProjectList = [
    'Project 1',
    'Project 2',
    'Project 3',
    'Project 4',
    'Project 5',
    'Project 6',
    'Project 7',
    'Project 8',
    'Project 9',
    'Project 10',
  ];

  var sampleProjectDescriptions = [
    'This project is killing me',
    'Why did i decide to do this',
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam.',
    'Sigma sigma boy sigma boy sigma sigma boy',
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam.',
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam.',
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam.',
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam.',
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam.',
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam.',
  ];

  @override
  void initState() {
    super.initState();
    // Fetch organisations when the page initializes
    context.read<OrganisationsBloc>().add(FetchOrganisationsEvent());
  }

  bool teacherView = false;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: teacherView ? 4 : 2,
      child: Scaffold(
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
          title: Row(
            children: [
              Text(
                widget.orgName,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: EdgeInsets.only(left: 10),
                child: IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return OrgSettingsDialog(
                          orgDescription: widget.orgDescription,
                          orgName: widget.orgName,
                          isTeacher: teacherView,
                        );
                      },
                    );
                  },
                  icon: Icon(Icons.info_outline),
                ),
              ),
            ],
          ),
          actions: [
            Text("Teacher View"),
            Checkbox(
              value: teacherView,
              onChanged: (value) {
                setState(() {
                  teacherView = value!;
                });
              },
            ),
          ],
          bottom:
              teacherView
                  ? TabBar(
                    tabs: [
                      Tab(icon: Icon(Icons.list), text: "Projects"),
                      Tab(
                        icon: Icon(Icons.auto_graph_rounded),
                        text: "Statistics",
                      ),
                      Tab(
                        icon: Icon(Icons.check_box_outlined),
                        text: "Project requests",
                      ),
                      Tab(icon: Icon(Icons.groups), text: "Members"),
                    ],
                  )
                  : TabBar(
                    tabs: [
                      Tab(icon: Icon(Icons.list), text: "Projects"),
                      Tab(icon: Icon(Icons.groups), text: "Members"),
                    ],
                  ),
        ),
        body:
            !teacherView
                ? TabBarView(
                  children: [
                    SafeArea(
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: BlocBuilder<
                          OrganisationsBloc,
                          OrganisationsState
                        >(
                          builder: (context, state) {
                            if (state is OrganisationsLoading) {
                              return Center(child: CircularProgressIndicator());
                            } else if (state is OrganisationsLoaded) {
                              // Find the organisation matching the name
                              final organisation =
                                  state.organisations
                                      .where(
                                        (org) => org.name == widget.orgName,
                                      )
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
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      children:
                                          projects.map((project) {
                                            return ProjectCardNew(
                                              project: project,
                                            );
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
                    OrgMembers(teacherView: false),
                  ],
                )
                : TabBarView(
                  children: [
                    TeacherProjectPage(
                      orgName: widget.orgName,
                      sampleProjectDescriptions: sampleProjectDescriptions,
                      sampleProjectList: sampleProjectList,
                    ),
                    OrgStatistics(projectsList: sampleProjectList),
                    ProjectRequests(),
                    OrgMembers(teacherView: true),
                  ],
                ),
      ),
    );
  }
}
