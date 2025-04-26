import 'package:flutter/material.dart';

class CommentsSheet extends StatefulWidget {
  CommentsSheet({
    super.key,
    required this.sampleCommentsList,
    required this.sampleMilestoneDescriptions,
    required this.index,
  });

  List sampleCommentsList;
  List sampleMilestoneDescriptions;
  int index;

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.sampleCommentsList[widget.index],
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(widget.sampleMilestoneDescriptions[0]),
            SizedBox(height: 10),
            Divider(),
            SizedBox(height: 10),
            Text("Assigned by X"),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                var navigator = Navigator.of(context);
                navigator.pop();
              },
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Row(
                  children: [
                    Icon(Icons.check),
                    SizedBox(width: 10),
                    Text("Mark as completed"),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            Divider(),
            SizedBox(height: 10),
            // Text(
            //   "Comments",
            //   style: TextStyle(
            //     fontSize: 22,
            //     fontWeight:
            //         FontWeight
            //             .bold,
            //   ),
            // ),
          ],
        ),
      ],
    );
  }
}
