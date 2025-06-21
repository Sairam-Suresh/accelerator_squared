import 'package:flutter/material.dart';

class OrgMembers extends StatefulWidget {
  const OrgMembers({super.key, required this.teacherView});

  final String organisationCode = "ABCD";
  final bool teacherView;

  @override
  State<OrgMembers> createState() => _OrganisationMembersDialogState();
}

class _OrganisationMembersDialogState extends State<OrgMembers> {
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
    return Padding(
      padding: const EdgeInsets.all(15),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.teacherView
                ? Column(
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
                  ],
                )
                : SizedBox(),
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
          ],
        ),
      ),
    );
  }
}
