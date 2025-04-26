import 'package:flutter/material.dart';

class RequestDialog extends StatefulWidget {
  const RequestDialog({super.key});

  @override
  State<RequestDialog> createState() => _RequestDialogState();
}

class _RequestDialogState extends State<RequestDialog> {
  var sampleProjects = ["Project Alpha", "Project Beta", "Project Sigma"];

  var checkBoxStates = {};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    for (var x in sampleProjects) {
      checkBoxStates[x] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        "Project Requests",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width / 2,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SingleChildScrollView(
              child: ListView.builder(
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      title: Text(
                        sampleProjects[index],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "Supporting line text lorem ipsum dolor sit amet, consectetur.",
                      ),
                      trailing: Checkbox(
                        value: checkBoxStates[sampleProjects[index]],
                        onChanged: (value) {
                          checkBoxStates[sampleProjects[index]] = value!;
                          setState(() {
                            print(value);
                          });
                        },
                      ),
                    ),
                  );
                },
                itemCount: sampleProjects.length,
                shrinkWrap: true,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // create project
                Navigator.of(context).pop();
              },
              child: Padding(
                padding: EdgeInsets.fromLTRB(5, 15, 5, 15),
                child: Text(
                  "Approve projects",
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
