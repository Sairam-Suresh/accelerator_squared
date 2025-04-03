import 'package:flutter/material.dart';

class OrgSettingsDialog extends StatefulWidget {
  const OrgSettingsDialog({super.key});

  @override
  State<OrgSettingsDialog> createState() => _OrgSettingsDialogState();
}

class _OrgSettingsDialogState extends State<OrgSettingsDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        "Organisation settings",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: "Enter organisation name",
              label: Text("Organisation name"),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            minLines: 3,
            maxLines: 1000,
            decoration: InputDecoration(
              hintText: "Enter organisation description",
              label: Text("Organisation description"),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          SizedBox(height: 20),
          Text("Members"),
          SizedBox(height: 10),
          Text("placeholder"),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Padding(
              padding: EdgeInsets.fromLTRB(5, 15, 5, 15),
              child: Text(
                "Update settings",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
    ();
  }
}
