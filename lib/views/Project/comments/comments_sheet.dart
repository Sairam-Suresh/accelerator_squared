import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:accelerator_squared/blocs/projects/projects_bloc.dart';

class CommentsSheet extends StatelessWidget {
  final String organisationId;
  final String projectId;
  final String commentId;
  const CommentsSheet({
    super.key,
    required this.organisationId,
    required this.projectId,
    required this.commentId,
  });

  Future<Map<String, dynamic>?> _fetchComment() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('organisations')
            .doc(organisationId)
            .collection('projects')
            .doc(projectId)
            .collection('comments')
            .doc(commentId)
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
                  (p) => p.id == projectId,
                  orElse:
                      () => ProjectWithDetails(
                        id: projectId,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment['title'] ?? '',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          comment['authorEmail'] ?? 'Unknown author',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
              Text(
                'Mentioned Files:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              mentionedFileNames.isEmpty
                  ? Text('None')
                  : Wrap(
                    spacing: 8,
                    children:
                        mentionedFileNames
                            .map((name) => Chip(label: Text(name)))
                            .toList(),
                  ),
              SizedBox(height: 24),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  comment['timestamp'] != null
                      ? (comment['timestamp'] as Timestamp).toDate().toString()
                      : '',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
