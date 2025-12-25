import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:accelerator_squared/util/snackbar_helper.dart';
import 'dart:math' as math;

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
  String currentUserRole = 'member';
  bool memberOperationInProgress = false;
  bool isAddingMember = false;
  List<Map<String, dynamic>> organisationMembers = [];
  bool isRemovingMember = false;
  String? currentOperationId;
  final TextEditingController _searchController = TextEditingController();
  final LayerLink _emailFieldLink = LayerLink();
  final FocusNode _emailFieldFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    fetchMembers();
    fetchOrganisationMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _emailFieldFocusNode.dispose();
    super.dispose();
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
        SnackBarHelper.showError(
          context,
          message: 'Error fetching project members: $e',
        );
      }
    }
  }

  Future<void> fetchOrganisationMembers() async {
    try {
      QuerySnapshot membersSnapshot =
          await firestore
              .collection('organisations')
              .doc(widget.organisationId)
              .collection('members')
              .get();

      List<Map<String, dynamic>> orgMembers = [];
      for (var doc in membersSnapshot.docs) {
        Map<String, dynamic> memberData = doc.data() as Map<String, dynamic>;
        orgMembers.add({
          'email': memberData['email'] ?? '',
          'role': memberData['role'] ?? 'member',
        });
      }

      if (mounted) {
        setState(() {
          organisationMembers = orgMembers;
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          message: 'Error fetching organisation members: $e',
        );
      }
    }
  }

  Future<void> addMemberFromEmail(String email) async {
    if (email.isEmpty) return;

    // Ensure email is in organisation
    final orgMember = organisationMembers.firstWhere(
      (m) => (m['email'] as String).toLowerCase() == email.toLowerCase(),
      orElse: () => {'email': '', 'role': ''},
    );
    if ((orgMember['email'] as String).isEmpty) {
      SnackBarHelper.showError(
        context,
        message: 'This email is not a member of the organisation.',
      );
      return;
    }

    // Disallow teachers in projects (follow create_new_project.dart)
    if (orgMember['role'] == 'teacher') {
      SnackBarHelper.showError(
        context,
        message: 'Teachers cannot be added to projects.',
      );
      return;
    }

    // Prevent duplicates in project
    final alreadyInProject = members.any(
      (m) => (m['email'] as String).toLowerCase() == email.toLowerCase(),
    );
    if (alreadyInProject) {
      SnackBarHelper.showError(
        context,
        message: 'This user is already a project member.',
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
          .collection('projects')
          .doc(widget.projectId)
          .collection('members')
          .doc(email)
          .set({
            'email': email,
            'role': 'member',
            'status': 'active',
            'addedAt': FieldValue.serverTimestamp(),
            'addedBy': auth.currentUser?.uid,
          });

      await fetchMembers();

      if (mounted) {
        SnackBarHelper.showSuccess(context, message: 'Member added to project');
      }

      setState(() {
        memberOperationInProgress = false;
        isAddingMember = false;
        _searchController.clear();
        _emailFieldFocusNode.unfocus();
      });
    } catch (e) {
      setState(() {
        memberOperationInProgress = false;
        isAddingMember = false;
      });
      if (mounted) {
        SnackBarHelper.showError(context, message: 'Error adding member: $e');
      }
    }
  }

  bool _hasDisplayName(Map<String, dynamic> member) {
    final displayName = member['displayName'];
    if (displayName == null) return false;
    if (displayName is String) {
      return displayName.isNotEmpty;
    }
    return false;
  }

  String _getDisplayName(Map<String, dynamic> member) {
    final displayName = member['displayName'];
    if (displayName != null && displayName is String && displayName.isNotEmpty) {
      return displayName;
    }
    return member['email'] as String? ?? 'Unknown';
  }

  String _getInitials(Map<String, dynamic> member) {
    final displayName = member['displayName'];
    final email = member['email'] as String? ?? '';
    
    if (displayName != null && displayName is String && displayName.isNotEmpty) {
      final parts = displayName.trim().split(' ');
      if (parts.length >= 2) {
        return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
      } else if (parts.isNotEmpty) {
        return parts[0][0].toUpperCase();
      }
    }
    
    if (email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return '?';
  }

  bool isCurrentUser(Map<String, dynamic> member) {
    return member['uid'] == auth.currentUser?.uid ||
        member['email'] == auth.currentUser?.email;
  }

  bool _canRemoveMember(String memberRole) {
    if (currentUserRole == 'teacher') {
      return memberRole == 'student_teacher' || memberRole == 'member';
    } else if (currentUserRole == 'student_teacher') {
      return memberRole == 'member';
    }
    return false;
  }

  Future<void> _removeMember(String memberId) async {
    try {
      setState(() {
        memberOperationInProgress = true;
        isRemovingMember = true;
        currentOperationId = memberId;
      });
      await firestore
          .collection('organisations')
          .doc(widget.organisationId)
          .collection('projects')
          .doc(widget.projectId)
          .collection('members')
          .doc(memberId)
          .delete();

      await fetchMembers();
      if (mounted) {
        SnackBarHelper.showSuccess(
          context,
          message: 'Member removed from project',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, message: 'Error removing member: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          memberOperationInProgress = false;
          isRemovingMember = false;
          currentOperationId = null;
        });
      }
    }
  }

  void _showRemoveConfirmation(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Remove Member'),
            content: Text(
              'Are you sure you want to remove ${_getDisplayName(member)} from the project?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _removeMember(member['id']);
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
            if (currentUserRole == 'teacher' ||
                currentUserRole == 'student_teacher') ...[
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: CompositedTransformTarget(
                          link: _emailFieldLink,
                          child: RawAutocomplete<String>(
                            textEditingController: _searchController,
                            focusNode: _emailFieldFocusNode,
                            optionsBuilder: (TextEditingValue value) {
                              final query = value.text.toLowerCase();
                              final filteredMembers =
                                  organisationMembers
                                      .where(
                                        (m) =>
                                            (m['role'] ?? '') != 'teacher' &&
                                            !members.any(
                                              (added) => 
                                                  (added['email'] as String).toLowerCase() == 
                                                  (m['email'] as String).toLowerCase(),
                                            ),
                                      )
                                      .toList();
                              
                              if (query.isEmpty) {
                                return filteredMembers.map((m) => m['email'] as String).toList();
                              }
                              
                              return filteredMembers
                                  .where((m) {
                                    final email = (m['email'] ?? '').toString().toLowerCase();
                                    final displayName = (m['displayName'] ?? '').toString().toLowerCase();
                                    return email.contains(query) || displayName.contains(query);
                                  })
                                  .map((m) => m['email'] as String)
                                  .toList();
                            },
                            displayStringForOption: (opt) {
                              final member = organisationMembers.firstWhere(
                                (m) => (m['email'] ?? '').toString() == opt,
                                orElse: () => {'email': opt, 'displayName': null},
                              );
                              final displayName = member['displayName'] as String?;
                              if (displayName != null && displayName.isNotEmpty) {
                                return '$displayName ($opt)';
                              }
                              return opt;
                            },
                            optionsViewBuilder: (
                              context,
                              onSelected,
                              options,
                            ) {
                              final tileHeight = 80.0;
                              final listHeight = math.min(
                                options.length * tileHeight,
                                240.0,
                              );
                              return CompositedTransformFollower(
                                link: _emailFieldLink,
                                showWhenUnlinked: false,
                                offset: const Offset(0, 56),
                                child: Material(
                                  elevation: 4,
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    height: listHeight,
                                    child: ListView.separated(
                                      separatorBuilder:
                                          (context, index) =>
                                              Divider(thickness: 1),
                                      padding: EdgeInsets.zero,
                                      itemCount: options.length,
                                      itemBuilder: (context, index) {
                                        final opt = options.elementAt(
                                          index,
                                        );
                                        final member =
                                            organisationMembers
                                                .firstWhere(
                                                  (m) =>
                                                      (m['email'] ?? '')
                                                          .toString() ==
                                                      opt,
                                                  orElse:
                                                      () => {'role': '', 'displayName': null},
                                                );
                                        final displayName = member['displayName'] as String?;
                                        final role = member['role']?.toString() ?? '';
                                        
                                        return Padding(
                                          padding: EdgeInsets.all(10),
                                          child: ListTile(
                                            dense: true,
                                            leading: CircleAvatar(
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme.primaryContainer,
                                              child: Text(
                                                _getInitials(member),
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.primary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            title: Text(
                                              displayName != null && displayName.isNotEmpty
                                                  ? displayName
                                                  : opt,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                if (displayName != null && displayName.isNotEmpty)
                                                  Text(
                                                    opt,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Theme.of(context)
                                                          .colorScheme.onSurfaceVariant,
                                                    ),
                                                  ),
                                                if (role.isNotEmpty)
                                                  Text(
                                                    role,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Theme.of(context)
                                                          .colorScheme.onSurfaceVariant,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            onTap: () => onSelected(opt),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                            onSelected: (opt) {
                              addMemberFromEmail(opt);
                              _emailFieldFocusNode.unfocus();
                              _searchController.clear();
                            },
                            fieldViewBuilder: (
                              context,
                              textController,
                              focusNode,
                              onFieldSubmitted,
                            ) {
                              return TextField(
                                controller: textController,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  hintText: "Enter member's email",
                                  label: Text("Member Email"),
                                  prefixIcon: Icon(Icons.email_rounded),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.outline,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withValues(alpha: 0.3),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        onPressed: isAddingMember
                            ? null
                            : () {
                                if (_searchController.text.isNotEmpty) {
                                  addMemberFromEmail(_searchController.text.trim());
                                }
                              },
                        icon: Icon(Icons.add_rounded, size: 20),
                        label: Text("Add"),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
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
                _getInitials(member),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              _getDisplayName(member),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: _hasDisplayName(member)
                ? Text(
                    member['email'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                : null,
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
                if (!isCurrentUser(member) &&
                    (currentUserRole == 'teacher' ||
                        currentUserRole == 'student_teacher') &&
                    !(currentUserRole == 'student_teacher' &&
                        member['role'] == 'teacher') &&
                    _canRemoveMember(member['role'])) ...[
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon:
                        (isRemovingMember && currentOperationId == member['id'])
                            ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            )
                            : Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'remove') {
                        _showRemoveConfirmation(member);
                      }
                    },
                    itemBuilder: (context) {
                      return [
                        PopupMenuItem<String>(
                          value: 'remove',
                          child:
                              (isRemovingMember &&
                                      currentOperationId == member['id'])
                                  ? Row(
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.red,
                                              ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Removing...',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  )
                                  : Text(
                                    'Remove from project',
                                    style: TextStyle(color: Colors.red),
                                  ),
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
      label: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      ),
      backgroundColor: bgColor,
      visualDensity: VisualDensity.compact,
    );
  }
}

