import 'package:accelerator_squared/blocs/organisation/organisation_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:accelerator_squared/blocs/organisations/organisations_bloc.dart';
import 'package:accelerator_squared/models/projects.dart';
import 'package:accelerator_squared/blocs/projects/projects_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:accelerator_squared/util/snackbar_helper.dart';
import 'dart:async';

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
  bool isAcceptingMilestone = false;
  String? currentMilestoneKey; // format: projectId|milestoneId
  bool isRefreshing = false;
  List<dynamic> lastMilestoneReviewRequests = [];
  bool isDecliningMilestone = false;
  String? currentDeclineKey; // format: projectId|milestoneId

  // Real-time listeners
  StreamSubscription<QuerySnapshot>? _milestoneReviewRequestsSubscription;
  StreamSubscription<QuerySnapshot>? _projectRequestsSubscription;
  Map<String, StreamSubscription<DocumentSnapshot>> _milestoneSubscriptions =
      {};
  Map<String, String> _milestoneNamesCache = {}; // Cache for milestone names

  @override
  void initState() {
    super.initState();
    currentRequests = List.from(widget.projectRequests);
    // Start real-time listeners
    _startRealTimeListeners();
    // Ensure this page has fresh data when opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<OrganisationsBloc>().add(FetchOrganisationsEvent());
      }
    });
  }

  @override
  void dispose() {
    _milestoneReviewRequestsSubscription?.cancel();
    _projectRequestsSubscription?.cancel();
    // Cancel all milestone subscriptions
    for (final subscription in _milestoneSubscriptions.values) {
      subscription.cancel();
    }
    super.dispose();
  }

  void _startRealTimeListeners() {
    final firestore = FirebaseFirestore.instance;

    // Listen to milestone review requests changes
    _milestoneReviewRequestsSubscription = firestore
        .collection('organisations')
        .doc(widget.organisationId)
        .collection('milestoneReviewRequests')
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              lastMilestoneReviewRequests =
                  snapshot.docs.map((doc) {
                    final data = doc.data();
                    data['id'] = doc.id;
                    return data;
                  }).toList();
            });
            // Update milestone names cache for new/updated requests
            _updateMilestoneNamesCache();
          }
        });

    // Listen to project requests changes
    _projectRequestsSubscription = firestore
        .collection('organisations')
        .doc(widget.organisationId)
        .collection('projectRequests')
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              currentRequests =
                  snapshot.docs.map((doc) {
                    final data = doc.data();
                    data['id'] = doc.id;
                    return ProjectRequest.fromJson(data);
                  }).toList();
            });
          }
        });
  }

  Future<void> _updateMilestoneNamesCache() async {
    final firestore = FirebaseFirestore.instance;
    final updatedCache = <String, String>{};
    final newSubscriptions = <String, StreamSubscription<DocumentSnapshot>>{};

    for (final request in lastMilestoneReviewRequests) {
      // Ensure request is a Map before accessing its properties
      if (request is! Map<String, dynamic>) {
        print('Warning: Request is not a Map: $request');
        continue;
      }

      final projectId = request['projectId'] as String?;
      final milestoneId = request['milestoneId'] as String?;

      if (projectId != null && milestoneId != null) {
        final cacheKey = '$projectId|$milestoneId';

        // Only fetch if not already cached
        if (!_milestoneNamesCache.containsKey(cacheKey)) {
          try {
            final milestoneDoc =
                await firestore
                    .collection('organisations')
                    .doc(widget.organisationId)
                    .collection('projects')
                    .doc(projectId)
                    .collection('milestones')
                    .doc(milestoneId)
                    .get();

            if (milestoneDoc.exists) {
              final milestoneData = milestoneDoc.data();
              final milestoneName =
                  milestoneData?['name'] as String? ?? 'Unknown Milestone';
              updatedCache[cacheKey] = milestoneName;
            }
          } catch (e) {
            print('Error fetching milestone name: $e');
          }
        } else {
          updatedCache[cacheKey] = _milestoneNamesCache[cacheKey]!;
        }

        // Set up real-time listener for this milestone if not already listening
        if (!_milestoneSubscriptions.containsKey(cacheKey)) {
          final subscription = firestore
              .collection('organisations')
              .doc(widget.organisationId)
              .collection('projects')
              .doc(projectId)
              .collection('milestones')
              .doc(milestoneId)
              .snapshots()
              .listen((docSnapshot) {
                if (mounted && docSnapshot.exists) {
                  final milestoneData = docSnapshot.data();
                  final milestoneName =
                      milestoneData?['name'] as String? ?? 'Unknown Milestone';
                  setState(() {
                    _milestoneNamesCache[cacheKey] = milestoneName;
                  });
                }
              });
          newSubscriptions[cacheKey] = subscription;
        }
      }
    }

    if (mounted) {
      setState(() {
        _milestoneNamesCache.addAll(updatedCache);
        _milestoneSubscriptions.addAll(newSubscriptions);
      });
    }
  }

  String _getMilestoneName(String projectId, String milestoneId) {
    final cacheKey = '$projectId|$milestoneId';
    return _milestoneNamesCache[cacheKey] ?? 'Loading...';
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
              if (isApproving || isRejecting || isAcceptingMilestone) {
                setState(() {
                  isApproving = false;
                  isRejecting = false;
                  currentRequestId = null;
                  isAcceptingMilestone = false;
                  currentMilestoneKey = null;
                });
              }
              // Update last known milestone review requests and clear refresh spinner
              try {
                final org = state.organisations.firstWhere(
                  (o) => o.id == widget.organisationId,
                );
                setState(() {
                  lastMilestoneReviewRequests = org.milestoneReviewRequests;
                  isRefreshing = false;
                });
              } catch (_) {
                setState(() {
                  isRefreshing = false;
                });
              }
            } else if (state is OrganisationsError) {
              // Reset loading states on error
              if (isApproving ||
                  isRejecting ||
                  isAcceptingMilestone ||
                  isDecliningMilestone) {
                setState(() {
                  isApproving = false;
                  isRejecting = false;
                  currentRequestId = null;
                  isAcceptingMilestone = false;
                  currentMilestoneKey = null;
                  isDecliningMilestone = false;
                  currentDeclineKey = null;
                });
                SnackBarHelper.showError(context, message: state.message);
              }
              setState(() {
                isRefreshing = false;
              });
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
        // Do not reset milestone loading on Projects updates; wait for OrganisationsLoaded
        // so the item disappears at the same time the spinner stops.
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
          if (state is OrganisationsLoaded ||
              (state is OrganisationsLoading &&
                  lastMilestoneReviewRequests.isNotEmpty)) {
            // Prefer live data; if loading, fallback to the last snapshot to keep UI intact
            final org =
                state is OrganisationsLoaded
                    ? state.organisations.firstWhere(
                      (o) => o.id == widget.organisationId,
                    )
                    : null;
            final milestoneReviewRequests =
                org?.milestoneReviewRequests != null
                    ? org!.milestoneReviewRequests
                        .map((req) => req.toJson())
                        .toList()
                    : lastMilestoneReviewRequests;
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
                      icon:
                          isRefreshing
                              ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : Icon(Icons.refresh),
                      onPressed:
                          isRefreshing
                              ? null
                              : () {
                                setState(() => isRefreshing = true);
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

                          // Ensure req is a Map before accessing its properties
                          if (req is! Map<String, dynamic>) {
                            return Card(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('Invalid request data'),
                              ),
                            );
                          }

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
                                                  _getMilestoneName(
                                                    req['projectId'] as String,
                                                    req['milestoneId']
                                                        as String,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (req['isOrgWide'] as bool)
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
                                              'Project: ${req['projectName'] as String}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Due: ${_formatDate(req['dueDate'] is Timestamp ? (req['dueDate'] as Timestamp).toDate() : DateTime.parse(req['dueDate'] as String))}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Sent for review: ${_formatDate(req['sentForReviewAt'] is Timestamp ? (req['sentForReviewAt'] as Timestamp).toDate() : DateTime.parse(req['sentForReviewAt'] as String))}',
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
                                        onPressed:
                                            (isDecliningMilestone &&
                                                    currentDeclineKey ==
                                                        '${req['projectId'] as String}|${req['milestoneId'] as String}')
                                                ? null
                                                : () async {
                                                  // Decline: show create new comment dialog for feedback, then unsend
                                                  final result =
                                                      await _showCreateCommentDialog(
                                                        context,
                                                        req['projectId']
                                                            as String,
                                                        req['milestoneId']
                                                            as String,
                                                      );
                                                  if (result == true) {
                                                    setState(() {
                                                      isDecliningMilestone =
                                                          true;
                                                      currentDeclineKey =
                                                          '${req['projectId'] as String}|${req['milestoneId'] as String}';
                                                    });
                                                    // Unsend milestone review
                                                    context
                                                        .read<
                                                          OrganisationBloc
                                                        >()
                                                        .add(
                                                          UnsendMilestoneReviewRequestEvent(
                                                            projectId:
                                                                req['projectId']
                                                                    as String,
                                                            milestoneId:
                                                                req['milestoneId']
                                                                    as String,
                                                          ),
                                                        );
                                                    // Also refresh project details for milestone status
                                                    context
                                                        .read<ProjectsBloc>()
                                                        .add(
                                                          FetchProjectsEvent(
                                                            widget
                                                                .organisationId,
                                                            projectId:
                                                                req['projectId']
                                                                    as String,
                                                          ),
                                                        );
                                                    // Trigger organisations refresh to update requests list
                                                    context
                                                        .read<
                                                          OrganisationsBloc
                                                        >()
                                                        .add(
                                                          FetchOrganisationsEvent(),
                                                        );
                                                    SnackBarHelper.showWarning(
                                                      context,
                                                      message:
                                                          'Milestone declined and comment created.',
                                                    );
                                                  }
                                                },
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        child:
                                            (isDecliningMilestone &&
                                                    currentDeclineKey ==
                                                        '${req['projectId'] as String}|${req['milestoneId'] as String}')
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
                                                : Text('Decline'),
                                      ),
                                      SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed:
                                            (isAcceptingMilestone &&
                                                    currentMilestoneKey ==
                                                        '${req['projectId'] as String}|${req['milestoneId'] as String}')
                                                ? null
                                                : () {
                                                  _acceptMilestone(
                                                    req['projectId'] as String,
                                                    req['milestoneId']
                                                        as String,
                                                  );
                                                },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                        child:
                                            (isAcceptingMilestone &&
                                                    currentMilestoneKey ==
                                                        '${req['projectId'] as String}|${req['milestoneId'] as String}')
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
                                                : Text('Accept'),
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

  void _acceptMilestone(String projectId, String milestoneId) {
    setState(() {
      isAcceptingMilestone = true;
      currentMilestoneKey = '$projectId|$milestoneId';
    });
    final orgBloc = context.read<OrganisationBloc>();
    final projectsBloc = context.read<ProjectsBloc>();

    // Unsend review request and mark milestone complete
    orgBloc.add(
      UnsendMilestoneReviewRequestEvent(
        projectId: projectId,
        milestoneId: milestoneId,
      ),
    );
    projectsBloc.add(
      CompleteMilestoneEvent(
        organisationId: widget.organisationId,
        projectId: projectId,
        milestoneId: milestoneId,
        isCompleted: true,
      ),
    );

    // Fetch updated project to reflect milestone status promptly
    projectsBloc.add(
      FetchProjectsEvent(widget.organisationId, projectId: projectId),
    );

    // Also refresh organisations to update requests list
    context.read<OrganisationsBloc>().add(FetchOrganisationsEvent());

    SnackBarHelper.showSuccess(
      context,
      message: 'Milestone review accepted and milestone marked as completed.',
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
                          // Milestone assignment (non-changeable for declined milestones)
                          if (milestones.isNotEmpty) ...[
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.flag,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Assigned to Milestone:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onPrimary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          milestones.firstWhere(
                                                (m) =>
                                                    m['id'] ==
                                                    selectedMilestoneId,
                                                orElse:
                                                    () => {
                                                      'name':
                                                          'Unknown Milestone',
                                                    },
                                              )['name'] ??
                                              'Unknown Milestone',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.lock,
                                    color: Colors.grey.shade500,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8),
                          ],
                          // File attachment section (disabled for milestone decline)
                          if (files.isNotEmpty) ...[
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.attach_file,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onErrorContainer,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'File Attachments:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onErrorContainer,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          'Not available for milestone decline feedback',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onErrorContainer,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.lock,
                                    color: Colors.grey.shade500,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8),
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
                                    'mentionedFiles':
                                        [], // No file attachments for decline comments
                                    'authorEmail': user?.email ?? 'Unknown',
                                  };

                                  // Add milestone assignment (should always be present)
                                  commentData['assignedMilestoneId'] =
                                      selectedMilestoneId;
                                  // Get milestone name for display
                                  final milestone = milestones.firstWhere(
                                    (m) => m['id'] == selectedMilestoneId,
                                    orElse: () => {'name': 'Unknown Milestone'},
                                  );
                                  commentData['assignedMilestoneName'] =
                                      milestone['name'];
                                  // Add flag to indicate this comment is for a declined milestone
                                  commentData['milestoneDeclined'] = true;

                                  await FirebaseFirestore.instance
                                      .collection('organisations')
                                      .doc(widget.organisationId)
                                      .collection('projects')
                                      .doc(projectId)
                                      .collection('comments')
                                      .add(commentData);

                                  setState(() => isLoading = false);
                                  Navigator.pop(context, true);
                                } else {
                                  SnackBarHelper.showError(
                                    context,
                                    message:
                                        "Comment body text cannot be empty.",
                                  );
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
