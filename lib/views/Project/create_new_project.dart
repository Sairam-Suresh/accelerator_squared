import 'package:accelerator_squared/blocs/organisation/organisation_bloc.dart';
import 'package:accelerator_squared/blocs/user/user_bloc.dart';
import 'package:accelerator_squared/util/snackbar_helper.dart';
import 'package:accelerator_squared/util/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

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
  List<Map<String, dynamic>> memberEmailsList = []; // Changed to store email and displayName
  List<Map<String, dynamic>> organisationMembers = [];
  bool isCreating = false;
  final LayerLink _emailFieldLink = LayerLink();
  final FocusNode _emailFieldFocusNode = FocusNode();
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    projectNameController.dispose();
    descriptionController.dispose();
    emailAddingController.dispose();
    _emailFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    fetchOrganisationMembers();
  }

  Future<void> fetchOrganisationMembers() async {
    try {
      QuerySnapshot membersSnapshot =
          await firestore
              .collection('organisations')
              .doc(widget.organisationId)
              .collection('members')
              .get();

      List<Map<String, dynamic>> members = [];
      List<String> uidsToFetch = [];
      
      for (var doc in membersSnapshot.docs) {
        Map<String, dynamic> memberData = doc.data() as Map<String, dynamic>;
        final uid = memberData['uid'] as String? ?? '';
        members.add({
          'email': memberData['email'] ?? '',
          'role': memberData['role'] ?? 'member',
          'uid': uid,
          'displayName': null, // Will be fetched below
        });

        if (uid.isNotEmpty) {
          uidsToFetch.add(uid);
        }
      }

      // Batch fetch display names
      if (uidsToFetch.isNotEmpty) {
        final displayNames = await batchFetchUserDisplayNamesByUids(
          firestore,
          uidsToFetch,
        );
        
        // Update members list with display names
        for (var member in members) {
          final uid = member['uid'] as String? ?? '';
          if (uid.isNotEmpty && displayNames.containsKey(uid)) {
            member['displayName'] = displayNames[uid];
          }
        }
      }

      setState(() {
        organisationMembers = members;
      });
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          message: 'Error fetching organisation members: $e',
        );
      }
    }
  }

  bool isTeacher(String email) {
    final member = organisationMembers.firstWhere(
      (m) => m['email'] == email,
      orElse: () => {'role': 'member'},
    );
    return member['role'] == 'teacher';
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

  void _handleAddEmail(String email, String selfEmail, StateSetter setState) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.red, size: 24),
                SizedBox(width: 8),
                Text("Invalid Email"),
              ],
            ),
            content: Text(
              "Email field cannot be empty when adding a new member.",
            ),
            actions: [
              TextButton(
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

    if (trimmed == selfEmail) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.red, size: 24),
                SizedBox(width: 8),
                Text(
                  "You will automatically be added as the creator. Please do not add your own email.",
                ),
              ],
            ),
            content: Text("You cannot add yourself as a project member."),
            actions: [
              TextButton(
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

    if (memberEmailsList.any((m) => (m['email'] as String).toLowerCase() == trimmed.toLowerCase())) {
      return;
    }

    if (isTeacher(trimmed)) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.red, size: 24),
                SizedBox(width: 8),
                Text("Cannot Add Teacher"),
              ],
            ),
            content: Text(
              "Teachers cannot be added to projects. Please add student teachers or members only.",
            ),
            actions: [
              TextButton(
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

    final found = organisationMembers.any((m) => (m['email'] ?? '') == trimmed);
    if (!found) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.red, size: 24),
                SizedBox(width: 8),
                Text("User Not Found"),
              ],
            ),
            content: Text("This email is not a member of the organisation."),
            actions: [
              TextButton(
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

    // Find the member data to get display name
    final memberData = organisationMembers.firstWhere(
      (m) => (m['email'] as String).toLowerCase() == trimmed.toLowerCase(),
      orElse: () => {'email': trimmed, 'displayName': null},
    );

    setState(() {
      memberEmailsList.add({
        'email': trimmed,
        'displayName': memberData['displayName'],
      });
      emailAddingController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    var userState = context.read<UserBloc>().state as UserLoggedIn;

    return BlocListener<OrganisationBloc, OrganisationState>(
      listener: (context, state) {
        if (state is OrganisationLoaded && isCreating) {
          setState(() {
            isCreating = false;
          });
          Navigator.of(context).pop();
          SnackBarHelper.showSuccess(
            context,
            message:
                widget.isTeacher
                    ? 'Project created successfully'
                    : 'Project request submitted successfully',
          );
        } else if (state is OrganisationError && isCreating) {
          setState(() {
            isCreating = false;
          });
          SnackBarHelper.showError(context, message: state.message);
        }
      },
      child: StatefulBuilder(
        builder: (context, StateSetter setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              height: MediaQuery.of(context).size.height / 1.3,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Header with icon
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        widget.isTeacher
                            ? Icons.add_task_rounded
                            : Icons.request_page_rounded,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: 24),

                    // Title
                    Text(
                      widget.isTeacher
                          ? "Create New Project"
                          : "Submit Project Request",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 8),

                    // Subtitle
                    Text(
                      widget.isTeacher
                          ? "Create a new project for your organisation"
                          : "Submit a project request for approval",
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32),

                    // Project name input
                    TextField(
                      controller: projectNameController,
                      decoration: InputDecoration(
                        label: Text("Project Name"),
                        hintText: "Enter project name",
                        prefixIcon: Icon(Icons.folder_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Project description input
                    TextField(
                      controller: descriptionController,
                      minLines: 3,
                      maxLines: 4,
                      decoration: InputDecoration(
                        label: Text("Project Description"),
                        hintText: "Enter project description (optional)",
                        prefixIcon: Icon(Icons.description_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.3),
                      ),
                    ),

                    if (widget.isTeacher) ...[
                      SizedBox(height: 24),

                      // Member management section
                      Row(
                        children: [
                          Icon(
                            Icons.people_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Add Team Members",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      // Info card
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "You must add at least 1 non-teacher member to the project. Teachers cannot be added to projects.",
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),

                      // Add member input row
                      Row(
                        children: [
                          Expanded(
                            child: CompositedTransformTarget(
                              link: _emailFieldLink,
                              child: RawAutocomplete<String>(
                                textEditingController: emailAddingController,
                                focusNode: _emailFieldFocusNode,
                                optionsBuilder: (TextEditingValue value) {
                                  final query = value.text.toLowerCase();
                                  final filteredMembers =
                                      organisationMembers
                                          .where(
                                            (m) =>
                                                (m['role'] ?? '') != 'teacher' &&
                                                !memberEmailsList.any(
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
                                  _handleAddEmail(
                                    opt,
                                    userState.email,
                                    setState,
                                  );
                                  _emailFieldFocusNode.unfocus();
                                  emailAddingController.clear();
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
                          SizedBox(width: 12),
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
                            onPressed: () {
                              _handleAddEmail(
                                emailAddingController.text,
                                userState.email,
                                setState,
                              );
                            },
                            icon: Icon(Icons.add_rounded, size: 20),
                            label: Text("Add"),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Members list
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height / 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            memberEmailsList.isNotEmpty
                                ? ListView.builder(
                                  padding: EdgeInsets.all(8),
                                  shrinkWrap: true,
                                  itemBuilder: (context, index) {
                                    return Card(
                                      margin: EdgeInsets.symmetric(vertical: 4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primaryContainer,
                                          child: Text(
                                            _getInitials(memberEmailsList[index]),
                                            style: TextStyle(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          _getDisplayName(memberEmailsList[index]),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if ((memberEmailsList[index]['displayName'] as String?) != null &&
                                                (memberEmailsList[index]['displayName'] as String).isNotEmpty)
                                              Text(
                                                memberEmailsList[index]['email'],
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context)
                                                      .colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            Text(
                                              isTeacher(memberEmailsList[index]['email'] as String)
                                                  ? "Teacher (cannot be added)"
                                                  : "Member",
                                              style: TextStyle(
                                                color:
                                                    isTeacher(
                                                          memberEmailsList[index]['email'] as String,
                                                        )
                                                        ? Colors.red
                                                        : Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              memberEmailsList.removeAt(index);
                                            });
                                          },
                                          icon: Icon(
                                            Icons.remove_circle_outline_rounded,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  itemCount: memberEmailsList.length,
                                )
                                : Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.people_outline_rounded,
                                          size: 48,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "No members added yet",
                                          style: TextStyle(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                      ),
                    ] else ...[
                      SizedBox(height: 24),

                      // Member management section
                      Row(
                        children: [
                          Icon(
                            Icons.people_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Add Team Members",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      // Info card
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Teachers cannot be added to projects. Please add student teachers or members only.",
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),

                      // Add member input row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: emailAddingController,
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
                                        Theme.of(context).colorScheme.outline,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
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
                            onPressed: () {
                              final email = emailAddingController.text.trim();
                              if (email.isNotEmpty) {
                                // Prevent adding self
                                if (email == userState.email) {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        title: Row(
                                          children: [
                                            Icon(
                                              Icons.error_outline_rounded,
                                              color: Colors.red,
                                              size: 24,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              "You will automatically be added as the creator. Please do not add your own email.",
                                            ),
                                          ],
                                        ),
                                        content: Text(
                                          "You cannot add yourself as a project member.",
                                        ),
                                        actions: [
                                          TextButton(
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
                                // Check if the email belongs to a teacher
                                if (isTeacher(email)) {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        title: Row(
                                          children: [
                                            Icon(
                                              Icons.error_outline_rounded,
                                              color: Colors.red,
                                              size: 24,
                                            ),
                                            SizedBox(width: 8),
                                            Text("Cannot Add Teacher"),
                                          ],
                                        ),
                                        content: Text(
                                          "Teachers cannot be added to projects. Please add student teachers or members only.",
                                        ),
                                        actions: [
                                          TextButton(
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
                                // Check if the email exists in the organisation
                                final found = organisationMembers.any(
                                  (m) => m['email'] == email,
                                );
                                if (!found) {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        title: Row(
                                          children: [
                                            Icon(
                                              Icons.error_outline_rounded,
                                              color: Colors.red,
                                              size: 24,
                                            ),
                                            SizedBox(width: 8),
                                            Text("User Not Found"),
                                          ],
                                        ),
                                        content: Text(
                                          "This email is not a member of the organisation.",
                                        ),
                                        actions: [
                                          TextButton(
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
                                
                                // Find the member data to get display name
                                final memberData = organisationMembers.firstWhere(
                                  (m) => (m['email'] as String).toLowerCase() == email.toLowerCase(),
                                  orElse: () => {'email': email, 'displayName': null},
                                );

                                setState(() {
                                  memberEmailsList.add({
                                    'email': email,
                                    'displayName': memberData['displayName'],
                                  });
                                  emailAddingController.clear();
                                });
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline_rounded,
                                            color: Colors.red,
                                            size: 24,
                                          ),
                                          SizedBox(width: 8),
                                          Text("Invalid Email"),
                                        ],
                                      ),
                                      content: Text(
                                        "Email field cannot be empty when adding a new member.",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text("OK"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            },
                            icon: Icon(Icons.add_rounded, size: 20),
                            label: Text("Add"),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Members list
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height / 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            memberEmailsList.isNotEmpty
                                ? ListView.builder(
                                  padding: EdgeInsets.all(8),
                                  shrinkWrap: true,
                                  itemBuilder: (context, index) {
                                    return Card(
                                      margin: EdgeInsets.symmetric(vertical: 4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primaryContainer,
                                          child: Text(
                                            _getInitials(memberEmailsList[index]),
                                            style: TextStyle(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          _getDisplayName(memberEmailsList[index]),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if ((memberEmailsList[index]['displayName'] as String?) != null &&
                                                (memberEmailsList[index]['displayName'] as String).isNotEmpty)
                                              Text(
                                                memberEmailsList[index]['email'],
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context)
                                                      .colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            Text(
                                              isTeacher(memberEmailsList[index]['email'] as String)
                                                  ? "Teacher (cannot be added)"
                                                  : "Member",
                                              style: TextStyle(
                                                color:
                                                    isTeacher(
                                                          memberEmailsList[index]['email'] as String,
                                                        )
                                                        ? Colors.red
                                                        : Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              memberEmailsList.removeAt(index);
                                            });
                                          },
                                          icon: Icon(
                                            Icons.remove_circle_outline_rounded,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  itemCount: memberEmailsList.length,
                                )
                                : Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.people_outline_rounded,
                                          size: 48,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "No members added yet",
                                          style: TextStyle(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                      ),
                    ],

                    SizedBox(height: 24),

                    // Google Drive integration

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed:
                                isCreating
                                    ? null
                                    : () {
                                      Navigator.of(context).pop();
                                    },
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed:
                                isCreating
                                    ? null
                                    : () {
                                      // create project or submit request
                                      if (projectNameController
                                          .text
                                          .isNotEmpty) {
                                        // For teachers, validate that at least 1 non-teacher member is added
                                        if (widget.isTeacher) {
                                          bool hasNonTeacherMember =
                                              memberEmailsList.any(
                                                (m) => !isTeacher(m['email'] as String),
                                              );
                                          if (!hasNonTeacherMember) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'You must add at least 1 non-teacher member to the project',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            return;
                                          }
                                        }

                                        setState(() {
                                          isCreating = true;
                                        });
                                        if (widget.isTeacher) {
                                          context.read<OrganisationBloc>().add(
                                            CreateProjectEvent(
                                              title: projectNameController.text,
                                              description:
                                                  descriptionController.text,
                                              memberEmails: memberEmailsList
                                                  .map((m) => m['email'] as String)
                                                  .toList(),
                                            ),
                                          );
                                        } else {
                                          context.read<OrganisationBloc>().add(
                                            SubmitProjectRequestEvent(
                                              title: projectNameController.text,
                                              description:
                                                  descriptionController.text,
                                              memberEmails: memberEmailsList
                                                  .map((m) => m['email'] as String)
                                                  .toList(),
                                            ),
                                          );
                                        }
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Please enter a project title',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                            child:
                                isCreating
                                    ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Theme.of(
                                                context,
                                              ).colorScheme.onPrimary,
                                            ),
                                      ),
                                    )
                                    : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          widget.isTeacher
                                              ? Icons.add_rounded
                                              : Icons.send_rounded,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          widget.isTeacher
                                              ? "Create Project"
                                              : "Submit Request",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
