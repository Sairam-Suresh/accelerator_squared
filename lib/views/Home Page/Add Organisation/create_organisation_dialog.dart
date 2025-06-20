import 'package:accelerator_squared/blocs/organisations/organisations_bloc.dart';
import 'package:accelerator_squared/blocs/user/user_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateOrganisationDialog extends StatefulWidget {
  const CreateOrganisationDialog({super.key});

  @override
  State<CreateOrganisationDialog> createState() =>
      _CreateOrganisationDialogState();
}

class _CreateOrganisationDialogState extends State<CreateOrganisationDialog> {
  var emailAddingController = TextEditingController();
  var orgNameController = TextEditingController();
  var orgDescController = TextEditingController();

  var orgMemberList = [];

  @override
  Widget build(BuildContext context) {
    var userState = context.read<UserBloc>().state as UserLoggedIn;

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
              controller: orgNameController,
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
              controller: orgDescController,
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
            SizedBox(height: 10),
            ElevatedButton(
              style: ButtonStyle(
                shape: WidgetStateProperty.all(
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
                          userState.email,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        // Text(
                        //   "Click to change account",
                        //   style: TextStyle(fontSize: 15),
                        // ),
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
                  width: MediaQuery.of(context).size.width / 2.5 + 20,
                  child: TextField(
                    controller: emailAddingController,
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
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ),
                  onPressed: () {
                    if (!emailAddingController.text.isEmpty) {
                      orgMemberList.add(emailAddingController.text);
                      emailAddingController.clear();
                      setState(() {});
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text("Email provided is empty!"),
                            content: Text(
                              "Email field cannot be empty when adding a new user",
                            ),
                            actions: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  "OK",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 13, 0, 13),
                    child: Text("Add", style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            orgMemberList.isNotEmpty
                ? Expanded(
                  child: ListView.builder(
                    itemBuilder: (context, index) {
                      return Card(
                        child: ListTile(
                          title: Text(orgMemberList[index]),
                          trailing: IconButton(
                            onPressed: () {
                              setState(() {
                                orgMemberList.removeAt(index);
                              });
                            },
                            icon: Icon(Icons.cancel, color: Colors.red),
                          ),
                        ),
                      );
                    },
                    itemCount: orgMemberList.length,
                  ),
                )
                : Text("No members added yet"),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.read<OrganisationsBloc>().add(
                  CreateOrganisationEvent(
                    name: orgNameController.text,
                    description: orgDescController.text,
                    memberEmails: List<String>.from(orgMemberList),
                  ),
                );
                Navigator.of(context).pop();
              },
              child: Padding(
                padding: EdgeInsets.fromLTRB(5, 15, 5, 15),
                child: Text(
                  "Create organisation",
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
