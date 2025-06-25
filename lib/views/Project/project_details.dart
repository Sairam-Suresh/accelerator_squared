import 'package:accelerator_squared/models/projects.dart';
import 'package:accelerator_squared/views/Project/comments/comments_dialog.dart';
import 'package:accelerator_squared/views/Project/milestone_sheet.dart';
import 'package:accelerator_squared/views/Project/project_files.dart';
import 'package:accelerator_squared/views/Project/project_settings.dart';
import 'package:accelerator_squared/views/Project/teacher_ui/create_milestone_dialog.dart';
import 'package:accelerator_squared/views/Project/teacher_ui/project_members.dart'
    show ProjectMembersDialog;
import 'package:awesome_side_sheet/Enums/sheet_position.dart';
import 'package:awesome_side_sheet/side_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:accelerator_squared/blocs/projects/projects_bloc.dart';
import 'package:accelerator_squared/blocs/organisations/organisations_bloc.dart';

class ProjectDetails extends StatefulWidget {
  final String organisationId;
  final Project project;
  final bool isTeacher;
  const ProjectDetails({
    super.key,
    required this.organisationId,
    required this.project,
    required this.isTeacher,
  });

  @override
  State<ProjectDetails> createState() => _ProjectDetailsState();
}

class _ProjectDetailsState extends State<ProjectDetails> {
  @override
  void initState() {
    super.initState();
    // Debug print to verify event call
    print(
      'Dispatching FetchProjectsEvent with orgId: \\${widget.organisationId}, projectId: \\${widget.project.id}',
    );
    context.read<ProjectsBloc>().add(
      FetchProjectsEvent(widget.organisationId, projectId: widget.project.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProjectsBloc, ProjectsState>(
      listener: (context, state) {
        if (state is ProjectActionSuccess) {
          // Refresh the project details after a successful update
          context.read<ProjectsBloc>().add(
            FetchProjectsEvent(
              widget.organisationId,
              projectId: widget.project.id,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<ProjectsBloc, ProjectsState>(
            key: ValueKey(widget.project.id),
            builder: (context, state) {
              String projectName = widget.project.name;
              if (state is ProjectsLoaded) {
                final project = state.projects.firstWhere(
                  (p) => p.id == widget.project.id,
                  orElse:
                      () => ProjectWithDetails(
                        id: widget.project.id,
                        data: {},
                        milestones: [],
                        comments: [],
                      ),
                );
                projectName = project.data['title'] ?? projectName;
              }
              return Text(
                projectName,
                style: TextStyle(fontWeight: FontWeight.bold),
              );
            },
          ),
          actions: [
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return CommentsDialog(
                      commentsContents: const [],
                      commentsList: const [],
                    );
                  },
                );
              },
              icon: Icon(Icons.chat),
            ),
            SizedBox(width: 10),
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, StateSetter setState) {
                        return ProjectMembersDialog();
                      },
                    );
                  },
                );
              },
              icon: Icon(Icons.group),
            ),
            SizedBox(width: 10),
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return BlocProvider.value(
                      value: context.read<ProjectsBloc>(),
                      child: StatefulBuilder(
                        builder: (context, setState) {
                          return ProjectSettings(
                            organisationId: widget.organisationId,
                            projectId: widget.project.id,
                            projectName: widget.project.name,
                            projectDescription: widget.project.description,
                            isTeacher: widget.isTeacher,
                            onProjectUpdated: () {
                              // Refresh both project and org data
                              context.read<ProjectsBloc>().add(
                                FetchProjectsEvent(
                                  widget.organisationId,
                                  projectId: widget.project.id,
                                ),
                              );
                              context.read<OrganisationsBloc>().add(
                                FetchOrganisationsEvent(),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                );
              },
              icon: Icon(Icons.settings),
            ),
            SizedBox(width: 20),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return BlocProvider.value(
                  value: context.read<ProjectsBloc>(),
                  child: StatefulBuilder(
                    builder: (context, StateSetter setState) {
                      return CreateMilestoneDialog(
                        organisationId: widget.organisationId,
                        projects: [widget.project],
                      );
                    },
                  ),
                );
              },
            );
          },
          label: Text("Create milestone"),
          icon: Icon(Icons.add),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(30, 10, 30, 10),
            child: BlocBuilder<ProjectsBloc, ProjectsState>(
              key: ValueKey(widget.project.id),
              builder: (context, state) {
                // Get the latest project data from the bloc, fallback to widget.project
                String projectName = widget.project.name;
                String projectDescription = widget.project.description;
                List<Map<String, dynamic>> milestones = [];
                if (state is ProjectsLoaded) {
                  final project = state.projects.firstWhere(
                    (p) => p.id == widget.project.id,
                    orElse:
                        () => ProjectWithDetails(
                          id: widget.project.id,
                          data: {},
                          milestones: [],
                          comments: [],
                        ),
                  );
                  projectName = project.data['title'] ?? projectName;
                  projectDescription =
                      project.data['description'] ?? projectDescription;
                  milestones = project.milestones;
                }
                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 2 - 50,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              BlocBuilder<ProjectsBloc, ProjectsState>(
                                key: ValueKey('header_${widget.project.id}'),
                                builder: (context, state) {
                                  String projectName = widget.project.name;
                                  if (state is ProjectsLoaded) {
                                    final project = state.projects.firstWhere(
                                      (p) => p.id == widget.project.id,
                                      orElse:
                                          () => ProjectWithDetails(
                                            id: widget.project.id,
                                            data: {},
                                            milestones: [],
                                            comments: [],
                                          ),
                                    );
                                    projectName =
                                        project.data['title'] ?? projectName;
                                  }
                                  return Text(
                                    projectName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 60,
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 10),
                              Container(
                                child: Text(
                                  projectDescription,
                                  style: TextStyle(fontSize: 17.5),
                                ),
                              ),
                              SizedBox(height: 15),
                              Text(
                                "Files",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 3,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        //_launchUrl();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.fromLTRB(
                                          10,
                                          20,
                                          10,
                                          20,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Icon(Icons.article, size: 30),
                                            SizedBox(width: 20),
                                            Text(
                                              "Project brief",
                                              style: TextStyle(fontSize: 18),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  IconButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return StatefulBuilder(
                                            builder: (
                                              context,
                                              StateSetter setState,
                                            ) {
                                              return ProjectFilesDialog(
                                                isTeacher: widget.isTeacher,
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                    icon: Icon(Icons.add),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 20),
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 2 - 50,
                          child: Column(
                            children: [
                              Text(
                                "Milestones",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                              SizedBox(height: 10),
                              if (state is ProjectsLoading)
                                Container(
                                  height:
                                      MediaQuery.of(context).size.height - 200,
                                  alignment: Alignment.center,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (state is ProjectsLoaded &&
                                  milestones.isEmpty)
                                Container(
                                  height:
                                      MediaQuery.of(context).size.height - 200,
                                  alignment: Alignment.center,
                                  child: Center(
                                    child: Text('No milestones found.'),
                                  ),
                                )
                              else if (state is ProjectsLoaded)
                                ListView.builder(
                                  itemBuilder: (context, index) {
                                    final milestone = milestones[index];
                                    return Card(
                                      child: Padding(
                                        padding: EdgeInsets.all(10),
                                        child: ListTile(
                                          leading: Container(
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color:
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .primaryContainer,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.flag,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                              size: 24,
                                            ),
                                          ),
                                          onTap: () {
                                            aweSideSheet(
                                              context: context,
                                              sheetPosition:
                                                  SheetPosition.right,
                                              body: Padding(
                                                padding: EdgeInsets.fromLTRB(
                                                  20,
                                                  10,
                                                  20,
                                                  10,
                                                ),
                                                child: MilestoneSheet(
                                                  milestone: milestone,
                                                  projectTitle: projectName,
                                                ),
                                              ),
                                              header: SizedBox(height: 20),
                                              showHeaderDivider: false,
                                            );
                                          },
                                          title: Text(
                                            milestone['name'] ?? '',
                                            style: TextStyle(fontSize: 20),
                                          ),
                                          subtitle: Text(
                                            milestone['description'] ?? '',
                                            maxLines: 3,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  itemCount: milestones.length,
                                  shrinkWrap: true,
                                )
                              else if (state is ProjectsError)
                                Text('Error: ${state.message}')
                              else
                                SizedBox.shrink(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
