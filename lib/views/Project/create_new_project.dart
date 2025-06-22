import 'package:accelerator_squared/blocs/user/user_bloc.dart';
import 'package:accelerator_squared/blocs/organisations/organisations_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewProjectDialog extends StatefulWidget {
  const NewProjectDialog({
    super.key, 
    required this.organisationId,
    required this.isTeacher,
  });

  final String organisationId;
  final bool isTeacher;

  @override
  State<NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<NewProjectDialog> {
  TextEditingController projectNameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController emailAddingController = TextEditingController();

  bool? backupFileHistory = false;
  List<String> memberEmailsList = [];
  List<Map<String, dynamic>> organizationMembers = [];

  @override
  void initState() {
    super.initState();
    fetchOrganizationMembers();
  }

  Future<void> fetchOrganizationMembers() async {
    try {
      QuerySnapshot membersSnapshot = await FirebaseFirestore.instance
          .collection('organisations')
          .doc(widget.organisationId)
          .collection('members')
          .get();

      List<Map<String, dynamic>> members = [];
      for (var doc in membersSnapshot.docs) {
        Map<String, dynamic> memberData = doc.data() as Map<String, dynamic>;
        members.add({
          'email': memberData['email'] ?? '',
          'role': memberData['role'] ?? 'member',
        });
      }

      setState(() {
        organizationMembers = members;
      });
    } catch (e) {
      print('Error fetching organization members: $e');
    }
  }

  bool isTeacher(String email) {
    final member = organizationMembers.firstWhere(
      (m) => m['email'] == email,
      orElse: () => {'role': 'member'},
    );
    return member['role'] == 'teacher';
  }

  @override
  Widget build(BuildContext context) {
    var userState = context.read<UserBloc>().state as UserLoggedIn;

    return StatefulBuilder(
      builder: (context, StateSetter setState) {
        return AlertDialog(
          scrollable: true,
          content: SizedBox(
            width: MediaQuery.of(context).size.width / 2,
            height: MediaQuery.of(context).size.height / 1.5,
            child: Column(
              children: [
                Text(
                  widget.isTeacher ? "Create new project" : "Submit project request",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: projectNameController,
                  decoration: InputDecoration(
                    label: Text("Project Name"),
                    hintText: "Enter project name",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  minLines: 3,
                  maxLines: 20,
                  decoration: InputDecoration(
                    label: Text("Project description (optional)"),
                    hintText: "Enter project description",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                if (!widget.isTeacher) ...[
                  SizedBox(height: 20),
                  Text("Member list"),
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Note: Teachers cannot be added to projects",
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                            // Check if the email belongs to a teacher
                            if (isTeacher(emailAddingController.text)) {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text("Cannot add teacher"),
                                    content: Text(
                                      "Teachers cannot be added to projects. Please add student teachers or members only.",
                                    ),
                                    actions: [
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text("OK"),
                                      ),
                                    ],
                                  );
                                },
                              );
                              return;
                            }

                            setState(() {
                              memberEmailsList.add(emailAddingController.text);
                              emailAddingController.clear();
                            });
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
                  memberEmailsList.isNotEmpty
                      ? Expanded(
                        child: ListView.builder(
                          itemBuilder: (context, index) {
                            return Card(
                              child: ListTile(
                                title: Text(memberEmailsList[index]),
                                subtitle: Text(
                                  isTeacher(memberEmailsList[index]) ? "Teacher (cannot be added)" : "Member",
                                  style: TextStyle(
                                    color: isTeacher(memberEmailsList[index]) ? Colors.red : Colors.grey,
                                  ),
                                ),
                                trailing: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      memberEmailsList.removeAt(index);
                                    });
                                  },
                                  icon: Icon(Icons.cancel, color: Colors.red),
                                ),
                              ),
                            );
                          },
                          itemCount: memberEmailsList.length,
                        ),
                      )
                      : Text("No members added yet"),
                ],
                SizedBox(height: 20),
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // create project or submit request
                    if (projectNameController.text.isNotEmpty) {
                      if (widget.isTeacher) {
                        // Direct project creation for teachers
                        context.read<OrganisationsBloc>().add(
                          CreateProjectEvent(
                            organisationId: widget.organisationId,
                            title: projectNameController.text,
                            description: descriptionController.text,
                          ),
                        );
                      } else {
                        // Submit project request for members
                        context.read<OrganisationsBloc>().add(
                          SubmitProjectRequestEvent(
                            organisationId: widget.organisationId,
                            title: projectNameController.text,
                            description: descriptionController.text,
                            memberEmails: List<String>.from(memberEmailsList),
                          ),
                        );
                      }
                      Navigator.of(context).pop();
                    } else {
                      // Show error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please enter a project title'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(5, 15, 5, 15),
                    child: Text(
                      widget.isTeacher ? "Create project" : "Submit request",
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
