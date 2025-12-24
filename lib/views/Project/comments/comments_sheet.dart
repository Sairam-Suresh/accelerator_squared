import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:accelerator_squared/blocs/projects/projects_bloc.dart';
import 'package:accelerator_squared/util/util.dart';
import 'package:intl/intl.dart';

class CommentsSheet extends StatefulWidget {
  final String organisationId;
  final String projectId;
  final String commentId;
  const CommentsSheet({
    super.key,
    required this.organisationId,
    required this.projectId,
    required this.commentId,
  });

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  String? _currentDisplayName;
  bool _isLoadingDisplayName = false;

  @override
  void initState() {
    super.initState();
    _fetchDisplayName();
  }

  Future<void> _fetchDisplayName() async {
    if (_isLoadingDisplayName) return;

    setState(() {
      _isLoadingDisplayName = true;
    });

    try {
      final comment = await _fetchComment();
      if (comment != null) {
        final authorEmail = comment['authorEmail'] as String?;
        if (authorEmail != null && authorEmail.isNotEmpty) {
          final displayName = await fetchUserDisplayNameByEmail(
            FirebaseFirestore.instance,
            authorEmail,
          );
          if (mounted) {
            setState(() {
              _currentDisplayName = displayName;
              _isLoadingDisplayName = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoadingDisplayName = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingDisplayName = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDisplayName = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchComment() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('organisations')
            .doc(widget.organisationId)
            .collection('projects')
            .doc(widget.projectId)
            .collection('comments')
            .doc(widget.commentId)
            .get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchComment(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final comment = snapshot.data!;
        final mentionedFiles = List<String>.from(
          comment['mentionedFiles'] ?? [],
        );

        final projectFiles =
            (() {
              final state = context.read<ProjectsBloc>().state;
              if (state is ProjectsLoaded) {
                final project = state.projects.firstWhere(
                  (p) => p.id == widget.projectId,
                  orElse:
                      () => ProjectWithDetails(
                        id: widget.projectId,
                        data: {},
                        milestones: [],
                        comments: [],
                        files: [],
                      ),
                );
                return project.files;
              }
              return [];
            })();

        final mentionedFileNames =
            projectFiles
                .where((file) => mentionedFiles.contains(file['id']))
                .map((file) => file['link'] ?? file['name'] ?? file['id'])
                .toList();

        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.comment,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment['title'] ?? '',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _currentDisplayName != null && _currentDisplayName!.isNotEmpty
                                    ? '$_currentDisplayName (${comment['authorEmail'] ?? 'Unknown'})'
                                    : comment['authorDisplayName'] != null && (comment['authorDisplayName'] as String).isNotEmpty
                                        ? '${comment['authorDisplayName']} (${comment['authorEmail'] ?? 'Unknown'})'
                                        : comment['authorEmail'] ?? 'Unknown author',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                comment['timestamp'] != null
                                    ? DateFormat('dd/MM/yy HH:mm').format(
                                      (comment['timestamp'] as Timestamp)
                                          .toDate(),
                                    )
                                    : '',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Container(
                constraints: BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Text(
                    comment['body'] ?? '',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              SizedBox(height: 24),
              // Show milestone assignment if present
              if (comment['assignedMilestoneId'] != null) ...[
                Text(
                  'Assigned to Milestone:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        comment['milestoneDeclined'] == true
                            ? Theme.of(context).colorScheme.errorContainer
                            : Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          comment['milestoneDeclined'] == true
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        comment['milestoneDeclined'] == true
                            ? Icons.flag_outlined
                            : Icons.flag,
                        color:
                            comment['milestoneDeclined'] == true
                                ? Theme.of(context).colorScheme.onErrorContainer
                                : Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comment['assignedMilestoneName'] ??
                                  'Unknown Milestone',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color:
                                    comment['milestoneDeclined'] == true
                                        ? Theme.of(
                                          context,
                                        ).colorScheme.onErrorContainer
                                        : null,
                              ),
                            ),
                            if (comment['milestoneDeclined'] == true) ...[
                              SizedBox(height: 4),
                              Text(
                                'This milestone was declined',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (comment['milestoneDeclined'] == true)
                        Icon(
                          Icons.cancel_outlined,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          size: 16,
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
              ],
              Text(
                'Mentioned Files:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              mentionedFileNames.isEmpty
                  ? SizedBox.shrink()
                  : SizedBox(height: 8),
              mentionedFileNames.isEmpty
                  ? Text('None')
                  : Wrap(
                    spacing: 8,
                    children:
                        mentionedFileNames
                            .map((name) => Chip(label: Text(name)))
                            .toList(),
                  ),
            ],
          ),
        );
      },
    );
  }
}
