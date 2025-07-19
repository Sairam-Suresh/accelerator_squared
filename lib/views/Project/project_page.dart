import 'package:accelerator_squared/blocs/organisation/organisation_bloc.dart';
import 'package:accelerator_squared/blocs/organisations/organisations_bloc.dart';
import 'package:accelerator_squared/blocs/projects/projects_bloc.dart';
import 'package:accelerator_squared/views/Project/create_new_project.dart';
import 'package:accelerator_squared/views/Project/project_card.dart';
import 'package:accelerator_squared/views/Project/project_details.dart';
import 'package:accelerator_squared/views/organisations/org_members.dart';
import 'package:accelerator_squared/views/organisations/org_milestones.dart';
import 'package:accelerator_squared/views/organisations/org_settings.dart';
import 'package:accelerator_squared/views/organisations/org_stats.dart';
import 'package:accelerator_squared/views/organisations/org_requests.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    OrganisationBloc organisationBloc = context.watch<OrganisationBloc>();
    OrganisationState organisationState = organisationBloc.state;
    late OrganisationLoaded organisationStateLoaded;

    if (organisationState is OrganisationLoaded) {
      organisationStateLoaded = organisationState;
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return BlocProvider.value(
                value: organisationBloc,
                child: NewProjectDialog(
                  organisationId: organisationStateLoaded.id,
                  isTeacher:
                      organisationStateLoaded.userRole == 'teacher' ||
                      organisationStateLoaded.userRole == 'student_teacher',
                ),
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
              organisationStateLoaded.name,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: EdgeInsets.only(left: 10),
              child: IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return BlocProvider.value(
                        value: context.watch<OrganisationBloc>(),
                        child: OrganisationSettingsDialog(
                          orgDescription: organisationStateLoaded.description,
                          orgName: organisationStateLoaded.name,
                          isTeacher:
                              organisationStateLoaded.userRole == 'teacher',
                          organisationId: organisationStateLoaded.id,
                          joinCode: organisationStateLoaded.joinCode,
                        ),
                      );
                    },
                  );
                },
                icon: Icon(Icons.info_outline),
              ),
            ),
            if (organisationStateLoaded.userRole == 'teacher')
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
            else if (organisationStateLoaded.userRole == 'student_teacher')
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
                onPressed:
                    isLoading
                        ? null
                        : () {
                          context.read<OrganisationBloc>().add(
                            FetchOrganisationEvent(),
                          );
                        },
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
          organisationStateLoaded.userRole == 'member'
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
                          icon: Icon(Icons.flag),
                          label: Text("Milestones"),
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
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child:
                                    organisationStateLoaded.projects.isEmpty
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
                                                    organisationStateLoaded.projects.map((
                                                      project,
                                                    ) {
                                                      return ProjectCard(
                                                        project: project,
                                                        organisationId:
                                                            organisationStateLoaded
                                                                .id,
                                                        isTeacher:
                                                            organisationStateLoaded
                                                                .userRole ==
                                                            'teacher',
                                                        onTap: () {
                                                          Navigator.of(context)
                                                              .push(
                                                                MaterialPageRoute(
                                                                  builder:
                                                                      (
                                                                        context,
                                                                      ) => BlocProvider(
                                                                        create:
                                                                            (
                                                                              _,
                                                                            ) =>
                                                                                ProjectsBloc(),
                                                                        child: ProjectDetails(
                                                                          organisationId:
                                                                              organisationStateLoaded.id,
                                                                          project:
                                                                              project,
                                                                          isTeacher:
                                                                              organisationStateLoaded.userRole !=
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
                                                                        organisationStateLoaded
                                                                            .id,
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
                            : _selectedIndex == 1
                            ? OrgMilestones(
                              isTeacher:
                                  organisationStateLoaded.userRole != 'member',
                              organisationId: organisationStateLoaded.id,
                            )
                            : OrgMembers(
                              teacherView: false,
                              organisationId: organisationStateLoaded.id,
                              organisationName: organisationStateLoaded.name,
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
                          label: Text("Requests"),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.flag),
                          label: Text("Milestones"),
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
                    child: Builder(
                      builder: (context) {
                        switch (_selectedIndex) {
                          case 0:
                            return Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child:
                                  organisationStateLoaded.projects.isEmpty
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
                                                  organisationStateLoaded.projects.map((
                                                    project,
                                                  ) {
                                                    return ProjectCard(
                                                      project: project,
                                                      organisationId:
                                                          organisationStateLoaded
                                                              .id,
                                                      isTeacher:
                                                          organisationStateLoaded
                                                              .userRole ==
                                                          'teacher',
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
                                                                            organisationStateLoaded.id,
                                                                        project:
                                                                            project,
                                                                        isTeacher:
                                                                            organisationStateLoaded.userRole !=
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
                                                                      organisationStateLoaded
                                                                          .id,
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
                            );
                          case 1:
                            // For member: Milestones, for teacher: Statistics
                            if (organisationStateLoaded.userRole == 'member') {
                              return OrgMilestones(
                                isTeacher: false,
                                organisationId: organisationStateLoaded.id,
                              );
                            } else {
                              return OrgStatistics(
                                projects: organisationStateLoaded.projects,
                              );
                            }
                          case 2:
                            // For member: Members, for teacher: Requests
                            if (organisationStateLoaded.userRole == 'member') {
                              return OrgMembers(
                                teacherView: false,
                                organisationId: organisationStateLoaded.id,
                                organisationName: organisationStateLoaded.name,
                              );
                            } else {
                              return ProjectRequests(
                                organisationId: organisationStateLoaded.id,
                                projectRequests:
                                    organisationStateLoaded.projectRequests,
                              );
                            }
                          case 3:
                            // Only for teacher: Milestones
                            return OrgMilestones(
                              isTeacher:
                                  organisationStateLoaded.userRole != 'member',
                              organisationId: organisationStateLoaded.id,
                            );
                          case 4:
                            // Only for teacher: Members
                            return OrgMembers(
                              teacherView: true,
                              organisationId: organisationStateLoaded.id,
                              organisationName: organisationStateLoaded.name,
                            );
                          default:
                            return SizedBox.shrink();
                        }
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}
