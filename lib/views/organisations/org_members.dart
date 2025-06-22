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
  bool memberOperationInProgress = false;
  bool isAddingMember = false;
  bool isChangingRole = false;
  bool isRemovingMember = false;
  String? currentOperationId;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching members: $e')),
        );
      }
    }
  }

  Future<void> addMember() async {
    if (memberEmailController.text.isEmpty) return;

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
      setState(() {
        memberOperationInProgress = true;
        isAddingMember = true;
      });
      
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
      fetchMembers();
      
      setState(() {
        memberOperationInProgress = false;
        isAddingMember = false;
      });
    } catch (e) {
      setState(() {
        memberOperationInProgress = false;
        isAddingMember = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding member: $e')),
        );
      }
    }
  }

  void _showRoleMenu(BuildContext context, Map<String, dynamic> member) {
    final String memberRole = member['role'] ?? 'member';
    final bool isCurrentUser = member['uid'] == auth.currentUser?.uid || 
                               member['email'] == auth.currentUser?.email;

    if (isCurrentUser) return;

    List<String> availableRoles = [];
    
    if (currentUserRole == 'teacher') {
      if (memberRole == 'teacher') {
        availableRoles = ['student_teacher', 'member'];
      } else if (memberRole == 'student_teacher') {
        availableRoles = ['teacher', 'member'];
      } else if (memberRole == 'member') {
        availableRoles = ['teacher', 'student_teacher'];
      }
    } else if (currentUserRole == 'student_teacher') {
      if (memberRole == 'student_teacher') {
        availableRoles = ['member'];
      } else if (memberRole == 'member') {
        availableRoles = ['student_teacher'];
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
          child: Text('Remove from organisation', style: TextStyle(color: Colors.red)),
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
      // Teachers can remove student teachers and members, but not other teachers
      return memberRole == 'student_teacher' || memberRole == 'member';
    } else if (currentUserRole == 'student_teacher') {
      // Student teachers can only remove members
      return memberRole == 'member';
    }
    // Members cannot remove anyone
    return false;
  }

  void _changeMemberRole(String memberId, String newRole) {
    setState(() {
      memberOperationInProgress = true;
      isChangingRole = true;
      currentOperationId = memberId;
    });
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
        content: Text('Are you sure you want to remove ${member['email']} from the organisation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                memberOperationInProgress = true;
                isRemovingMember = true;
                currentOperationId = member['id'];
              });
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrganisationsBloc, OrganisationsState>(
      listener: (context, state) {
        if (state is OrganisationsLoaded && memberOperationInProgress) {
          setState(() {
            memberOperationInProgress = false;
            isAddingMember = false;
            isChangingRole = false;
            isRemovingMember = false;
            currentOperationId = null;
          });
          fetchMembers();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Member operation completed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is OrganisationsError && memberOperationInProgress) {
          setState(() {
            memberOperationInProgress = false;
            isAddingMember = false;
            isChangingRole = false;
            isRemovingMember = false;
            currentOperationId = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    List<Map<String, dynamic>> teachers = members.where((m) => m['role'] == 'teacher').toList();
    List<Map<String, dynamic>> studentTeachers = members.where((m) => m['role'] == 'student_teacher').toList();
    List<Map<String, dynamic>> regularMembers = members.where((m) => m['role'] == 'member').toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.teacherView) ...[
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
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
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: isAddingMember ? null : addMember,
                      icon: isAddingMember
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                            ),
                          )
                        : Icon(Icons.add),
                      label: Padding(
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        child: isAddingMember
                          ? Text("Adding...", style: TextStyle(fontWeight: FontWeight.bold))
                          : Text("Add member", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          _buildSectionHeader(context, "Teachers", teachers.length),
          _buildMemberList(context, teachers, "Teacher"),
          const SizedBox(height: 16),
          Divider(),
          _buildSectionHeader(context, "Student Teachers", studentTeachers.length),
          _buildMemberList(context, studentTeachers, "Student Teacher"),
          const SizedBox(height: 16),
          Divider(),
          _buildSectionHeader(context, "Members", regularMembers.length),
          _buildMemberList(context, regularMembers, "Member"),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Chip(
            label: Text(count.toString()),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildMemberList(BuildContext context, List<Map<String, dynamic>> members, String roleLabel) {
    if (members.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text("No $roleLabel${roleLabel.endsWith('s') ? '' : 's'} found", style: TextStyle(fontStyle: FontStyle.italic, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
    }
    return ListView.separated(
      itemCount: members.length,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => SizedBox(height: 8),
      itemBuilder: (context, index) {
        final member = members[index];
        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: Text(
                (member['email'] as String).isNotEmpty ? member['email'][0].toUpperCase() : '?',
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              member['email'],
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRoleChip(context, member['role']),
                if (isCurrentUser(member)) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: Text("You", style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.green.shade400,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
                if (!isCurrentUser(member) && widget.teacherView && 
                    !(currentUserRole == 'student_teacher' && member['role'] == 'teacher')) ...[
                  PopupMenuButton<String>(
                    icon: (isChangingRole && currentOperationId == member['id'])
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                          ),
                        )
                      : Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'remove') {
                        _showRemoveConfirmation(member);
                      } else {
                        _changeMemberRole(member['id'], value);
                      }
                    },
                    itemBuilder: (context) {
                      final String memberRole = member['role'] ?? 'member';
                      List<String> availableRoles = [];
                      
                      if (currentUserRole == 'teacher') {
                        // Teacher permissions
                        if (memberRole == 'teacher') {
                          availableRoles = ['student_teacher', 'member'];
                        } else if (memberRole == 'student_teacher') {
                          availableRoles = ['teacher', 'member'];
                        } else if (memberRole == 'member') {
                          availableRoles = ['teacher', 'student_teacher'];
                        }
                      } else if (currentUserRole == 'student_teacher') {
                        // Student teacher permissions
                        if (memberRole == 'student_teacher') {
                          availableRoles = ['member'];
                        } else if (memberRole == 'member') {
                          availableRoles = ['student_teacher'];
                        }
                        // No options for teachers (teacher role)
                      }
                      // No options for members (member role)
                      
                      return [
                        ...availableRoles.map((role) => PopupMenuItem<String>(
                          value: role,
                          child: (isChangingRole && currentOperationId == member['id'])
                            ? Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Changing to ${_getRoleDisplayName(role)}...'),
                                ],
                              )
                            : Text('Change to ${_getRoleDisplayName(role)}'),
                        )),
                        if (_canRemoveMember(memberRole)) PopupMenuItem<String>(
                          value: 'remove',
                          child: (isRemovingMember && currentOperationId == member['id'])
                            ? Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Removing...', style: TextStyle(color: Colors.red)),
                                ],
                              )
                            : Text('Remove from organisation', style: TextStyle(color: Colors.red)),
                        ),
                      ];
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleChip(BuildContext context, String role) {
    Color bgColor;
    Color textColor;
    String label;
    switch (role) {
      case 'teacher':
        bgColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        label = 'Teacher';
        break;
      case 'student_teacher':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        label = 'Student Teacher';
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        label = 'Member';
    }
    return Chip(
      label: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
      backgroundColor: bgColor,
      visualDensity: VisualDensity.compact,
    );
  }
}
