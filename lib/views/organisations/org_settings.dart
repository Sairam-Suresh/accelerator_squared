import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:accelerator_squared/blocs/organisations/organisations_bloc.dart';

class OrganisationSettingsDialog extends StatefulWidget {
  final String organisationId;
  final String orgName;
  final String orgDescription;
  final String joinCode;
  final bool isTeacher;

  const OrganisationSettingsDialog({
    super.key,
    required this.organisationId,
    required this.orgName,
    required this.orgDescription,
    required this.joinCode,
    required this.isTeacher,
  });

  @override
  State<OrganisationSettingsDialog> createState() => _OrganisationSettingsDialogState();
}

class _OrganisationSettingsDialogState extends State<OrganisationSettingsDialog> {
  late TextEditingController nameFieldController;
  late TextEditingController descriptionFieldController;
  late String currentJoinCode;
  bool editingName = false;
  bool editingDescription = false;

  @override
  void initState() {
    super.initState();
    nameFieldController = TextEditingController(text: widget.orgName);
    descriptionFieldController = TextEditingController(text: widget.orgDescription);
    currentJoinCode = widget.joinCode;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrganisationsBloc, OrganisationsState>(
      listener: (context, state) {
        if (state is OrganisationsLoaded) {
          final updatedOrg = state.organisations
              .where((org) => org.id == widget.organisationId)
              .firstOrNull;
          if (updatedOrg != null && mounted) {
            setState(() {
              currentJoinCode = updatedOrg.joinCode;
            });
            // Check if this was an organisation update
            if (updatedOrg.name != widget.orgName || updatedOrg.description != widget.orgDescription) {
              // Organisation was updated successfully
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Organisation updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else if (updatedOrg == null && mounted) {
            // User is no longer in this organisation, navigate to home
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Left organisation successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else if (state is OrganisationsError) {
          // Check if this is the "last teacher" error
          if (state.message.contains("last teacher")) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Cannot Leave Organisation'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You are the last teacher in this organisation.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'To leave the organisation, you must first assign another member as a teacher.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('OK'),
                  ),
                ],
              ),
            );
          } else {
            // Show other errors as snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: AlertDialog(
        title: Row(
          children: [
            Icon(Icons.business, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Organisation Info",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
              ),
            ),
            if (widget.isTeacher && (editingName || editingDescription))
              IconButton(
                onPressed: () {
                  // Save changes
                  context.read<OrganisationsBloc>().add(
                    UpdateOrganisationEvent(
                      organisationId: widget.organisationId,
                      name: nameFieldController.text,
                      description: descriptionFieldController.text,
                    ),
                  );
                  setState(() {
                    editingName = false;
                    editingDescription = false;
                  });
                  // Dismiss the dialog
                  Navigator.of(context).pop();
                },
                icon: Icon(Icons.save, color: Theme.of(context).colorScheme.primary),
                tooltip: "Save changes",
              ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width / 2.5,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Organisation Name
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.label, color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text(
                              "Organisation Name",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                            Spacer(),
                            if (widget.isTeacher)
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    editingName = true;
                                  });
                                },
                                icon: Icon(Icons.edit, size: 20),
                                tooltip: "Edit name",
                              ),
                          ],
                        ),
                        SizedBox(height: 8),
                        editingName
                            ? Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: nameFieldController,
                                      decoration: InputDecoration(
                                        hintText: "Enter organisation name",
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        editingName = false;
                                        nameFieldController.text = widget.orgName;
                                      });
                                    },
                                    icon: Icon(Icons.close, color: Colors.red),
                                    tooltip: "Cancel",
                                  ),
                                ],
                              )
                            : Text(
                                widget.orgName,
                                style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                              ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Description
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.description, color: Theme.of(context).colorScheme.primary),
                            SizedBox(width: 8),
                            Text(
                              "Description",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                            Spacer(),
                            if (widget.isTeacher)
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    editingDescription = true;
                                  });
                                },
                                icon: Icon(Icons.edit, size: 20),
                                tooltip: "Edit description",
                              ),
                          ],
                        ),
                        SizedBox(height: 8),
                        editingDescription
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: descriptionFieldController,
                                          minLines: 3,
                                          maxLines: 5,
                                          decoration: InputDecoration(
                                            hintText: "Enter organisation description",
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            editingDescription = false;
                                            descriptionFieldController.text = widget.orgDescription;
                                          });
                                        },
                                        icon: Icon(Icons.close, color: Colors.red),
                                        tooltip: "Cancel",
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Text(
                                widget.orgDescription.isEmpty ? "No description provided" : widget.orgDescription,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: widget.orgDescription.isEmpty 
                                      ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Join Code (for teachers and student teachers)
                if (widget.isTeacher)
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.key, color: Theme.of(context).colorScheme.primary),
                              SizedBox(width: 8),
                              Text(
                                "Join Code",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                              Spacer(),
                              IconButton(
                                onPressed: () {
                                  context.read<OrganisationsBloc>().add(
                                    RefreshJoinCodeEvent(
                                      organisationId: widget.organisationId,
                                    ),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Join code refreshed!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                icon: Icon(Icons.refresh, size: 20),
                                tooltip: "Refresh join code",
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                if (currentJoinCode.isNotEmpty) {
                                  Clipboard.setData(ClipboardData(text: currentJoinCode));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Join code copied to clipboard!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Row(
                                children: [
                                  Text(
                                    currentJoinCode.isNotEmpty ? currentJoinCode : 'No join code',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                      letterSpacing: 2,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Icon(
                                    Icons.copy,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Share this code with others to let them join your organisation",
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Leave Organisation Section
                SizedBox(height: 32),
                Divider(color: Colors.orange.withValues(alpha: 0.3)),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.exit_to_app_rounded, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            "Leave Organisation",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Leaving this organisation will remove you from all projects and member lists. You can rejoin later using the join code.",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Row(
                                  children: [
                                    Icon(Icons.exit_to_app_rounded, color: Colors.orange),
                                    SizedBox(width: 8),
                                    Text('Leave Organisation'),
                                  ],
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Are you sure you want to leave "${widget.orgName}"?',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'This will:',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    SizedBox(height: 4),
                                    Text('• Remove you from the organisation'),
                                    Text('• Remove you from all projects'),
                                    Text('• Remove your access to organisation data'),
                                    SizedBox(height: 16),
                                    Text(
                                      'You can rejoin later using the join code.',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(); // Close confirmation dialog
                                      Navigator.of(context).pop(); // Close settings dialog
                                      context.read<OrganisationsBloc>().add(
                                        LeaveOrganisationEvent(
                                          organisationId: widget.organisationId,
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text('Leave Organisation'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: Icon(Icons.exit_to_app_rounded),
                          label: Text('Leave Organisation'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Delete Organisation Section (only for teachers)
                if (widget.isTeacher) ...[
                  SizedBox(height: 32),
                  Divider(color: Colors.red.withValues(alpha: 0.3)),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              "Danger Zone",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Deleting this organisation will permanently remove all projects, members, and data. This action cannot be undone.",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Row(
                                    children: [
                                      Icon(Icons.delete_forever, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete Organisation'),
                                    ],
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Are you absolutely sure you want to delete "${widget.orgName}"?',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'This will permanently delete:',
                                        style: TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      SizedBox(height: 4),
                                      Text('• All projects and their data'),
                                      Text('• All project requests'),
                                      Text('• All member information'),
                                      Text('• The organisation itself'),
                                      SizedBox(height: 16),
                                      Text(
                                        'This action cannot be undone.',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(); // Close confirmation dialog
                                        Navigator.of(context).pop(); // Close settings dialog
                                        context.read<OrganisationsBloc>().add(
                                          DeleteOrganisationEvent(
                                            organisationId: widget.organisationId,
                                          ),
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Organisation deleted successfully'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text('Delete Organisation'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: Icon(Icons.delete_forever),
                            label: Text('Delete Organisation'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
