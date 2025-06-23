import 'package:accelerator_squared/blocs/organisations/organisations_bloc.dart';
import 'package:accelerator_squared/models/projects.dart';
import 'package:accelerator_squared/views/Project/create_new_project.dart';
import 'package:accelerator_squared/views/Project/project_card.dart';
import 'package:accelerator_squared/views/Project/project_details.dart';
import 'package:accelerator_squared/views/organisations/org_members.dart';
import 'package:accelerator_squared/views/organisations/org_settings.dart';
import 'package:accelerator_squared/views/organisations/org_stats.dart';
import 'package:accelerator_squared/views/Project/teacher_ui/project_requests.dart';
import 'package:accelerator_squared/views/Project/teacher_ui/teacher_project_page.dart';
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

class _ProjectPageState extends State<ProjectPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Project> projects = [];
  List<ProjectRequest> projectRequests = [];
  String userRole = 'member';
  String currentOrgName = '';
  String currentOrgDescription = '';
  String currentJoinCode = '';

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
    _tabController = TabController(
      length: (userRole == 'teacher' || userRole == 'student_teacher') ? 4 : 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshData() {
    context.read<OrganisationsBloc>().add(FetchOrganisationsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrganisationsBloc, OrganisationsState>(
      listener: (context, state) {
        if (state is OrganisationsLoaded) {
          final updatedOrg = state.organisations
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
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return NewProjectDialog(
                  organisationId: widget.organisationId,
                  isTeacher: userRole == 'teacher',
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Teacher',
                    style: TextStyle(
                      fontSize: 12,
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Student Teacher',
                    style: TextStyle(
                      fontSize: 12,
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Member',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _refreshData,
              icon: Icon(Icons.refresh),
              tooltip: 'Refresh data',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: (userRole == 'teacher' || userRole == 'student_teacher')
                ? [
                    Tab(icon: Icon(Icons.list), text: "Projects"),
                    Tab(
                      icon: Icon(Icons.auto_graph_rounded),
                      text: "Statistics",
                    ),
                    Tab(
                      icon: Icon(Icons.check_box_outlined),
                      text: "Project Requests",
                    ),
                    Tab(icon: Icon(Icons.groups), text: "Members"),
                  ]
                : [
                    Tab(icon: Icon(Icons.list), text: "Projects"),
                    Tab(icon: Icon(Icons.groups), text: "Members"),
                  ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: userRole == 'member'
              ? [
                  SafeArea(
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: projects.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
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
                                    children: projects.map((project) {
                                      return ProjectCard(
                                        project: project,
                                        organisationId: widget.organisationId,
                                        isTeacher: userRole == 'teacher',
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => ProjectDetails(
                                                projectName: project.name,
                                                projectDescription: project.description,
                                              ),
                                            ),
                                          );
                                        },
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
                ]
              : [
                  TeacherProjectPage(
                    orgName: widget.orgName,
                    projects: projects,
                    organisationId: widget.organisationId,
                  ),
                  OrgStatistics(projects: projects),
                  ProjectRequests(
                    organisationId: widget.organisationId,
                    projectRequests: projectRequests,
                  ),
                  OrgMembers(
                    teacherView: true,
                    organisationId: widget.organisationId,
                    organisationName: widget.orgName,
                  ),
                ],
        ),
      ),
    );
  }
}
