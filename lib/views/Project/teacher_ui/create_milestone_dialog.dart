import 'package:flutter/material.dart';

class CreateMilestoneDialog extends StatefulWidget {
  const CreateMilestoneDialog({super.key});

  @override
  State<CreateMilestoneDialog> createState() => _CreateMilestoneDialogState();
}

class _CreateMilestoneDialogState extends State<CreateMilestoneDialog> {
  var projectsList = ["Project 1", "Project 2"];
  var projectStates = {};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    for (var x in projectsList) {
      projectStates[x] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        "Create new milestone",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width / 2,
        height: MediaQuery.of(context).size.height / 1.5,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: "Milestone Title",
                  label: Text("Enter Milestone Title"),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                minLines: 3,
                maxLines: 100,
                decoration: InputDecoration(
                  hintText: "Milestone Description",
                  label: Text("Enter Milestone Description"),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  hintText: "dd/mm/yyyy",
                  label: Text("Due Date"),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Align(alignment: Alignment.centerLeft, child: Text("Assign to")),
              SizedBox(height: 5),
              ListView.builder(
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      title: Text(
                        projectsList[index],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Checkbox(
                        value: projectStates[projectsList[index]],
                        onChanged: (value) {
                          setState(() {
                            projectStates[projectsList[index]] = value!;
                          });
                        },
                      ),
                    ),
                  );
                },
                itemCount: projectsList.length,
                shrinkWrap: true,
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
                    "Create milestone",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
