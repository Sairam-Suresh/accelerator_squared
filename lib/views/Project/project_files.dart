import 'package:flutter/material.dart';

class ProjectFilesDialog extends StatefulWidget {
  const ProjectFilesDialog({super.key});

  @override
  State<ProjectFilesDialog> createState() => _ProjectFilesDialogState();
}

class _ProjectFilesDialogState extends State<ProjectFilesDialog> {
  var filenameList = ["hello.py", "scoobert.png"];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        "Project Files",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width / 2,
        height: MediaQuery.of(context).size.height / 1.5,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Project Brief"),
            ),
            SizedBox(height: 5),
            Card(
              child: ListTile(
                title: Text("Project Brief"),
                subtitle: Text("2MB"),
                trailing: IconButton(onPressed: () {}, icon: Icon(Icons.edit)),
              ),
            ),
            SizedBox(height: 10),
            Align(alignment: Alignment.centerLeft, child: Text("Files")),
            SizedBox(height: 5),
            ListView.builder(
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    title: Text(filenameList[index]),
                    subtitle: Text("12KB"),
                    trailing: IconButton(
                      onPressed: () {
                        setState(() {
                          filenameList.remove(filenameList[index]);
                        });
                      },
                      icon: Icon(Icons.delete),
                    ),
                  ),
                );
              },
              itemCount: filenameList.length,
              shrinkWrap: true,
            ),
            Padding(
              padding: const EdgeInsets.all(5),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(5, 16, 5, 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Icon(Icons.add),
                      SizedBox(width: 10),
                      Text("Upload files"),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Padding(
                padding: EdgeInsets.fromLTRB(5, 15, 5, 15),
                child: Text(
                  "Save changes",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
