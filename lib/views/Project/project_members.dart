import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProjectMembersDialog extends StatefulWidget {
  final String organisationId;
  final String projectId;
  const ProjectMembersDialog({
    super.key,
    required this.organisationId,
    required this.projectId,
  });

  @override
  State<ProjectMembersDialog> createState() => _ProjectMembersDialogState();
}

class _ProjectMembersDialogState extends State<ProjectMembersDialog> {
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
      QuerySnapshot membersSnapshot =
          await firestore
              .collection('organisations')
              .doc(widget.organisationId)
              .collection('projects')
              .doc(widget.projectId)
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
          SnackBar(content: Text('Error fetching project members: $e')),
        );
      }
    }
  }

  bool isCurrentUser(Map<String, dynamic> member) {
    return member['uid'] == auth.currentUser?.uid ||
        member['email'] == auth.currentUser?.email;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        "Project Members",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width / 2,
        height: MediaQuery.of(context).size.height / 2,
        child:
            isLoading
                ? Center(child: CircularProgressIndicator())
                : _buildContent(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            child: Text(
              "Close",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    List<Map<String, dynamic>> teachers =
        members.where((m) => m['role'] == 'teacher').toList();
    List<Map<String, dynamic>> studentTeachers =
        members.where((m) => m['role'] == 'student_teacher').toList();
    List<Map<String, dynamic>> regularMembers =
        members.where((m) => m['role'] == 'member').toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, "Teachers", teachers.length),
            _buildMemberList(context, teachers, "Teacher"),
            const SizedBox(height: 16),
            Divider(),
            SizedBox(height: 5),
            _buildSectionHeader(
              context,
              "Student Teachers",
              studentTeachers.length,
            ),
            _buildMemberList(context, studentTeachers, "Student Teacher"),
            const SizedBox(height: 16),
            Divider(),
            SizedBox(height: 5),
            _buildSectionHeader(context, "Members", regularMembers.length),
            _buildMemberList(context, regularMembers, "Member"),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Chip(
            label: Text(count.toString()),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildMemberList(
    BuildContext context,
    List<Map<String, dynamic>> members,
    String roleLabel,
  ) {
    if (members.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          "No $roleLabel${roleLabel.endsWith('s') ? '' : 's'} found",
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: members.length,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => SizedBox(height: 7.5),
      itemBuilder: (context, index) {
        final member = members[index];
        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.5,
              vertical: 7.5,
            ),
            leading: CircleAvatar(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withAlpha(25),
              child: Text(
                (member['email'] as String).isNotEmpty
                    ? member['email'][0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
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
      label: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      ),
      backgroundColor: bgColor,
      visualDensity: VisualDensity.compact,
    );
  }
}
