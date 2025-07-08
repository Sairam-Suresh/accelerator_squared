import 'package:flutter/material.dart';

class DeclineMilestoneDialog extends StatefulWidget {
  DeclineMilestoneDialog({super.key, required this.feedback});

  String feedback = '';

  @override
  State<DeclineMilestoneDialog> createState() => _DeclineMilestoneDialogState();
}

class _DeclineMilestoneDialogState extends State<DeclineMilestoneDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Decline Milestone Review'),
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
          child: Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.of(context).pop(widget.feedback),
          child: Text('Decline'),
        ),
      ],
    );
  }
}
