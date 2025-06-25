import 'package:accelerator_squared/blocs/organisations/organisations_bloc.dart';
import 'package:accelerator_squared/blocs/projects/projects_bloc.dart';
import 'package:accelerator_squared/models/projects.dart';
import 'package:accelerator_squared/views/Project/create_new_project.dart';
import 'package:accelerator_squared/views/Project/project_card.dart';
import 'package:accelerator_squared/views/Project/project_details.dart';
import 'package:accelerator_squared/views/organisations/org_members.dart';
import 'package:accelerator_squared/views/organisations/org_settings.dart';
import 'package:accelerator_squared/views/organisations/org_stats.dart';
import 'package:accelerator_squared/views/Project/teacher_ui/project_requests.dart';
import 'package:accelerator_squared/views/Project/teacher_ui/create_milestone_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProjectPage extends StatefulWidget {
  const ProjectPage({
    super.key,
    required this.organisationId,
    required this.orgName,
    required this.orgDescription,
    required this.projects,
    required this.projectRequests,
    required this.userRole,
    required this.joinCode,
  });

  final String organisationId;
  final String orgName;
  final String orgDescription;
  final List<Project> projects;
  final List<ProjectRequest> projectRequests;
  final String userRole;
  final String joinCode;

  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage>
    with TickerProviderStateMixin {
  List<Project> projects = [];
  List<ProjectRequest> projectRequests = [];
  String userRole = 'member';
  String currentOrgName = '';
  String currentOrgDescription = '';
  String currentJoinCode = '';

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    projects = List.from(widget.projects);
    projectRequests = List.from(widget.projectRequests);
    userRole = widget.userRole;
    currentOrgName = widget.orgName;
    currentOrgDescription = widget.orgDescription;
    currentJoinCode = widget.joinCode;

    // Initialize TabController with correct length based on user role
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _refreshData() {
    context.read<OrganisationsBloc>().add(FetchOrganisationsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<OrganisationsBloc, OrganisationsState>(
          listener: (context, state) {
            if (state is OrganisationsLoaded) {
              final updatedOrg =
                  state.organisations
                      .where((org) => org.id == widget.organisationId)
                      .firstOrNull;
              if (updatedOrg != null && mounted) {
                setState(() {
                  projects = List.from(updatedOrg.projects);
                  projectRequests = List.from(updatedOrg.projectRequests);
                  userRole = updatedOrg.userRole;
                  currentOrgName = updatedOrg.name;
                  currentOrgDescription = updatedOrg.description;
                  currentJoinCode = updatedOrg.joinCode;
                });
              }
            }
          },
        ),
        BlocListener<ProjectsBloc, ProjectsState>(
          listener: (context, state) {
            if (state is ProjectActionSuccess) {
              // Refresh the project list after a project is updated
              context.read<ProjectsBloc>().add(
                FetchProjectsEvent(widget.organisationId),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return NewProjectDialog(
                  organisationId: widget.organisationId,
                  isTeacher:
                      userRole == 'teacher' || userRole == 'student_teacher',
                );
              },
            );
          },
          child: Icon(Icons.add),
        ),
        appBar: AppBar(
          title: Row(
            children: [
              Text(
                currentOrgName,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: EdgeInsets.only(left: 10),
                child: IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return OrganisationSettingsDialog(
                          orgDescription: currentOrgDescription,
                          orgName: currentOrgName,
                          isTeacher: userRole == 'teacher',
                          organisationId: widget.organisationId,
                          joinCode: currentJoinCode,
                        );
                      },
                    );
                  },
                  icon: Icon(Icons.info_outline),
                ),
              ),
              if (userRole == 'teacher')
                Container(
                  margin: EdgeInsets.only(left: 10),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Teacher',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                )
              else if (userRole == 'student_teacher')
                Container(
                  margin: EdgeInsets.only(left: 10),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Student Teacher',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                )
              else
                Container(
                  margin: EdgeInsets.only(left: 10),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Member',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            BlocBuilder<OrganisationsBloc, OrganisationsState>(
              builder: (context, state) {
                final isLoading = state is OrganisationsLoading;
                return IconButton(
                  onPressed: isLoading ? null : _refreshData,
                  icon:
                      isLoading
                          ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          )
                          : Icon(Icons.refresh),
                  tooltip: 'Refresh data',
                );
              },
            ),
            SizedBox(width: 10),
          ],
        ),
        body:
            userRole == 'member'
                ? Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border(
                          right: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                      ),
                      child: NavigationRail(
                        backgroundColor: Colors.transparent,
                        onDestinationSelected: (value) {
                          setState(() {
                            _selectedIndex = value;
                          });
                        },
                        labelType: NavigationRailLabelType.all,
                        destinations: [
                          NavigationRailDestination(
                            icon: Icon(Icons.list),
                            label: Text("Projects"),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.groups),
                            label: Text("Members"),
                          ),
                        ],

                        selectedIndex: _selectedIndex,
                      ),
                    ),
                    Expanded(
                      child:
                          _selectedIndex == 0
                              ? SafeArea(
                                child: Padding(
                                  padding: EdgeInsets.all(10),
                                  child:
                                      projects.isEmpty
                                          ? Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.folder_off,
                                                  size: 64,
                                                  color: Colors.grey,
                                                ),
                                                SizedBox(height: 16),
                                                Text(
                                                  'No projects found',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.grey,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'There are no projects in this organisation yet.',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
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
                                                  children:
                                                      projects.map((project) {
                                                        return ProjectCard(
                                                          project: project,
                                                          organisationId:
                                                              widget
                                                                  .organisationId,
                                                          isTeacher:
                                                              userRole ==
                                                              'teacher',
                                                          onTap: () {
                                                            Navigator.of(
                                                                  context,
                                                                )
                                                                .push(
                                                                  MaterialPageRoute(
                                                                    builder:
                                                                        (
                                                                          context,
                                                                        ) => BlocProvider(
                                                                          create:
                                                                              (_) =>
                                                                                  ProjectsBloc(),
                                                                          child: ProjectDetails(
                                                                            organisationId:
                                                                                widget.organisationId,
                                                                            project:
                                                                                project,
                                                                            isTeacher:
                                                                                widget.userRole !=
                                                                                "member",
                                                                            key: ValueKey(
                                                                              project.id,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                  ),
                                                                )
                                                                .then((_) {
                                                                  context
                                                                      .read<
                                                                        ProjectsBloc
                                                                      >()
                                                                      .add(
                                                                        FetchProjectsEvent(
                                                                          widget
                                                                              .organisationId,
                                                                        ),
                                                                      );
                                                                  context
                                                                      .read<
                                                                        OrganisationsBloc
                                                                      >()
                                                                      .add(
                                                                        FetchOrganisationsEvent(),
                                                                      );
                                                                });
                                                          },
                                                        );
                                                      }).toList(),
                                                ),
                                              ),
                                            ],
                                          ),
                                ),
                              )
                              : OrgMembers(
                                teacherView: false,
                                organisationId: widget.organisationId,
                                organisationName: widget.orgName,
                              ),
                    ),
                  ],
                )
                : Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border(
                          right: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                      ),
                      child: NavigationRail(
                        backgroundColor: Colors.transparent,
                        onDestinationSelected: (value) {
                          setState(() {
                            _selectedIndex = value;
                          });
                        },
                        labelType: NavigationRailLabelType.all,
                        destinations: [
                          NavigationRailDestination(
                            icon: Icon(Icons.list),
                            label: Text("Projects"),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.auto_graph_rounded),
                            label: Text("Statistics"),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.check_box_outlined),
                            label: Text("Project Requests"),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.groups),
                            label: Text("Members"),
                          ),
                        ],
                        selectedIndex: _selectedIndex,
                      ),
                    ),
                    Expanded(
                      child:
                          _selectedIndex == 0
                              ? projects.isEmpty
                                  ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.folder_off,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'No projects found',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'There are no projects in this organisation yet.',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
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
                                          children:
                                              projects.map((project) {
                                                return ProjectCard(
                                                  project: project,
                                                  organisationId:
                                                      widget.organisationId,
                                                  isTeacher:
                                                      userRole == 'teacher',
                                                  onTap: () {
                                                    Navigator.of(context)
                                                        .push(
                                                          MaterialPageRoute(
                                                            builder:
                                                                (
                                                                  context,
                                                                ) => BlocProvider(
                                                                  create:
                                                                      (_) =>
                                                                          ProjectsBloc(),
                                                                  child: ProjectDetails(
                                                                    organisationId:
                                                                        widget
                                                                            .organisationId,
                                                                    project:
                                                                        project,
                                                                    isTeacher:
                                                                        widget
                                                                            .userRole !=
                                                                        "member",
                                                                    key: ValueKey(
                                                                      project
                                                                          .id,
                                                                    ),
                                                                  ),
                                                                ),
                                                          ),
                                                        )
                                                        .then((_) {
                                                          context
                                                              .read<
                                                                ProjectsBloc
                                                              >()
                                                              .add(
                                                                FetchProjectsEvent(
                                                                  widget
                                                                      .organisationId,
                                                                ),
                                                              );
                                                          context
                                                              .read<
                                                                OrganisationsBloc
                                                              >()
                                                              .add(
                                                                FetchOrganisationsEvent(),
                                                              );
                                                        });
                                                  },
                                                );
                                              }).toList(),
                                        ),
                                      ),
                                    ],
                                  )
                              : _selectedIndex == 1
                              ? OrgStatistics(projects: projects)
                              : _selectedIndex == 2
                              ? ProjectRequests(
                                organisationId: widget.organisationId,
                                projectRequests: projectRequests,
                              )
                              : OrgMembers(
                                teacherView: true,
                                organisationId: widget.organisationId,
                                organisationName: widget.orgName,
                              ),
                    ),
                  ],
                ),
      ),
    );
  }
}
