import 'package:accelerator_squared/blocs/organisation/organisation_bloc.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:accelerator_squared/blocs/organisations/organisations_bloc.dart';
import 'package:accelerator_squared/util/snackbar_helper.dart';
import 'package:accelerator_squared/util/util.dart';

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
  StreamSubscription<QuerySnapshot>? _membersSubscription;
  bool memberOperationInProgress = false;
  bool isAddingMember = false;
  bool isChangingRole = false;
  bool isRemovingMember = false;
  bool isRetractingInvite = false;
  String? currentOperationId;

  @override
  void initState() {
    super.initState();
    fetchMembers();
    _membersSubscription = firestore
        .collection('organisations')
        .doc(widget.organisationId)
        .collection('members')
        .snapshots()
        .listen((snapshot) async {
          List<Map<String, dynamic>> membersList = [];
          List<String> uidsToFetch = [];

          for (final doc in snapshot.docs) {
            final memberData = doc.data();
            final uid = memberData['uid'] as String? ?? '';
            final storedDisplayName = memberData['displayName'] as String?;
            membersList.add({
              'id': doc.id,
              'email': memberData['email'] ?? 'Unknown',
              'role': memberData['role'] ?? 'member',
              'uid': uid,
              'status': memberData['status'] ?? 'active',
              'displayName': storedDisplayName, // Use stored displayName first
            });

            if (memberData['uid'] == auth.currentUser?.uid ||
                memberData['email'] == auth.currentUser?.email) {
              currentUserRole = memberData['role'] ?? 'member';
            }

            // Only fetch from users collection if displayName is not stored
            if (uid.isNotEmpty &&
                (storedDisplayName == null || storedDisplayName.isEmpty)) {
              uidsToFetch.add(uid);
            }
          }

          // Batch fetch display names only for members without stored displayName
          if (uidsToFetch.isNotEmpty) {
            final displayNames = await batchFetchUserDisplayNamesByUids(
              firestore,
              uidsToFetch,
            );

            // Update members list with display names
            for (var member in membersList) {
              final uid = member['uid'] as String? ?? '';
              if (uid.isNotEmpty &&
                  displayNames.containsKey(uid) &&
                  (member['displayName'] == null ||
                      member['displayName'].isEmpty)) {
                member['displayName'] = displayNames[uid];
              }
            }
          }

          if (mounted) {
            setState(() {
              members = membersList;
              isLoading = false;
            });
          }
        });
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
              .collection('members')
              .get();

      List<Map<String, dynamic>> membersList = [];
      List<String> uidsToFetch = [];

      for (var doc in membersSnapshot.docs) {
        Map<String, dynamic> memberData = doc.data() as Map<String, dynamic>;
        final uid = memberData['uid'] as String? ?? '';
        final storedDisplayName = memberData['displayName'] as String?;
        membersList.add({
          'id': doc.id,
          'email': memberData['email'] ?? 'Unknown',
          'role': memberData['role'] ?? 'member',
          'uid': uid,
          'status': memberData['status'] ?? 'active',
          'displayName': storedDisplayName, // Use stored displayName first
        });

        if (memberData['uid'] == auth.currentUser?.uid ||
            memberData['email'] == auth.currentUser?.email) {
          currentUserRole = memberData['role'] ?? 'member';
        }

        // Only fetch from users collection if displayName is not stored
        if (uid.isNotEmpty &&
            (storedDisplayName == null || storedDisplayName.isEmpty)) {
          uidsToFetch.add(uid);
        }
      }

      // Batch fetch display names only for members without stored displayName
      if (uidsToFetch.isNotEmpty) {
        final displayNames = await batchFetchUserDisplayNamesByUids(
          firestore,
          uidsToFetch,
        );

        // Update members list with display names
        for (var member in membersList) {
          final uid = member['uid'] as String? ?? '';
          if (uid.isNotEmpty &&
              displayNames.containsKey(uid) &&
              (member['displayName'] == null ||
                  member['displayName'].isEmpty)) {
            member['displayName'] = displayNames[uid];
          }
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching members: $e')));
      }
    }
  }

  @override
  void dispose() {
    _membersSubscription?.cancel();
    super.dispose();
  }

  Future<void> addMember() async {
    if (memberEmailController.text.isEmpty) return;

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(memberEmailController.text)) {
      SnackBarHelper.showError(
        context,
        message: 'Please enter a valid email address',
      );
      return;
    }

    try {
      setState(() {
        memberOperationInProgress = true;
        isAddingMember = true;
      });

      // Try to find the user's UID by email
      String email = memberEmailController.text.trim();
      String? uid;
      try {
        final methods = await auth.fetchSignInMethodsForEmail(email);
        if (methods.isNotEmpty) {
          // User exists, try to get UID from Firestore users collection if you have one
          // (Assume users are stored in a 'users' collection with UID as doc ID and email field)
          final userQuery =
              await firestore
                  .collection('users')
                  .where('email', isEqualTo: email)
                  .limit(1)
                  .get();
          if (userQuery.docs.isNotEmpty) {
            uid = userQuery.docs.first.id;
          }
        }
      } catch (e) {
        // Ignore errors, fallback to email as ID
      }
      // Get display name for this email if available
      String? memberDisplayName;
      try {
        memberDisplayName = await fetchUserDisplayNameByEmail(firestore, email);
      } catch (e) {
        // Ignore errors, displayName will be null
      }

      // Use UID if found, otherwise fallback to email
      String docId = uid ?? email;
      await firestore
          .collection('organisations')
          .doc(widget.organisationId)
          .collection('members')
          .doc(docId)
          .set({
            'email': email,
            'role': 'member',
            'displayName': memberDisplayName,
            'status': 'pending',
            'addedAt': FieldValue.serverTimestamp(),
            'addedBy': auth.currentUser?.uid,
            if (uid != null) 'uid': uid,
          });

      // Create an invite document for this member
      final inviteRef =
          firestore
              .collection('organisations')
              .doc(widget.organisationId)
              .collection('invites')
              .doc();
      await inviteRef.set({
        'orgId': widget.organisationId,
        'orgName': widget.organisationName,
        'toEmail': email.toLowerCase(),
        'toEmailLower': email.toLowerCase(),
        if (uid != null) 'toUid': uid,
        'fromUid': auth.currentUser?.uid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'memberDocId': docId,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding member: $e')));
      }
    }
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
    context.read<OrganisationBloc>().add(
      ChangeMemberRoleEvent(memberId: memberId, newRole: newRole),
    );
  }

  void _showRemoveConfirmation(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Remove Member'),
            content: Text(
              'Are you sure you want to remove ${_getDisplayName(member)} from the organisation?',
            ),
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

  Future<void> _removeMember(String memberId) async {
    try {
      await firestore
          .collection('organisations')
          .doc(widget.organisationId)
          .collection('members')
          .doc(memberId)
          .delete();

      // Refresh members locally
      await fetchMembers();

      // Ask outer views to refresh organisations list
      if (mounted) {
        context.read<OrganisationsBloc>().add(FetchOrganisationsEvent());
        SnackBarHelper.showSuccess(
          context,
          message: 'Member removed successfully',
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

  bool isCurrentUser(Map<String, dynamic> member) {
    return member['uid'] == auth.currentUser?.uid ||
        member['email'] == auth.currentUser?.email;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<OrganisationsBloc, OrganisationsState>(
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
              SnackBarHelper.showSuccess(
                context,
                message: 'Member operation completed successfully',
              );
            } else if (state is OrganisationsError &&
                memberOperationInProgress) {
              setState(() {
                memberOperationInProgress = false;
                isAddingMember = false;
                isChangingRole = false;
                isRemovingMember = false;
                currentOperationId = null;
              });
              SnackBarHelper.showError(context, message: state.message);
            }
          },
        ),
        BlocListener<OrganisationBloc, OrganisationState>(
          listener: (context, state) {
            if (state is OrganisationLoaded) {
              // Refresh organisations list so other views reflect the change
              context.read<OrganisationsBloc>().add(FetchOrganisationsEvent());
              // Also reset any local operation spinners and refresh members list
              if (memberOperationInProgress) {
                setState(() {
                  memberOperationInProgress = false;
                  isAddingMember = false;
                  isChangingRole = false;
                  isRemovingMember = false;
                  currentOperationId = null;
                });
                fetchMembers();
              }
            } else if (state is OrganisationError) {
              if (memberOperationInProgress) {
                setState(() {
                  memberOperationInProgress = false;
                  isAddingMember = false;
                  isChangingRole = false;
                  isRemovingMember = false;
                  currentOperationId = null;
                });
                SnackBarHelper.showError(context, message: state.message);
              }
            }
          },
        ),
      ],
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    List<Map<String, dynamic>> teachers =
        members.where((m) => m['role'] == 'teacher').toList();
    List<Map<String, dynamic>> studentTeachers =
        members.where((m) => m['role'] == 'student_teacher').toList();
    List<Map<String, dynamic>> regularMembers =
        members.where((m) => m['role'] == 'member').toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.teacherView) ...[
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
                        icon:
                            isAddingMember
                                ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                                : Icon(Icons.add),
                        label: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 8,
                          ),
                          child:
                              isAddingMember
                                  ? Text(
                                    "Adding...",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                  : Text(
                                    "Add member",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          elevation: 0,
                        ),
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
      // physics: NeverScrollableScrollPhysics(),
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
              ).colorScheme.primary.withValues(alpha: 0.1),
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
            subtitle:
                (member['displayName'] != null &&
                        (member['displayName'] as String).isNotEmpty)
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
                if ((member['status'] ?? 'active') == 'pending') ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(
                      "Pending",
                      style: TextStyle(color: Colors.orange.shade900),
                    ),
                    backgroundColor: Colors.orange.shade100,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 8),
                  if (widget.teacherView)
                    OutlinedButton.icon(
                      onPressed:
                          (isRetractingInvite &&
                                  currentOperationId == member['id'])
                              ? null
                              : () => _retractInvite(member),
                      icon:
                          (isRetractingInvite &&
                                  currentOperationId == member['id'])
                              ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              )
                              : Icon(Icons.undo, size: 16),
                      label: Text(
                        (isRetractingInvite &&
                                currentOperationId == member['id'])
                            ? 'Retracting...'
                            : 'Retract invite',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
                if (isCurrentUser(member)) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: Text("You", style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.green.shade400,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
                if (!isCurrentUser(member) &&
                    widget.teacherView &&
                    (member['status'] ?? 'active') != 'pending' &&
                    !(currentUserRole == 'student_teacher' &&
                        member['role'] == 'teacher')) ...[
                  PopupMenuButton<String>(
                    icon:
                        (isChangingRole && currentOperationId == member['id'])
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
                        ...availableRoles.map(
                          (role) => PopupMenuItem<String>(
                            value: role,
                            child:
                                (isChangingRole &&
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
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Changing to ${_getRoleDisplayName(role)}...',
                                        ),
                                      ],
                                    )
                                    : Text(
                                      'Change to ${_getRoleDisplayName(role)}',
                                    ),
                          ),
                        ),
                        if (_canRemoveMember(memberRole))
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
                                      'Remove from organisation',
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

  Future<void> _retractInvite(Map<String, dynamic> member) async {
    try {
      setState(() {
        isRetractingInvite = true;
        currentOperationId = member['id'] as String?;
      });

      // Find the pending invite associated with this member by memberDocId
      final invitesSnap =
          await firestore
              .collection('organisations')
              .doc(widget.organisationId)
              .collection('invites')
              .where('memberDocId', isEqualTo: member['id'])
              .where('status', isEqualTo: 'pending')
              .limit(1)
              .get();

      if (invitesSnap.docs.isNotEmpty) {
        await invitesSnap.docs.first.reference.delete();
      } else {
        // Fallback: attempt to find by toEmail if member was created with email docId
        final email = (member['email'] as String?)?.toLowerCase();
        if (email != null && email.isNotEmpty) {
          final byEmailSnap =
              await firestore
                  .collection('organisations')
                  .doc(widget.organisationId)
                  .collection('invites')
                  .where('toEmail', isEqualTo: email)
                  .where('status', isEqualTo: 'pending')
                  .limit(1)
                  .get();
          if (byEmailSnap.docs.isNotEmpty) {
            await byEmailSnap.docs.first.reference.delete();
          }
        }
      }

      // Remove the pending member document
      await firestore
          .collection('organisations')
          .doc(widget.organisationId)
          .collection('members')
          .doc(member['id'])
          .delete();

      await fetchMembers();

      if (mounted) {
        SnackBarHelper.showSuccess(context, message: 'Invite retracted');
      }
    } catch (e) {
      // Log for debugging
      // ignore: avoid_print
      print('Error retracting invite for member ${member['id']}: $e');
      if (mounted) {
        SnackBarHelper.showError(
          context,
          message: 'Error retracting invite: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isRetractingInvite = false;
          currentOperationId = null;
        });
      }
    }
  }

  String _getDisplayName(Map<String, dynamic> member) {
    final displayName = member['displayName'] as String?;
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    return member['email'] as String? ?? 'Unknown';
  }

  String _getInitials(Map<String, dynamic> member) {
    final displayName = member['displayName'] as String?;
    final email = member['email'] as String? ?? '';

    if (displayName != null && displayName.isNotEmpty) {
      // Get first letter of first name and first letter of last name
      final parts = displayName.trim().split(' ');
      if (parts.length >= 2) {
        return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
      } else if (parts.isNotEmpty) {
        return parts[0][0].toUpperCase();
      }
    }

    // Fallback to email
    if (email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return '?';
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
