import 'package:accelerator_squared/views/Project/comments/comments_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:awesome_side_sheet/Enums/sheet_position.dart';
import 'package:awesome_side_sheet/side_sheet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:accelerator_squared/blocs/projects/projects_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentsDialog extends StatefulWidget {
  final String projectId;
  final String organisationId;
  const CommentsDialog({
    super.key,
    required this.projectId,
    required this.organisationId,
  });

  @override
  State<CommentsDialog> createState() => _CommentsDialogState();
}

class _CommentsDialogState extends State<CommentsDialog> {
  Future<void> _showAddCommentDialog() async {
    // Ensure we have the latest project data with files
    context.read<ProjectsBloc>().add(
      FetchProjectsEvent(widget.organisationId, projectId: widget.projectId),
    );

    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    List<String> selectedFileIds = [];

    await showDialog<bool>(
      context: context,
      builder: (context) {
        bool isLoading = false;
        return BlocBuilder<ProjectsBloc, ProjectsState>(
          key: ValueKey('comments_dialog_${widget.projectId}'),
          builder: (context, state) {
            // --- Always get the latest files from the BLoC state ---
            List<Map<String, dynamic>> files = [];
            if (state is ProjectsLoading) {
              return AlertDialog(
                title: Text('New Comment'),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width / 2.5,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading project files...'),
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
            } else if (state is ProjectsLoaded) {
              print(
                '[CommentsDialog] Projects loaded: ${state.projects.length}',
              );
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
              print(
                '[CommentsDialog] Project files count: ${project.files.length}',
              );
              if (project.files.isNotEmpty) {
                print(
                  '[CommentsDialog] First file data: ${project.files.first}',
                );
              }
              // Defensive: ensure files is a List<Map>
              files =
                  project.files
                      .where((file) => file['id'] != null)
                      .map<Map<String, dynamic>>(
                        (file) => {
                          'id': file['id'],
                          'name': file['link'] ?? file['id'] ?? 'Unknown file',
                          'link': file['link'] ?? '',
                        },
                      )
                      .toList();
              print('[CommentsDialog] Filtered files count: ${files.length}');
              if (files.isNotEmpty) {
                print('[CommentsDialog] First filtered file: ${files.first}');
              }
            } else if (state is ProjectsError) {
              return AlertDialog(
                title: Text('New Comment'),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width / 2.5,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 48),
                        SizedBox(height: 16),
                        Text('Error loading project files'),
                        SizedBox(height: 8),
                        Text(
                          state.message,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<ProjectsBloc>().add(
                        FetchProjectsEvent(
                          widget.organisationId,
                          projectId: widget.projectId,
                        ),
                      );
                    },
                    child: Text('Retry'),
                  ),
                ],
              );
            } else {
              // Fallback for other states
              return AlertDialog(
                title: Text('New Comment'),
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
            // --------------------------------------------------------

            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: Text('New Comment'),
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
                          Row(
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Mention files:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.refresh),
                                onPressed: () {
                                  context.read<ProjectsBloc>().add(
                                    FetchProjectsEvent(
                                      widget.organisationId,
                                      projectId: widget.projectId,
                                    ),
                                  );
                                },
                                tooltip: 'Refresh files',
                              ),
                            ],
                          ),
                          files.isEmpty
                              ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'No files available to mention.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Add files to the project first.',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : Wrap(
                                spacing: 8,
                                children:
                                    files.map((file) {
                                      final isSelected = selectedFileIds
                                          .contains(file['id']);
                                      return FilterChip(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 15,
                                        ),
                                        label: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.file_copy),
                                            SizedBox(width: 8),
                                            Text(file['name']),
                                          ],
                                        ),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          setState(() {
                                            if (selected) {
                                              selectedFileIds.add(file['id']);
                                            } else {
                                              selectedFileIds.remove(
                                                file['id'],
                                              );
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                              ),
                          if (selectedFileIds.isNotEmpty) ...[
                            SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Selected files:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              children:
                                  files
                                      .where(
                                        (file) => selectedFileIds.contains(
                                          file['id'],
                                        ),
                                      )
                                      .map(
                                        (file) => Chip(
                                          label: Text(file['name']),
                                          onDeleted: () {
                                            setState(() {
                                              selectedFileIds.remove(
                                                file['id'],
                                              );
                                            });
                                          },
                                        ),
                                      )
                                      .toList(),
                            ),
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
                                  await FirebaseFirestore.instance
                                      .collection('organisations')
                                      .doc(widget.organisationId)
                                      .collection('projects')
                                      .doc(widget.projectId)
                                      .collection('comments')
                                      .add({
                                        'title': titleController.text.trim(),
                                        'body': bodyController.text.trim(),
                                        'timestamp':
                                            FieldValue.serverTimestamp(),
                                        'mentionedFiles': selectedFileIds,
                                        'authorEmail': user?.email ?? 'Unknown',
                                      });
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
                                'Add',
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

  @override
  Widget build(BuildContext context) {
    // Ensure we have the latest project data with files when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectsBloc>().add(
        FetchProjectsEvent(widget.organisationId, projectId: widget.projectId),
      );
    });

    return AlertDialog(
      title: Text(
        "Project comments",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width / 2,
        height: MediaQuery.of(context).size.height / 1.5,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor:
                          Theme.of(context).colorScheme.onSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _showAddCommentDialog,
                    icon: Icon(Icons.add),
                    label: Text("Create comment"),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('organisations')
                        .doc(widget.organisationId)
                        .collection('projects')
                        .doc(widget.projectId)
                        .collection('comments')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(child: Text('No comments yet.'));
                  }
                  return ListView.separated(
                    separatorBuilder: (context, index) => SizedBox(height: 10),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: ListTile(
                            leading: Container(
                              padding: EdgeInsets.fromLTRB(0, 10, 10, 10),
                              child: Icon(Icons.comment, size: 24),
                            ),
                            title: Text(
                              data['title'] ?? '',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              data['body'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              aweSideSheet(
                                context: context,
                                sheetPosition: SheetPosition.right,
                                sheetWidth:
                                    MediaQuery.of(context).size.width / 3,
                                header: SizedBox(height: 16),
                                body: CommentsSheet(
                                  organisationId: widget.organisationId,
                                  projectId: widget.projectId,
                                  commentId: docs[index].id,
                                ),
                                footer: SizedBox(height: 16),
                              );
                            },
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Delete Comment',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: Text('Delete Comment'),
                                        content: Text(
                                          'Are you sure you want to delete this comment?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                            child: Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                            child: Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                );
                                if (confirm == true) {
                                  await FirebaseFirestore.instance
                                      .collection('organisations')
                                      .doc(widget.organisationId)
                                      .collection('projects')
                                      .doc(widget.projectId)
                                      .collection('comments')
                                      .doc(docs[index].id)
                                      .delete();
                                }
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
