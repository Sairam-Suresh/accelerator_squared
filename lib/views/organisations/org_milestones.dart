import 'package:awesome_side_sheet/Enums/sheet_position.dart';
import 'package:awesome_side_sheet/side_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:accelerator_squared/blocs/organisations/organisations_bloc.dart';
import 'package:accelerator_squared/blocs/organisation/organisation_bloc.dart';
import 'package:accelerator_squared/views/Project/milestone_sheet.dart';
import 'package:accelerator_squared/blocs/projects/projects_bloc.dart';
import 'dart:async';
import 'package:accelerator_squared/views/Project/teacher_ui/create_milestone_dialog.dart';

class OrgMilestones extends StatefulWidget {
  final String organisationId;
  final bool isTeacher;
  const OrgMilestones({
    super.key,
    required this.organisationId,
    required this.isTeacher,
  });

  @override
  State<OrgMilestones> createState() => _OrgMilestonesState();
}

class _OrgMilestonesState extends State<OrgMilestones> {
  final Set<String> _deletingMilestoneIds = {};
  String? _pendingDeleteMilestoneId;

  @override
  void initState() {
    super.initState();
    // Fetch organisation projects and milestones on view initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectsBloc>().add(
        FetchProjectsEvent(widget.organisationId),
      );
      context.read<OrganisationsBloc>().add(FetchOrganisationsEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Organization wide milestones",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 14),
          widget.isTeacher
              ? SizedBox(
                height: 45,
                width: 250,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () async {
                    // Get org projects from OrganisationsBloc
                    final orgState = context.read<OrganisationsBloc>().state;
                    if (orgState is OrganisationsLoaded) {
                      final org = orgState.organisations.firstWhere(
                        (o) => o.id == widget.organisationId,
                        orElse: () => orgState.organisations.first,
                      );
                      if (org.id == widget.organisationId &&
                          org.projects.isNotEmpty) {
                        await showDialog(
                          context: context,
                          builder:
                              (context) => CreateMilestoneDialog(
                                isOrgWide: true,
                                organisationId: widget.organisationId,
                                projects: org.projects,
                              ),
                        );
                        // Refresh after dialog closes
                        context.read<ProjectsBloc>().add(
                          FetchProjectsEvent(widget.organisationId),
                        );
                        context.read<OrganisationsBloc>().add(
                          FetchOrganisationsEvent(),
                        );
                      }
                    }
                  },
                  icon: Icon(Icons.add, size: 20),
                  label: Text(
                    "Create milestone",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              )
              : SizedBox(),
          widget.isTeacher ? SizedBox(height: 15) : SizedBox(),

          // Milestone list
          Expanded(
            child: BlocBuilder<OrganisationsBloc, OrganisationsState>(
              builder: (context, orgState) {
                if (orgState is OrganisationsLoading) {
                  return Center(child: CircularProgressIndicator());
                }
                if (orgState is OrganisationsLoaded) {
                  final org = orgState.organisations.firstWhere(
                    (o) => o.id == widget.organisationId,
                    orElse: () => orgState.organisations.first,
                  );
                  final projectCount = org.projects.length;
                  if (projectCount == 0) {
                    return Center(
                      child: Text('No projects in this organisation.'),
                    );
                  }
                  // Now use ProjectsBloc for milestone data
                  return BlocBuilder<ProjectsBloc, ProjectsState>(
                    builder: (context, projectsState) {
                      if (projectsState is ProjectsLoading) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (projectsState is ProjectsLoaded) {
                        final projects = projectsState.projects;
                        // Collect all milestones from all projects
                        final allMilestones = <Map<String, dynamic>>[];
                        for (final project in projects) {
                          for (final m in project.milestones) {
                            allMilestones.add(m);
                          }
                        }
                        // Find sharedId values that appear in every project
                        final sharedIdCounts = <String, int>{};
                        for (final milestone in allMilestones) {
                          final sharedId = milestone['sharedId'];
                          if (sharedId != null) {
                            sharedIdCounts[sharedId] =
                                (sharedIdCounts[sharedId] ?? 0) + 1;
                          }
                        }
                        // Only sharedIds present in every project
                        final orgWideSharedIds =
                            sharedIdCounts.entries
                                .where((e) => e.value == projectCount)
                                .map((e) => e.key)
                                .toSet();
                        // Get one milestone per sharedId (they should be the same across projects)
                        final orgWideMilestones = <Map<String, dynamic>>[];
                        final seen = <String>{};
                        for (final milestone in allMilestones) {
                          final sharedId = milestone['sharedId'];
                          if (sharedId != null &&
                              orgWideSharedIds.contains(sharedId) &&
                              !seen.contains(sharedId)) {
                            orgWideMilestones.add(milestone);
                            seen.add(sharedId);
                          }
                        }
                        if (orgWideMilestones.isEmpty) {
                          return Center(
                            child: Text(
                              'No milestones found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        // Use the rest of the milestone list UI as before, but use projects[0].id for projectId
                        return ListView.separated(
                          separatorBuilder:
                              (context, index) => SizedBox(height: 10),
                          itemCount: orgWideMilestones.length,
                          itemBuilder: (context, index) {
                            final milestone = orgWideMilestones[index];
                            final milestoneId =
                                milestone['sharedId'] ?? milestone['id'];
                            return Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  // Open milestone sheet
                                  aweSideSheet(
                                    footer: SizedBox(height: 10),
                                    sheetWidth:
                                        MediaQuery.of(context).size.width / 3,
                                    context: context,
                                    sheetPosition: SheetPosition.right,
                                    body: BlocProvider<OrganisationBloc>(
                                      create:
                                          (context) => OrganisationBloc(
                                            organisationId:
                                                widget.organisationId,
                                          ),
                                      child: Padding(
                                        padding: EdgeInsets.fromLTRB(
                                          20,
                                          10,
                                          20,
                                          10,
                                        ),
                                        child: MilestoneSheet(
                                          isTeacher: widget.isTeacher,
                                          milestone: milestone,
                                          projectTitle: 'Organisation-wide',
                                          organisationId: widget.organisationId,
                                          projectId:
                                              projects[0]
                                                  .id, // Use any projectId
                                          allowEdit: true,
                                        ),
                                      ),
                                    ),
                                    header: SizedBox(height: 20),
                                    showHeaderDivider: false,
                                  );
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(10),
                                  child: ListTile(
                                    leading: Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(12),
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
                                    title: Text(
                                      milestone['name'] ?? '',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          milestone['description'] ?? '',
                                          maxLines: 3,
                                        ),
                                        if (milestone['dueDate'] != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2.0,
                                            ),
                                            child: Text(
                                              _formatDueDate(
                                                milestone['dueDate'],
                                              ),
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing:
                                        widget.isTeacher
                                            ? _deletingMilestoneIds.contains(
                                                  milestoneId,
                                                )
                                                ? SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.red,
                                                      ),
                                                )
                                                : IconButton(
                                                  icon: Icon(Icons.delete),
                                                  color: Colors.white,
                                                  style: ButtonStyle(
                                                    iconColor:
                                                        WidgetStateProperty.all<
                                                          Color
                                                        >(Colors.red),
                                                  ),
                                                  onPressed: () async {
                                                    final confirm = await showDialog<
                                                      bool
                                                    >(
                                                      context: context,
                                                      builder:
                                                          (
                                                            context,
                                                          ) => AlertDialog(
                                                            title: Text(
                                                              'Delete Milestone',
                                                            ),
                                                            content: Text(
                                                              'Are you sure you want to delete this milestone?',
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed:
                                                                    () => Navigator.of(
                                                                      context,
                                                                    ).pop(
                                                                      false,
                                                                    ),
                                                                child: Text(
                                                                  'Cancel',
                                                                ),
                                                              ),
                                                              ElevatedButton(
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .red,
                                                                  foregroundColor:
                                                                      Colors
                                                                          .white,
                                                                ),
                                                                onPressed:
                                                                    () => Navigator.of(
                                                                      context,
                                                                    ).pop(true),
                                                                child: Text(
                                                                  'Delete',
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                    );
                                                    if (confirm == true) {
                                                      setState(() {
                                                        _deletingMilestoneIds
                                                            .add(milestoneId);
                                                        _pendingDeleteMilestoneId =
                                                            milestoneId;
                                                      });
                                                      final bloc =
                                                          context
                                                              .read<
                                                                ProjectsBloc
                                                              >();
                                                      late final StreamSubscription
                                                      subscription;
                                                      subscription = bloc.stream.listen((
                                                        state,
                                                      ) {
                                                        if (state
                                                            is ProjectActionSuccess) {
                                                          bloc.add(
                                                            FetchProjectsEvent(
                                                              widget
                                                                  .organisationId,
                                                            ),
                                                          );
                                                          subscription.cancel();
                                                          if (mounted) {
                                                            setState(() {
                                                              _deletingMilestoneIds
                                                                  .remove(
                                                                    milestoneId,
                                                                  );
                                                              _pendingDeleteMilestoneId =
                                                                  null;
                                                            });
                                                          }
                                                        } else if (state
                                                            is ProjectsError) {
                                                          subscription.cancel();
                                                          if (mounted) {
                                                            setState(() {
                                                              _deletingMilestoneIds
                                                                  .remove(
                                                                    milestoneId,
                                                                  );
                                                              _pendingDeleteMilestoneId =
                                                                  null;
                                                            });
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  state.message,
                                                                ),
                                                                backgroundColor:
                                                                    Colors.red,
                                                              ),
                                                            );
                                                          }
                                                        }
                                                      });
                                                      bloc.add(
                                                        DeleteMilestoneEvent(
                                                          organisationId:
                                                              widget
                                                                  .organisationId,
                                                          projectId:
                                                              projects[0]
                                                                  .id, // Use any projectId
                                                          milestoneId:
                                                              milestoneId,
                                                        ),
                                                      );
                                                    }
                                                  },
                                                )
                                            : SizedBox(),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }
                      return SizedBox.shrink();
                    },
                  );
                }
                return SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDueDate(dynamic dueDateRaw) {
    if (dueDateRaw == null) return '';
    DateTime? dueDate;
    if (dueDateRaw is DateTime) {
      dueDate = dueDateRaw;
    } else if (dueDateRaw is String) {
      try {
        dueDate = DateTime.parse(dueDateRaw);
      } catch (_) {}
    } else if (dueDateRaw is Timestamp) {
      dueDate = dueDateRaw.toDate();
    }
    if (dueDate != null) {
      return '${dueDate.day.toString().padLeft(2, '0')}/${dueDate.month.toString().padLeft(2, '0')}/${dueDate.year.toString().substring(2)}';
    }
    return '';
  }
}
