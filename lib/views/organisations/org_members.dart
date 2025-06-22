import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrgMembers extends StatefulWidget {
  const OrgMembers({
    super.key, 
    required this.teacherView,
    required this.organisationId,
    required this.organisationName,
  });

  final bool teacherView;
  final String organisationId;
  final String organisationName;

  @override
  State<OrgMembers> createState() => _OrganisationMembersDialogState();
}

class _OrganisationMembersDialogState extends State<OrgMembers> {
  TextEditingController memberEmailController = TextEditingController();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  
  List<Map<String, dynamic>> members = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMembers();
  }

  Future<void> fetchMembers() async {
    try {
      setState(() {
        isLoading = true;
      });

      QuerySnapshot membersSnapshot = await firestore
          .collection('organisations')
          .doc(widget.organisationId)
          .collection('members')
          .get();

      List<Map<String, dynamic>> membersList = [];
      for (var doc in membersSnapshot.docs) {
        Map<String, dynamic> memberData = doc.data() as Map<String, dynamic>;
        membersList.add({
          'id': doc.id,
          'email': memberData['email'] ?? 'Unknown',
          'role': memberData['role'] ?? 'member',
          'status': memberData['status'] ?? 'active',
        });
      }

      setState(() {
        members = membersList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching members: $e');
    }
  }

  Future<void> addMember() async {
    if (memberEmailController.text.isEmpty) return;

    try {
      // Add member to Firestore
      await firestore
          .collection('organisations')
          .doc(widget.organisationId)
          .collection('members')
          .doc()
          .set({
        'email': memberEmailController.text,
        'role': 'member',
        'status': 'pending',
        'addedAt': FieldValue.serverTimestamp(),
        'addedBy': auth.currentUser?.uid,
      });

      memberEmailController.clear();
      fetchMembers(); // Refresh the list
    } catch (e) {
      print('Error adding member: $e');
    }
  }

  Future<void> removeMember(String memberId) async {
    try {
      await firestore
          .collection('organisations')
          .doc(widget.organisationId)
          .collection('members')
          .doc(memberId)
          .delete();

      fetchMembers(); // Refresh the list
    } catch (e) {
      print('Error removing member: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    // Separate owners and members
    List<Map<String, dynamic>> owners = members.where((m) => m['role'] == 'owner').toList();
    List<Map<String, dynamic>> regularMembers = members.where((m) => m['role'] == 'member').toList();

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
                      "Organisation: ${widget.organisationName}",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                        onPressed: addMember,
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
            Align(alignment: Alignment.centerLeft, child: Text("Owners", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            SizedBox(height: 5),
            owners.isEmpty 
                ? Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text("No owners found", style: TextStyle(fontStyle: FontStyle.italic)),
                    ),
                  )
                : ListView.builder(
                    itemBuilder: (context, index) {
                      return Card(
                        child: ListTile(
                          leading: Icon(Icons.person, color: Colors.blue),
                          title: Text(
                            owners[index]['email'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("Owner"),
                          trailing: owners[index]['id'] == auth.currentUser?.uid
                              ? Chip(label: Text("You"), backgroundColor: Colors.green.shade100)
                              : null,
                        ),
                      );
                    },
                    itemCount: owners.length,
                    shrinkWrap: true,
                  ),
            SizedBox(height: 20),
            Align(alignment: Alignment.centerLeft, child: Text("Members", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            SizedBox(height: 5),
            regularMembers.isEmpty 
                ? Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text("No members found", style: TextStyle(fontStyle: FontStyle.italic)),
                    ),
                  )
                : ListView.builder(
                    itemBuilder: (context, index) {
                      return Card(
                        child: ListTile(
                          leading: Icon(Icons.person_outline),
                          title: Text(regularMembers[index]['email']),
                          subtitle: Text(regularMembers[index]['status'] ?? 'active'),
                          trailing: widget.teacherView
                              ? IconButton(
                                  onPressed: () => removeMember(regularMembers[index]['id']),
                                  icon: Icon(Icons.remove, color: Colors.red),
                                )
                              : null,
                        ),
                      );
                    },
                    itemCount: regularMembers.length,
                    shrinkWrap: true,
                  ),
          ],
        ),
      ),
    );
  }
}
