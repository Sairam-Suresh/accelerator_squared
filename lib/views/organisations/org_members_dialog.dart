import 'package:flutter/material.dart';

class OrganisationMembersDialog extends StatefulWidget {
  const OrganisationMembersDialog({super.key});

  final String organisationCode = "ABCD";

  @override
  State<OrganisationMembersDialog> createState() =>
      _OrganisationMembersDialogState();
}

class _OrganisationMembersDialogState extends State<OrganisationMembersDialog> {
  TextEditingController memberEmailController = TextEditingController();
  var orgTeachersList = {
    "Aurelius Yeo": "aurelius_yeo@sst.edu.sg",
    "Jovita Tang": "jovita_tang@sst.edu.sg",
  };
  var orgStudentsList = [
    "chay_yu_hung@s2021.ssts.edu.sg",
    "sairam_suresh@s2021.ssts.edu.sg",
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        "Organisation members",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width / 2,
        height: MediaQuery.of(context).size.height / 2,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Organisation code: ${widget.organisationCode}",
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: MediaQuery.of(context).size.width / 2.5,
                child: TextField(
                  controller: memberEmailController,
                  decoration: InputDecoration(
                    label: Text("Add user to organisation"),
                    hintText: "Enter email to add",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: MediaQuery.of(context).size.width / 2.5,
                child: ElevatedButton(
                  onPressed: () {
                    // Add member to member list of org
                    setState(() {
                      orgStudentsList.add(memberEmailController.text);
                      memberEmailController.clear();
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(5, 15, 5, 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add),
                        SizedBox(width: 10),
                        Text(
                          "Add member",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Align(alignment: Alignment.centerLeft, child: Text("Teachers")),
              SizedBox(height: 5),
              ListView.builder(
                itemBuilder: (context, index) {
                  var keysList = orgTeachersList.keys.toList();
                  return Card(
                    child: ListTile(
                      title: Text(
                        keysList[index],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(orgTeachersList[keysList[index]]!),
                    ),
                  );
                },
                itemCount: orgTeachersList.length,
                shrinkWrap: true,
              ),
              SizedBox(height: 10),
              Align(alignment: Alignment.centerLeft, child: Text("Students")),
              SizedBox(height: 5),
              ListView.builder(
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      title: Text(orgStudentsList[index]),
                      trailing: IconButton(
                        onPressed: () {
                          setState(() {
                            orgStudentsList.remove(orgStudentsList[index]);
                          });
                        },
                        icon: Icon(Icons.remove, color: Colors.red),
                      ),
                    ),
                  );
                },
                itemCount: orgStudentsList.length,
                shrinkWrap: true,
              ),
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: () {
                  // create project
                  Navigator.of(context).pop();
                },
                child: Padding(
                  padding: EdgeInsets.fromLTRB(5, 15, 5, 15),
                  child: Text(
                    "Save members",
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
