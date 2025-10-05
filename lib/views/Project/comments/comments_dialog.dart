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
  final String userRole;
  final String?
  preselectedMilestoneId; // New parameter for pre-selecting milestone
  final String? customTitle; // Optional custom title for the dialog
  const CommentsDialog({
    super.key,
    required this.projectId,
    required this.organisationId,
    required this.userRole,
    this.preselectedMilestoneId,
    this.customTitle,
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
    String? selectedMilestoneId = widget.preselectedMilestoneId;
    List<Map<String, dynamic>> milestones = [];

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
                  child: SizedBox(
                    height: 120,
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
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancel'),
                  ),
                ],
              );
            } else if (state is ProjectsLoaded) {
              final project = state.projects.firstWhere(
                (p) => p.id == widget.projectId,
                orElse: () => throw Exception('Project not found'),
              );

              // Get milestones for this project
              milestones = project.milestones;

              // Get files for this project
              files = project.files;
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
                          // Milestone assignment dropdown
                          if (milestones.isNotEmpty) ...[
                            DropdownButtonFormField<String>(
                              value: selectedMilestoneId,
                              decoration: InputDecoration(
                                labelText: 'Assign to Milestone (Optional)',
                                border: OutlineInputBorder(),
                              ),
                              hint: Text('Select a milestone'),
                              items: [
                                DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('No milestone'),
                                ),
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
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
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

                                  // Add milestone assignment if selected
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
                                      .doc(widget.projectId)
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
        widget.customTitle ?? "Project comments",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width / 2,
        height: MediaQuery.of(context).size.height / 1.5,
        child: Column(
          children: [
            Row(
              children: [
                if (widget.userRole == 'teacher')
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
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
            widget.userRole == 'teacher'
                ? SizedBox(height: 20)
                : SizedBox.shrink(),
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
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            aweSideSheet(
                              context: context,
                              sheetPosition: SheetPosition.right,
                              sheetWidth: MediaQuery.of(context).size.width / 3,
                              header: SizedBox(height: 16),
                              body: CommentsSheet(
                                organisationId: widget.organisationId,
                                projectId: widget.projectId,
                                commentId: docs[index].id,
                              ),
                              footer: SizedBox(height: 16),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: ListTile(
                              leading: Container(
                                padding: EdgeInsets.fromLTRB(0, 10, 10, 10),
                                child: Icon(Icons.comment, size: 24),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      data['title'] ?? '',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (data['assignedMilestoneId'] != null)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            data['milestoneDeclined'] == true
                                                ? Theme.of(
                                                  context,
                                                ).colorScheme.errorContainer
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .secondaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color:
                                              data['milestoneDeclined'] == true
                                                  ? Theme.of(
                                                    context,
                                                  ).colorScheme.error
                                                  : Theme.of(
                                                    context,
                                                  ).colorScheme.outline,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            data['milestoneDeclined'] == true
                                                ? Icons.flag_outlined
                                                : Icons.flag,
                                            size: 14,
                                            color:
                                                data['milestoneDeclined'] ==
                                                        true
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .onErrorContainer
                                                    : Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            data['assignedMilestoneName'] ??
                                                'Milestone',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color:
                                                  data['milestoneDeclined'] ==
                                                          true
                                                      ? Theme.of(context)
                                                          .colorScheme
                                                          .onErrorContainer
                                                      : null,
                                            ),
                                          ),
                                          if (data['milestoneDeclined'] ==
                                              true) ...[
                                            SizedBox(width: 4),
                                            Icon(
                                              Icons.cancel_outlined,
                                              size: 12,
                                              color:
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .onErrorContainer,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                data['body'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              trailing:
                                  widget.userRole == 'teacher'
                                      ? IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        tooltip: 'Delete Comment',
                                        onPressed: () async {
                                          final confirm = await showDialog<
                                            bool
                                          >(
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
                                      )
                                      : null,
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
