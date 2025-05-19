import 'package:flutter/material.dart';

class OrgStatisticsDialog extends StatefulWidget {
  const OrgStatisticsDialog({super.key});

  @override
  State<OrgStatisticsDialog> createState() => _OrgStatisticsDialogState();
}

class _OrgStatisticsDialogState extends State<OrgStatisticsDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        "Organisation statistics",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width / 2,
        child: Column(mainAxisSize: MainAxisSize.min, children: []),
      ),
    );
  }
}
