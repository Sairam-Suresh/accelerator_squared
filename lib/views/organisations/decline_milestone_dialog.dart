import 'package:flutter/material.dart';

class DeclineRequestDialog extends StatefulWidget {
  DeclineRequestDialog({
    super.key,
    required this.feedback,
    required this.isMilestone,
  });

  String feedback = '';
  final bool isMilestone;

  @override
  State<DeclineRequestDialog> createState() => _DeclineMilestoneDialogState();
}

class _DeclineMilestoneDialogState extends State<DeclineRequestDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isMilestone ? 'Decline Milestone Review' : 'Decline Task Review',
      ),
      content: TextField(
        minLines: 3,
        maxLines: 10,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Feedback to student',
          hintText: 'Enter feedback (optional)',
        ),
        onChanged: (val) => widget.feedback = val,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.of(context).pop(widget.feedback),
          child: Text(
            'Decline',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
        ),
      ],
    );
  }
}
