import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:accelerator_squared/blocs/organisations/organisations_bloc.dart';

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
  String currentUserRole = 'member';

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
          'uid': memberData['uid'] ?? '',
        });
        
        // Get current user's role
        if (memberData['uid'] == auth.currentUser?.uid || 
            memberData['email'] == auth.currentUser?.email) {
          currentUserRole = memberData['role'] ?? 'member';
        }
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

    // Email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(memberEmailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
        'status': 'active',
        'addedAt': FieldValue.serverTimestamp(),
        'addedBy': auth.currentUser?.uid,
      });

      memberEmailController.clear();
      fetchMembers(); // Refresh the list
    } catch (e) {
      print('Error adding member: $e');
    }
  }

  void _showRoleMenu(BuildContext context, Map<String, dynamic> member) {
    final String memberRole = member['role'] ?? 'member';
    final bool isCurrentUser = member['uid'] == auth.currentUser?.uid || 
                               member['email'] == auth.currentUser?.email;

    // Don't show menu for current user
    if (isCurrentUser) return;

    // Determine available role options based on current user's role and target member's role
    List<String> availableRoles = [];
    
    if (currentUserRole == 'teacher') {
      // Teachers can change any role
      if (memberRole != 'teacher') {
        availableRoles = ['teacher', 'student_teacher', 'member'];
      }
    } else if (currentUserRole == 'student_teacher') {
      // Student teachers can only change members to student_teacher or student_teacher to member
      if (memberRole == 'member') {
        availableRoles = ['student_teacher'];
      } else if (memberRole == 'student_teacher') {
        availableRoles = ['member'];
      }
    }

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(100, 100, 100, 100),
      items: [
        ...availableRoles.map((role) => PopupMenuItem<String>(
          value: role,
          child: Text('Change to ${_getRoleDisplayName(role)}'),
        )),
        if (_canRemoveMember(memberRole)) PopupMenuItem<String>(
          value: 'remove',
          child: Text('Remove from organization', style: TextStyle(color: Colors.red)),
        ),
      ],
    ).then((value) {
      if (value != null) {
        if (value == 'remove') {
          _showRemoveConfirmation(member);
        } else {
          _changeMemberRole(member['id'], value);
        }
      }
    });
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'teacher':
        return 'Teacher';
      case 'student_teacher':
        return 'Student Teacher';
      case 'member':
        return 'Member';
      default:
        return role;
    }
  }

  bool _canRemoveMember(String memberRole) {
    if (currentUserRole == 'teacher') {
      return memberRole != 'teacher';
    } else if (currentUserRole == 'student_teacher') {
      return memberRole == 'member';
    }
    return false;
  }

  void _changeMemberRole(String memberId, String newRole) {
    context.read<OrganisationsBloc>().add(
      ChangeMemberRoleEvent(
        organisationId: widget.organisationId,
        memberId: memberId,
        newRole: newRole,
      ),
    );
  }

  void _showRemoveConfirmation(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Member'),
        content: Text('Are you sure you want to remove ${member['email']} from the organization?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<OrganisationsBloc>().add(
                RemoveMemberEvent(
                  organisationId: widget.organisationId,
                  memberId: member['id'],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Remove'),
          ),
        ],
      ),
    );
  }

  bool isCurrentUser(Map<String, dynamic> member) {
    return member['uid'] == auth.currentUser?.uid || 
           member['email'] == auth.currentUser?.email;
  }

  Icon _getRoleIcon(String role) {
    switch (role) {
      case 'teacher':
        return Icon(Icons.school, color: Colors.blue);
      case 'student_teacher':
        return Icon(Icons.person, color: Colors.orange);
      case 'member':
        return Icon(Icons.person_outline, color: Colors.grey);
      default:
        return Icon(Icons.person_outline, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    // Separate members by role
    List<Map<String, dynamic>> teachers = members.where((m) => m['role'] == 'teacher').toList();
    List<Map<String, dynamic>> studentTeachers = members.where((m) => m['role'] == 'student_teacher').toList();
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
            
            // Teachers section
            if (teachers.isNotEmpty) ...[
              Align(alignment: Alignment.centerLeft, child: Text("Teachers", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              SizedBox(height: 5),
              ListView.builder(
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      leading: _getRoleIcon(teachers[index]['role']),
                      title: Text(
                        teachers[index]['email'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("Teacher"),
                      trailing: isCurrentUser(teachers[index])
                          ? Chip(
                              label: Text("You", style: TextStyle(color: Colors.white)),
                              backgroundColor: Colors.green.shade100,
                            )
                          : (widget.teacherView ? IconButton(
                              onPressed: () => _showRoleMenu(context, teachers[index]),
                              icon: Icon(Icons.more_vert),
                            ) : null),
                    ),
                  );
                },
                itemCount: teachers.length,
                shrinkWrap: true,
              ),
              SizedBox(height: 20),
            ],
            
            // Student Teachers section
            if (studentTeachers.isNotEmpty) ...[
              Align(alignment: Alignment.centerLeft, child: Text("Student Teachers", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              SizedBox(height: 5),
              ListView.builder(
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      leading: _getRoleIcon(studentTeachers[index]['role']),
                      title: Text(
                        studentTeachers[index]['email'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("Student Teacher"),
                      trailing: isCurrentUser(studentTeachers[index])
                          ? Chip(
                              label: Text("You", style: TextStyle(color: Colors.white)),
                              backgroundColor: Colors.green.shade100,
                            )
                          : (widget.teacherView ? IconButton(
                              onPressed: () => _showRoleMenu(context, studentTeachers[index]),
                              icon: Icon(Icons.more_vert),
                            ) : null),
                    ),
                  );
                },
                itemCount: studentTeachers.length,
                shrinkWrap: true,
              ),
              SizedBox(height: 20),
            ],
            
            // Members section
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
                          leading: _getRoleIcon(regularMembers[index]['role']),
                          title: Text(regularMembers[index]['email']),
                          subtitle: Text("Member"),
                          trailing: isCurrentUser(regularMembers[index])
                              ? Chip(
                                  label: Text("You", style: TextStyle(color: Colors.white)),
                                  backgroundColor: Colors.green.shade100,
                                )
                              : (widget.teacherView ? IconButton(
                                  onPressed: () => _showRoleMenu(context, regularMembers[index]),
                                  icon: Icon(Icons.more_vert),
                                ) : null),
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
