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
      title: Row(
        children: [
          Icon(Icons.business, color: Theme.of(context).colorScheme.primary),
          SizedBox(width: 10),
          Text(
            "Organisation Info",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width / 2.5,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.label, color: Theme.of(context).colorScheme.primary),
                        SizedBox(width: 8),
                        Text(
                          "Organisation Name",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        Spacer(),
                        if (widget.isTeacher)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                editingName = true;
                              });
                            },
                            icon: Icon(Icons.edit, size: 20),
                            tooltip: "Edit name",
                          ),
                      ],
                    ),
                    SizedBox(height: 8),
                    editingName
                        ? TextField(
                            controller: nameFieldController,
                            decoration: InputDecoration(
                              hintText: "Enter organisation name",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          )
                        : Text(
                            widget.orgName,
                            style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                          ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description, color: Theme.of(context).colorScheme.primary),
                        SizedBox(width: 8),
                        Text(
                          "Description",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        Spacer(),
                        if (widget.isTeacher)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                editingDescription = true;
                              });
                            },
                            icon: Icon(Icons.edit, size: 20),
                            tooltip: "Edit description",
                          ),
                      ],
                    ),
                    SizedBox(height: 8),
                    editingDescription
                        ? TextField(
                            controller: descriptionFieldController,
                            minLines: 3,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: "Enter organisation description",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          )
                        : Text(
                            widget.orgDescription.isEmpty ? "No description provided" : widget.orgDescription,
                            style: TextStyle(
                              fontSize: 16,
                              color: widget.orgDescription.isEmpty 
                                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            
            if (widget.isTeacher)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("Cancel"),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement save functionality
                      Navigator.of(context).pop();
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text("Save Changes"),
                    ),
                  ),
                ],
              )
            else
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text("Close"),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
