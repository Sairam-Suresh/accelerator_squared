import 'package:flutter/material.dart';

class OrgSettingsDialog extends StatefulWidget {
  const OrgSettingsDialog({
    super.key,
    required this.orgDescription,
    required this.orgName,
    required this.isTeacher,
  });

  final String orgName;
  final String orgDescription;
  final bool isTeacher;

  @override
  State<OrgSettingsDialog> createState() => _OrgSettingsDialogState();
}

class _OrgSettingsDialogState extends State<OrgSettingsDialog> {
  bool editingName = false;
  bool editingDescription = false;

  var nameFieldController = TextEditingController();
  var descriptionFieldController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    nameFieldController.text = widget.orgName;
    descriptionFieldController.text = widget.orgDescription;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        "Organisation info",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
      ),
      content: SizedBox(
        height: MediaQuery.of(context).size.height / 2,
        width: MediaQuery.of(context).size.width / 2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Organisation name",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 10),
            editingName
                ? TextField(
                  controller: nameFieldController,
                  decoration: InputDecoration(
                    hintText: "Enter organisation name",
                    label: Text("Organisation name"),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                )
                : Row(
                  children: [
                    Text(widget.orgName, style: TextStyle(fontSize: 16)),
                    Spacer(),
                    widget.isTeacher
                        ? IconButton.outlined(
                          onPressed: () {
                            setState(() {
                              editingName = true;
                            });
                          },
                          icon: Icon(Icons.edit),
                        )
                        : SizedBox(),
                  ],
                ),
            SizedBox(height: 20),
            Text(
              "Organisation description",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 10),
            editingDescription
                ? TextField(
                  controller: descriptionFieldController,
                  minLines: 3,
                  maxLines: 1000,
                  decoration: InputDecoration(
                    hintText: "Enter organisation description",
                    label: Text("Organisation description"),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                )
                : Row(
                  children: [
                    Text(widget.orgDescription, style: TextStyle(fontSize: 16)),
                    Spacer(),
                    widget.isTeacher
                        ? IconButton.outlined(
                          onPressed: () {
                            setState(() {
                              editingDescription = true;
                            });
                          },
                          icon: Icon(Icons.edit),
                        )
                        : SizedBox(),
                  ],
                ),
            SizedBox(height: 20),
            Text(
              "Members",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 10),
            Text("placeholder list", style: TextStyle(fontSize: 16)),
            Spacer(),
            widget.isTeacher
                ? Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(5, 15, 5, 15),
                      child: Text(
                        "Update settings",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
                : SizedBox(),
          ],
        ),
      ),
    );
  }
}
