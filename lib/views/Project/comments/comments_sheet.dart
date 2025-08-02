import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CommentsSheet extends StatelessWidget {
  final String projectId;
  final String commentId;
  const CommentsSheet({
    super.key,
    required this.projectId,
    required this.commentId,
  });

  Future<Map<String, dynamic>?> _fetchComment() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('projects')
            .doc(projectId)
            .collection('comments')
            .doc(commentId)
            .get();
    return doc.data();
  }

  Future<List<Map<String, dynamic>>> _fetchFiles(List<String> fileIds) async {
    if (fileIds.isEmpty) return [];
    final filesSnap =
        await FirebaseFirestore.instance
            .collection('projects')
            .doc(projectId)
            .collection('files')
            .where(FieldPath.documentId, whereIn: fileIds)
            .get();
    return filesSnap.docs
        .map((doc) => {'id': doc.id, 'name': doc['name'] ?? doc.id})
        .toList();
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
              Text(
                comment['title'] ?? '',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(comment['body'] ?? '', style: TextStyle(fontSize: 18)),
              SizedBox(height: 24),
              Text(
                'Mentioned Files:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchFiles(mentionedFiles),
                builder: (context, fileSnap) {
                  if (!fileSnap.hasData)
                    return SizedBox(
                      height: 40,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  if (fileSnap.data!.isEmpty) return Text('None');
                  return Wrap(
                    spacing: 8,
                    children:
                        fileSnap.data!
                            .map((file) => Chip(label: Text(file['name'])))
                            .toList(),
                  );
                },
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
