import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:accelerator_squared/blocs/organisations/organisations_bloc.dart';
import 'package:accelerator_squared/models/projects.dart';

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
  @override
  Widget build(BuildContext context) {
    final pendingRequests = widget.projectRequests;

    if (pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey,
            ),
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
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pending Project Requests (${pendingRequests.length})',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                _showRejectDialog(context, request);
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: Text('Reject'),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                _approveRequest(request);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: Text('Approve'),
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
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _approveRequest(ProjectRequest request) {
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
      builder: (context) => AlertDialog(
        title: Text('Reject Project Request'),
        content: Text('Are you sure you want to reject "${request.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
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
            child: Text('Reject'),
          ),
        ],
      ),
    );
  }
}
