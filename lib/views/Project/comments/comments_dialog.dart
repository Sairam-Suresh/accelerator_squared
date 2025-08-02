import 'package:accelerator_squared/views/Project/comments/comments_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:awesome_side_sheet/Enums/sheet_position.dart';
import 'package:awesome_side_sheet/side_sheet.dart';

class CommentsDialog extends StatefulWidget {
  final String projectId;
  const CommentsDialog({super.key, required this.projectId});

  @override
  State<CommentsDialog> createState() => _CommentsDialogState();
}

class _CommentsDialogState extends State<CommentsDialog> {
  Future<List<Map<String, dynamic>>> _fetchFiles() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('projects')
            .doc(widget.projectId)
            .collection('files')
            .get();
    return snapshot.docs
        .map((doc) => {'id': doc.id, 'name': doc['name'] ?? doc.id})
        .toList();
  }

  Future<void> _showAddCommentDialog() async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    List<String> selectedFileIds = [];
    final files = await _fetchFiles();

    await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: Text('New Comment'),
                content: SingleChildScrollView(
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Mention files:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      files.isEmpty
                          ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'No files available to mention.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                          : Wrap(
                            spacing: 8,
                            children:
                                files.map((file) {
                                  final isSelected = selectedFileIds.contains(
                                    file['id'],
                                  );
                                  return FilterChip(
                                    label: Text(file['name']),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          selectedFileIds.add(file['id']);
                                        } else {
                                          selectedFileIds.remove(file['id']);
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
                                    (file) =>
                                        selectedFileIds.contains(file['id']),
                                  )
                                  .map(
                                    (file) => Chip(
                                      label: Text(file['name']),
                                      onDeleted: () {
                                        setState(() {
                                          selectedFileIds.remove(file['id']);
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
                    onPressed: () async {
                      if (titleController.text.trim().isNotEmpty &&
                          bodyController.text.trim().isNotEmpty) {
                        await FirebaseFirestore.instance
                            .collection('projects')
                            .doc(widget.projectId)
                            .collection('comments')
                            .add({
                              'title': titleController.text.trim(),
                              'body': bodyController.text.trim(),
                              'timestamp': FieldValue.serverTimestamp(),
                              'mentionedFiles': selectedFileIds,
                            });
                        Navigator.pop(
                          context,
                          true,
                        ); // Only pops the add comment dialog
                      }
                    },
                    child: Text(
                      'Add',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        // borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: ListTile(
                            leading: Container(
                              padding: EdgeInsets.fromLTRB(0, 10, 10, 10),
                              child: Icon(
                                Icons.comment,
                                // color: Colors.amber,
                                size: 24,
                              ),
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
