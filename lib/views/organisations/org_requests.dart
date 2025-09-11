import 'package:accelerator_squared/blocs/organisation/organisation_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:accelerator_squared/blocs/organisations/organisations_bloc.dart';
import 'package:accelerator_squared/models/projects.dart';
import 'package:accelerator_squared/blocs/projects/projects_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProjectRequests extends StatefulWidget {
  const ProjectRequests({
    super.key,
    required this.organisationId,
    required this.projectRequests,
  });

  final String organisationId;
  final List<ProjectRequest> projectRequests;

  @override
  State<ProjectRequests> createState() => _RequestDialogState();
}

class _RequestDialogState extends State<ProjectRequests> {
  bool isApproving = false;
  bool isRejecting = false;
  String? currentRequestId;
  List<ProjectRequest> currentRequests = [];

  @override
  void initState() {
    super.initState();
    currentRequests = List.from(widget.projectRequests);
    // Ensure this page has fresh data when opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<OrganisationsBloc>().add(FetchOrganisationsEvent());
      }
    });
  }

  @override
  void didUpdateWidget(ProjectRequests oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectRequests != widget.projectRequests) {
      setState(() {
        currentRequests = List.from(widget.projectRequests);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<OrganisationsBloc, OrganisationsState>(
          listener: (context, state) {
            if (state is OrganisationsLoaded) {
              // Reset loading states when operation completes
              if (isApproving || isRejecting) {
                setState(() {
                  isApproving = false;
                  isRejecting = false;
                  currentRequestId = null;
                });
              }
            } else if (state is OrganisationsError) {
              // Reset loading states on error
              if (isApproving || isRejecting) {
                setState(() {
                  isApproving = false;
                  isRejecting = false;
                  currentRequestId = null;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
        // When single-organisation actions complete, refresh the organisations list
        BlocListener<OrganisationBloc, OrganisationState>(
          listener: (context, state) {
            if (state is OrganisationLoaded || state is OrganisationError) {
              context.read<OrganisationsBloc>().add(FetchOrganisationsEvent());
            }
          },
        ),
      ],
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    final pendingRequests = currentRequests;

    return Padding(
      padding: EdgeInsets.all(15),
      child: BlocBuilder<OrganisationsBloc, OrganisationsState>(
        builder: (context, state) {
          if (state is OrganisationsLoaded) {
            final org = state.organisations.firstWhere(
              (o) => o.id == widget.organisationId,
            );
            final milestoneReviewRequests = org.milestoneReviewRequests;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Manual refresh button
                Row(
                  children: [
                    Text(
                      'Pending Project Requests (${pendingRequests.length})',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      tooltip: 'Refresh',
                      icon: Icon(Icons.refresh),
                      onPressed: () {
                        context.read<OrganisationsBloc>().add(
                          FetchOrganisationsEvent(),
                        );
                      },
                    ),
                  ],
                ),

                SizedBox(height: 16),
                pendingRequests.isNotEmpty
                    ? Expanded(
                      child: ListView.builder(
                        itemBuilder: (context, index) {
                          final request = pendingRequests[index];
                          return Card(
                            elevation: 2,
                            margin: EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              request.title,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Requested by: ${request.requesterEmail}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Requested: ${_formatDate(request.requestedAt)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (request.description.isNotEmpty) ...[
                                    SizedBox(height: 12),
                                    Text(
                                      request.description,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                  if (request.memberEmails.isNotEmpty) ...[
                                    SizedBox(height: 12),
                                    Text(
                                      'Project Members:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children:
                                          request.memberEmails.map((email) {
                                            return Chip(
                                              label: Text(
                                                email,
                                                style: TextStyle(fontSize: 12),
                                              ),
                                              backgroundColor:
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .primaryContainer,
                                              side: BorderSide(
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.onPrimary,
                                              ),
                                              visualDensity:
                                                  VisualDensity.compact,
                                            );
                                          }).toList(),
                                    ),
                                  ],
                                  SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed:
                                            (isRejecting &&
                                                    currentRequestId ==
                                                        request.id)
                                                ? null
                                                : () {
                                                  _showRejectDialog(
                                                    context,
                                                    request,
                                                  );
                                                },
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        child:
                                            (isRejecting &&
                                                    currentRequestId ==
                                                        request.id)
                                                ? SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.red),
                                                  ),
                                                )
                                                : Text('Reject'),
                                      ),
                                      SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed:
                                            (isApproving &&
                                                    currentRequestId ==
                                                        request.id)
                                                ? null
                                                : () {
                                                  _approveRequest(request);
                                                },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                        child:
                                            (isApproving &&
                                                    currentRequestId ==
                                                        request.id)
                                                ? SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.white),
                                                  ),
                                                )
                                                : Text('Approve'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        itemCount: pendingRequests.length,
                        shrinkWrap: true,
                      ),
                    )
                    : Padding(
                      padding: EdgeInsets.all(10),
                      child: Center(child: Text('No project requests')),
                    ),
                SizedBox(height: 16),
                Text(
                  'Pending Milestone Reviews (${milestoneReviewRequests.length})',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                milestoneReviewRequests.isEmpty
                    ? Padding(
                      padding: EdgeInsets.all(10),
                      child: Center(
                        child: Text('No milestone review requests'),
                      ),
                    )
                    : Expanded(
                      child: ListView.builder(
                        itemCount: milestoneReviewRequests.length,
                        itemBuilder: (context, index) {
                          final req = milestoneReviewRequests[index];
                          return Card(
                            elevation: 2,
                            margin: EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  req.milestoneName,
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (req.isOrgWide)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          left: 8.0,
                                                        ),
                                                    child: Chip(
                                                      label: Text(
                                                        'Org-wide',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onPrimary,
                                                        ),
                                                      ),
                                                      backgroundColor:
                                                          Theme.of(
                                                            context,
                                                          ).colorScheme.primary,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Project: ${req.projectName}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Due: ${_formatDate(req.dueDate)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Sent for review: ${_formatDate(req.sentForReviewAt)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () async {
                                          // Decline: show create new comment dialog for feedback, then unsend
                                          final result =
                                              await _showCreateCommentDialog(
                                                context,
                                                req.projectId,
                                                req.milestoneId,
                                              );
                                          if (result == true) {
                                            // Unsend milestone review
                                            context.read<OrganisationBloc>().add(
                                              UnsendMilestoneReviewRequestEvent(
                                                projectId: req.projectId,
                                                milestoneId: req.milestoneId,
                                              ),
                                            );
                                            // Also refresh the projects data to update milestone status
                                            context.read<ProjectsBloc>().add(
                                              FetchProjectsEvent(
                                                widget.organisationId,
                                                projectId: req.projectId,
                                              ),
                                            );
                                            // Refresh orgs after a short delay to ensure updates propagate
                                            Future.delayed(
                                              Duration(milliseconds: 500),
                                              () {
                                                context
                                                    .read<OrganisationBloc>()
                                                    .add(
                                                      FetchOrganisationEvent(),
                                                    );
                                              },
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Milestone declined and comment created.',
                                                ),
                                                backgroundColor: Colors.orange,
                                              ),
                                            );
                                          }
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        child: Text('Decline'),
                                      ),
                                      SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () {
                                          // Accept: mark milestone as completed and unsend milestone review
                                          final bloc =
                                              context.read<OrganisationBloc>();
                                          bloc.add(
                                            UnsendMilestoneReviewRequestEvent(
                                              projectId: req.projectId,
                                              milestoneId: req.milestoneId,
                                            ),
                                          );
                                          // Also mark the milestone as completed
                                          context.read<ProjectsBloc>().add(
                                            CompleteMilestoneEvent(
                                              organisationId:
                                                  widget.organisationId,
                                              projectId: req.projectId,
                                              milestoneId: req.milestoneId,
                                              isCompleted: true,
                                            ),
                                          );
                                          // Refresh orgs after a short delay to ensure updates propagate
                                          Future.delayed(
                                            Duration(milliseconds: 500),
                                            () {
                                              bloc.add(
                                                FetchOrganisationEvent(),
                                              );
                                            },
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Milestone review accepted and milestone marked as completed.',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: Text('Accept'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
              ],
            );
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _approveRequest(ProjectRequest request) {
    setState(() {
      isApproving = true;
      currentRequestId = request.id;
    });
    context.read<OrganisationBloc>().add(
      ApproveProjectRequestEvent(requestId: request.id),
    );
  }

  void _showRejectDialog(BuildContext context, ProjectRequest request) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Reject Project Request'),
            content: Text(
              'Are you sure you want to reject "${request.title}"?',
            ),
            actions: [
              TextButton(
                onPressed:
                    (isRejecting && currentRequestId == request.id)
                        ? null
                        : () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed:
                    (isRejecting && currentRequestId == request.id)
                        ? null
                        : () {
                          setState(() {
                            isRejecting = true;
                            currentRequestId = request.id;
                          });
                          Navigator.of(context).pop();
                          context.read<OrganisationBloc>().add(
                            RejectProjectRequestEvent(requestId: request.id),
                          );
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child:
                    (isRejecting && currentRequestId == request.id)
                        ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : Text(
                          'Reject',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
              ),
            ],
          ),
    );
  }

  Future<bool?> _showCreateCommentDialog(
    BuildContext context,
    String projectId,
    String milestoneId,
  ) async {
    // Ensure we have the latest project data with files
    context.read<ProjectsBloc>().add(
      FetchProjectsEvent(widget.organisationId, projectId: projectId),
    );

    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    List<String> selectedFileIds = [];
    String? selectedMilestoneId = milestoneId; // Pre-select the milestone
    List<Map<String, dynamic>> milestones = [];

    return await showDialog<bool>(
      context: context,
      builder: (context) {
        bool isLoading = false;
        return BlocBuilder<ProjectsBloc, ProjectsState>(
          key: ValueKey('create_comment_dialog_$projectId'),
          builder: (context, state) {
            // Get the latest files and milestones from the BLoC state
            List<Map<String, dynamic>> files = [];
            if (state is ProjectsLoaded) {
              final project = state.projects.firstWhere(
                (p) => p.id == projectId,
                orElse: () => throw Exception('Project not found'),
              );

              // Get milestones for this project
              milestones = project.milestones;

              // Get files for this project
              files = project.files;
            } else if (state is ProjectsLoading) {
              return AlertDialog(
                title: Text('Create Comment'),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width / 2.5,
                  child: SizedBox(
                    height: 120,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading project data...'),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancel'),
                  ),
                ],
              );
            } else {
              // Fallback for other states
              return AlertDialog(
                title: Text('Create Comment'),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width / 2.5,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading...'),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancel'),
                  ),
                ],
              );
            }

            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: Text('Create Comment for Declined Milestone'),
                  content: SizedBox(
                    width: MediaQuery.of(context).size.width / 2.5,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: titleController,
                            decoration: InputDecoration(labelText: 'Title'),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: bodyController,
                            decoration: InputDecoration(labelText: 'Body'),
                            maxLines: 3,
                          ),
                          SizedBox(height: 8),
                          // Milestone assignment dropdown (pre-selected)
                          if (milestones.isNotEmpty) ...[
                            DropdownButtonFormField<String>(
                              value: selectedMilestoneId,
                              decoration: InputDecoration(
                                labelText: 'Assign to Milestone',
                                border: OutlineInputBorder(),
                              ),
                              hint: Text('Select a milestone'),
                              items: [
                                ...milestones.map((milestone) {
                                  return DropdownMenuItem<String>(
                                    value: milestone['id'],
                                    child: Text(
                                      milestone['name'] ?? 'Unnamed Milestone',
                                    ),
                                  );
                                }).toList(),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  selectedMilestoneId = value;
                                });
                              },
                            ),
                            SizedBox(height: 8),
                          ],
                          // File attachment section
                          if (files.isNotEmpty) ...[
                            Text(
                              'Attach Files:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              constraints: BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: files.length,
                                itemBuilder: (context, index) {
                                  final file = files[index];
                                  final isSelected = selectedFileIds.contains(
                                    file['id'],
                                  );
                                  return CheckboxListTile(
                                    title: Text(file['link'] ?? 'Unknown File'),
                                    value: isSelected,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          selectedFileIds.add(file['id']);
                                        } else {
                                          selectedFileIds.remove(file['id']);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 8),
                            // Show selected files
                            if (selectedFileIds.isNotEmpty) ...[
                              Text(
                                'Selected Files:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children:
                                    selectedFileIds.map((fileId) {
                                      final file = files.firstWhere(
                                        (f) => f['id'] == fileId,
                                        orElse: () => {'link': 'Unknown File'},
                                      );
                                      return Chip(
                                        label: Text(
                                          file['link'] ?? 'Unknown File',
                                        ),
                                        onDeleted: () {
                                          setState(() {
                                            selectedFileIds.remove(fileId);
                                          });
                                        },
                                      );
                                    }).toList(),
                              ),
                              SizedBox(height: 8),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : () async {
                                if (titleController.text.trim().isNotEmpty &&
                                    bodyController.text.trim().isNotEmpty) {
                                  setState(() => isLoading = true);
                                  final user =
                                      FirebaseAuth.instance.currentUser;

                                  // Create comment data
                                  Map<String, dynamic> commentData = {
                                    'title': titleController.text.trim(),
                                    'body': bodyController.text.trim(),
                                    'timestamp': FieldValue.serverTimestamp(),
                                    'mentionedFiles': selectedFileIds,
                                    'authorEmail': user?.email ?? 'Unknown',
                                  };

                                  // Add milestone assignment (should always be present)
                                  if (selectedMilestoneId != null) {
                                    commentData['assignedMilestoneId'] =
                                        selectedMilestoneId;
                                    // Get milestone name for display
                                    final milestone = milestones.firstWhere(
                                      (m) => m['id'] == selectedMilestoneId,
                                      orElse:
                                          () => {'name': 'Unknown Milestone'},
                                    );
                                    commentData['assignedMilestoneName'] =
                                        milestone['name'];
                                  }

                                  await FirebaseFirestore.instance
                                      .collection('organisations')
                                      .doc(widget.organisationId)
                                      .collection('projects')
                                      .doc(projectId)
                                      .collection('comments')
                                      .add(commentData);

                                  setState(() => isLoading = false);
                                  Navigator.pop(context, true);
                                }
                              },
                      child:
                          isLoading
                              ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : Text(
                                'Create Comment',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
