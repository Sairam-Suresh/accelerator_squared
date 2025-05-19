import 'package:flutter/material.dart';

class JoinOrganizationDialog extends StatefulWidget {
  const JoinOrganizationDialog({super.key});

  @override
  State<JoinOrganizationDialog> createState() => _JoinOrganizationDialogState();
}

class _JoinOrganizationDialogState extends State<JoinOrganizationDialog> {
  TextEditingController orgcodecontroller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      content: SizedBox(
        width: MediaQuery.of(context).size.width / 2,
        height: MediaQuery.of(context).size.height / 4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Join organisation",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            Center(
              child: TextField(
                controller: orgcodecontroller,
                decoration: InputDecoration(
                  hintText: "Enter join code",
                  label: Text("Organisation code"),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            Spacer(),
            ElevatedButton(
              style: ButtonStyle(
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Padding(
                padding: EdgeInsets.fromLTRB(5, 15, 5, 15),
                child: Text(
                  "Send join request",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
