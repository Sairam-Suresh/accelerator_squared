import 'package:flutter/material.dart';

class OrgCreationDialog extends StatefulWidget {
  const OrgCreationDialog({super.key});

  @override
  State<OrgCreationDialog> createState() => _OrgCreationDialogState();
}

class _OrgCreationDialogState extends State<OrgCreationDialog> {
  TextEditingController orgnamecontroller = TextEditingController();
  TextEditingController orgdesccontroller = TextEditingController();
  TextEditingController emailaddingcontroller = TextEditingController();

  var orgmemberlist = [];

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, StateSetter setState) {
        return AlertDialog(
          scrollable: true,
          title: Text(
            "Create new organisation",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width / 2,
            height: MediaQuery.of(context).size.height / 1.5,
            child: Column(
              children: [
                TextField(
                  controller: orgnamecontroller,
                  decoration: InputDecoration(
                    label: Text("Organisation Name"),
                    hintText: "Enter organisation name",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: orgdesccontroller,
                  minLines: 3,
                  maxLines: 20,
                  decoration: InputDecoration(
                    label: Text("Organisation description"),
                    hintText: "Enter organisation description",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ),
                  onPressed: () {
                    // open google account selector
                  },
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset("../assets/drive.png", height: 30),
                        SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "dummyemail@gmail.com",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "Click to change account",
                              style: TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text("Member list"),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 3,
                      child: TextField(
                        controller: emailaddingcontroller,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          hintText: "Enter email to add",
                          label: Text("Add members' email"),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                      ),
                      onPressed: () {
                        orgmemberlist.add(emailaddingcontroller.text);
                        emailaddingcontroller.clear();
                        setState(() {});
                      },
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 13, 0, 13),
                        child: Text("Add", style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                !orgmemberlist.isEmpty
                    ? Expanded(
                      child: ListView.builder(
                        itemBuilder: (context, index) {
                          return Card(
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: Text(orgmemberlist[index]),
                            ),
                          );
                        },
                        itemCount: orgmemberlist.length,
                      ),
                    )
                    : Text("No members added yet"),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // create project
                    Navigator.of(context).pop();
                  },
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(5, 15, 5, 15),
                    child: Text(
                      "Create organisation",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
