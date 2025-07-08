import 'package:accelerator_squared/views/organisations/declineMilestoneDialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:accelerator_squared/blocs/organisations/organisations_bloc.dart';
import 'package:accelerator_squared/models/projects.dart';
import 'package:accelerator_squared/blocs/projects/projects_bloc.dart';

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
    return BlocListener<OrganisationsBloc, OrganisationsState>(
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
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    final pendingRequests = currentRequests;

    if (pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No pending project requests',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'All project requests have been reviewed',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

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
                Text(
                  'Pending Project Requests (${pendingRequests.length})',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Expanded(
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
                                              Theme.of(
                                                context,
                                              ).colorScheme.primaryContainer,
                                          side: BorderSide(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onPrimary,
                                          ),
                                          visualDensity: VisualDensity.compact,
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
                                                currentRequestId == request.id)
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
                                                currentRequestId == request.id)
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
                                                currentRequestId == request.id)
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
                                                currentRequestId == request.id)
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
                ),
                SizedBox(height: 16),
                Text(
                  'Pending Milestone Reviews (${milestoneReviewRequests.length})',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Expanded(
                  child:
                      milestoneReviewRequests.isEmpty
                          ? Center(child: Text('No milestone review requests'))
                          : ListView.builder(
                            itemCount: milestoneReviewRequests.length,
                            itemBuilder: (context, index) {
                              final req = milestoneReviewRequests[index];
                              return Card(
                                elevation: 2,
                                margin: EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                                        fontWeight:
                                                            FontWeight.bold,
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
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .onPrimary,
                                                            ),
                                                          ),
                                                          backgroundColor:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () async {
                                              // Decline: show dialog for feedback, then unsend
                                              String feedback = '';
                                              final result = await showDialog<
                                                String
                                              >(
                                                context: context,
                                                builder: (context) {
                                                  return DeclineMilestoneDialog(
                                                    feedback: feedback,
                                                  );
                                                },
                                              );
                                              if (result != null) {
                                                // Unsend milestone review
                                                context
                                                    .read<OrganisationsBloc>()
                                                    .add(
                                                      UnsendMilestoneReviewRequestEvent(
                                                        organisationId:
                                                            widget
                                                                .organisationId,
                                                        projectId:
                                                            req.projectId,
                                                        milestoneId:
                                                            req.milestoneId,
                                                      ),
                                                    );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Feedback sent: $result',
                                                    ),
                                                    backgroundColor:
                                                        Colors.orange,
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
                                                  context
                                                      .read<
                                                        OrganisationsBloc
                                                      >();
                                              bloc.add(
                                                UnsendMilestoneReviewRequestEvent(
                                                  organisationId:
                                                      widget.organisationId,
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
                                                    FetchOrganisationsEvent(),
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
                SizedBox(height: 16),
                Text(
                  'Pending Task Reviews (${pendingRequests.length})',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
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
    context.read<OrganisationsBloc>().add(
      ApproveProjectRequestEvent(
        organisationId: widget.organisationId,
        requestId: request.id,
      ),
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
                child: Text('Cancel'),
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
                          context.read<OrganisationsBloc>().add(
                            RejectProjectRequestEvent(
                              organisationId: widget.organisationId,
                              requestId: request.id,
                            ),
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
                        : Text('Reject'),
              ),
            ],
          ),
    );
  }
}
