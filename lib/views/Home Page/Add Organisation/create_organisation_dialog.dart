import 'package:accelerator_squared/blocs/organisations/organisations_bloc.dart';
import 'package:accelerator_squared/blocs/user/user_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:accelerator_squared/util/util.dart';

class CreateOrganisationDialog extends StatefulWidget {
  const CreateOrganisationDialog({super.key});

  @override
  State<CreateOrganisationDialog> createState() =>
      _CreateOrganisationDialogState();
}

class _CreateOrganisationDialogState extends State<CreateOrganisationDialog> {
  TextEditingController orgNameController = TextEditingController();
  TextEditingController orgDescController = TextEditingController();
  TextEditingController emailAddingController = TextEditingController();
  List<Map<String, dynamic>> orgMemberList = []; // Changed to store email and displayName
  bool isCreating = false;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

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
                'Organisation "${orgNameController.text}" created successfully',
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
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SizedBox(
          width: MediaQuery.of(context).size.width / 2.5,
          height: MediaQuery.of(context).size.height / 1.3,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                // Header with icon
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.business_rounded,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(height: 24),

                // Title
                Text(
                  "Create New Organisation",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 32),

                // Organisation name input
                TextField(
                  controller: orgNameController,
                  decoration: InputDecoration(
                    label: Text("Organisation Name"),
                    hintText: "Enter organisation name",
                    prefixIcon: Icon(Icons.business_rounded),
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

                // Organisation description input
                TextField(
                  controller: orgDescController,
                  minLines: 3,
                  maxLines: 4,
                  decoration: InputDecoration(
                    label: Text("Organisation Description"),
                    hintText: "Enter organisation description",
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

                // Google Drive integration
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
                      "Add Members",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
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
                    ),
                    SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
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
                      onPressed: () async {
                        final email = emailAddingController.text.trim();
                        if (email.isNotEmpty) {
                          // Prevent adding self
                          if (email == userState.email) {
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
                                      Text("Cannot Add Yourself"),
                                    ],
                                  ),
                                  content: Text(
                                    "You will automatically be added as the creator. Please do not add your own email.",
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

                          // Check if email is already in list
                          if (orgMemberList.any((m) => 
                              (m['email'] as String).toLowerCase() == email.toLowerCase())) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('This email is already in the list'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          // Look up display name for this email
                          String? displayName;
                          try {
                            displayName = await fetchUserDisplayNameByEmail(
                              firestore,
                              email,
                            );
                          } catch (e) {
                            // Continue even if lookup fails
                            print('Error fetching display name for $email: $e');
                          }

                          setState(() {
                            orgMemberList.add({
                              'email': email,
                              'displayName': displayName,
                            });
                          });
                          emailAddingController.clear();
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
                      label: Text("Invite"),
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
                      orgMemberList.isNotEmpty
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
                                      _getInitials(orgMemberList[index]),
                                      style: TextStyle(
                                        color:
                                            Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    _getDisplayName(orgMemberList[index]),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: (orgMemberList[index]['displayName'] != null &&
                                           (orgMemberList[index]['displayName'] as String).isNotEmpty)
                                      ? Text(
                                          orgMemberList[index]['email'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        )
                                      : null,
                                  trailing: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        orgMemberList.removeAt(index);
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
                            itemCount: orgMemberList.length,
                          )
                          : Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
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
                SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
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
                                  setState(() {
                                    isCreating = true;
                                  });
                                  context.read<OrganisationsBloc>().add(
                                    CreateOrganisationEvent(
                                      name: orgNameController.text,
                                      description: orgDescController.text,
                                      memberEmails: orgMemberList
                                          .map((m) => m['email'] as String)
                                          .toList(),
                                    ),
                                  );
                                },
                        child:
                            isCreating
                                ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                                : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_business_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      "Create Organisation",
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
      ),
    );
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
}
