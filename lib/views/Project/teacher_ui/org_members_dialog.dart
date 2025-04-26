import 'package:flutter/material.dart';

class OrganisationMembersDialog extends StatefulWidget {
  const OrganisationMembersDialog({super.key});

  @override
  State<OrganisationMembersDialog> createState() =>
      _OrganisationMembersDialogState();
}

class _OrganisationMembersDialogState extends State<OrganisationMembersDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        "Organisation members",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width / 2,
        child: Column(mainAxisSize: MainAxisSize.min, children: []),
      ),
    );
  }
}
