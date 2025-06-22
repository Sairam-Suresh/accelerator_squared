import 'package:accelerator_squared/views/Project/create_new_project.dart';
import 'package:accelerator_squared/views/Project/teacher_ui/project_requests.dart';
import 'package:accelerator_squared/views/organisations/org_members.dart';
import 'package:accelerator_squared/views/organisations/org_settings.dart';
import 'package:accelerator_squared/views/Project/project_card.dart';
import 'package:accelerator_squared/views/Project/teacher_ui/teacher_project_page.dart';
import 'package:accelerator_squared/views/organisations/org_stats.dart';
import 'package:accelerator_squared/models/projects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:accelerator_squared/blocs/organisations/organisations_bloc.dart';

class ProjectPage extends StatefulWidget {
  const ProjectPage({
    super.key,
    required this.organisationId,
    required this.orgName,
    required this.orgDescription,
    required this.projects,
  });

  final String organisationId;
  final String orgName;
  final String orgDescription;
  final List<Project> projects;

  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  late List<Project> projects;

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
    projects = List.from(widget.projects);
    // Fetch organisations when the page initializes
    context.read<OrganisationsBloc>().add(FetchOrganisationsEvent());
  }

  bool teacherView = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrganisationsBloc, OrganisationsState>(
      listener: (context, state) {
        if (state is OrganisationsLoaded) {
          // Find the updated organization and refresh the projects
          final updatedOrg = state.organisations
              .where((org) => org.id == widget.organisationId)
              .firstOrNull;
          if (updatedOrg != null && mounted) {
            setState(() {
              projects = List.from(updatedOrg.projects);
            });
          }
        }
      },
      child: DefaultTabController(
        length: teacherView ? 4 : 2,
        child: Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return NewProjectDialog(organisationId: widget.organisationId);
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
              IconButton(
                onPressed: () {
                  context.read<OrganisationsBloc>().add(FetchOrganisationsEvent());
                },
                icon: Icon(Icons.refresh),
              ),
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
                            child: projects.isEmpty
                                ? Center(
                                    child: Text(
                                      'No projects found',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  )
                                : Column(
                                    children: [
                                      Expanded(
                                        child: GridView.count(
                                          childAspectRatio: 1.5,
                                          crossAxisCount: 3,
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 10,
                                          children: projects.map((project) {
                                            return ProjectCardNew(
                                              project: project,
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        OrgMembers(
                          teacherView: false,
                          organisationId: widget.organisationId,
                          organisationName: widget.orgName,
                        ),
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
                        OrgMembers(
                          teacherView: true,
                          organisationId: widget.organisationId,
                          organisationName: widget.orgName,
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
