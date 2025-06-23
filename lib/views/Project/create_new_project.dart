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
  List<Map<String, dynamic>> organisationMembers = [];
  bool isCreating = false;

  @override
  void initState() {
    super.initState();
    fetchOrganisationMembers();
  }

  Future<void> fetchOrganisationMembers() async {
    try {
      QuerySnapshot membersSnapshot =
          await FirebaseFirestore.instance
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
        organisationMembers = members;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching organisation members: $e')),
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

  @override
  Widget build(BuildContext context) {
    var userState = context.read<UserBloc>().state as UserLoggedIn;

    return BlocListener<OrganisationsBloc, OrganisationsState>(
      listener: (context, state) {
        if (state is OrganisationsLoaded && isCreating) {
          setState(() {
            isCreating = false;
          });
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isTeacher
                    ? 'Project created successfully'
                    : 'Project request submitted successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is OrganisationsError && isCreating) {
          setState(() {
            isCreating = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
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
                                setState(() {
                                  memberEmailsList.add(email);
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
                                          child: Icon(
                                            Icons.person_rounded,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                          ),
                                        ),
                                        title: Text(
                                          memberEmailsList[index],
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        subtitle: Text(
                                          isTeacher(memberEmailsList[index])
                                              ? "Teacher (cannot be added)"
                                              : "Member",
                                          style: TextStyle(
                                            color:
                                                isTeacher(
                                                      memberEmailsList[index],
                                                    )
                                                    ? Colors.red
                                                    : Colors.grey,
                                          ),
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
                                setState(() {
                                  memberEmailsList.add(email);
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
                                          child: Icon(
                                            Icons.person_rounded,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                          ),
                                        ),
                                        title: Text(
                                          memberEmailsList[index],
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        subtitle: Text(
                                          isTeacher(memberEmailsList[index])
                                              ? "Teacher (cannot be added)"
                                              : "Member",
                                          style: TextStyle(
                                            color:
                                                isTeacher(
                                                      memberEmailsList[index],
                                                    )
                                                    ? Colors.red
                                                    : Colors.grey,
                                          ),
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
                                                (email) => !isTeacher(email),
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
                                          context.read<OrganisationsBloc>().add(
                                            CreateProjectEvent(
                                              organisationId:
                                                  widget.organisationId,
                                              title: projectNameController.text,
                                              description:
                                                  descriptionController.text,
                                              memberEmails: List<String>.from(
                                                memberEmailsList,
                                              ),
                                            ),
                                          );
                                        } else {
                                          context.read<OrganisationsBloc>().add(
                                            SubmitProjectRequestEvent(
                                              organisationId:
                                                  widget.organisationId,
                                              title: projectNameController.text,
                                              description:
                                                  descriptionController.text,
                                              memberEmails: List<String>.from(
                                                memberEmailsList,
                                              ),
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
