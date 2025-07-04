import 'package:accelerator_squared/views/Project/comments/comments_sheet.dart';
import 'package:awesome_side_sheet/Enums/sheet_position.dart';
import 'package:awesome_side_sheet/side_sheet.dart';
import 'package:flutter/material.dart';

class CommentsDialog extends StatefulWidget {
  const CommentsDialog({
    super.key,
    required this.commentsContents,
    required this.commentsList,
  });

  final List commentsList;
  final List commentsContents;

  @override
  State<CommentsDialog> createState() => _CommentsDialogState();
}

class _CommentsDialogState extends State<CommentsDialog> {
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              ListView.builder(
                itemBuilder: (context, index) {
                  return Card(
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: ListTile(
                        onTap: () {
                          aweSideSheet(
                            footer: SizedBox(height: 10),
                            onCancel: () => Navigator.of(context).pop(),
                            header: SizedBox(height: 20),
                            sheetPosition: SheetPosition.right,
                            sheetWidth: MediaQuery.of(context).size.width / 3,
                            context: context,
                            body: Padding(
                              padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                              child: CommentsSheet(
                                sampleCommentsList: widget.commentsList,
                                sampleMilestoneDescriptions:
                                    widget.commentsContents,
                                index: index,
                              ),
                            ),
                          );
                        },
                        title: Text(
                          widget.commentsList[index],
                          style: TextStyle(fontSize: 20),
                        ),
                        subtitle: Text(widget.commentsContents[0], maxLines: 3),
                      ),
                    ),
                  );
                },
                itemCount: widget.commentsContents.length,
                shrinkWrap: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
