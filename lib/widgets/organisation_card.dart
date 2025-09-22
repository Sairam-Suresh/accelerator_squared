import 'package:accelerator_squared/models/organisation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:accelerator_squared/blocs/organisations/organisations_bloc.dart';
import 'package:accelerator_squared/blocs/organisation/organisation_bloc.dart';
import 'package:accelerator_squared/views/organisations/org_settings.dart';

class OrganisationCard extends StatefulWidget {
  final Organisation organisation;
  final VoidCallback? onTap;

  const OrganisationCard({super.key, required this.organisation, this.onTap});

  @override
  State<OrganisationCard> createState() => _OrganisationCardState();
}

class _OrganisationCardState extends State<OrganisationCard> {
  bool isLeaving = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrganisationsBloc, OrganisationsState>(
      listener: (context, state) {
        if (state is OrganisationsError) {
          if (isLeaving) {
            setState(() {
              isLeaving = false;
            });
          }
          // Check if this is the "last teacher" error
          if (state.message.contains("last teacher")) {
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
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
        } else if (state is OrganisationsLoaded) {
          if (isLeaving) {
            setState(() {
              isLeaving = false;
            });
          }
          // Check if user is no longer in this organisation
          final updatedOrg =
              state.organisations
                  .where((org) => org.id == widget.organisation.id)
                  .firstOrNull;
          if (updatedOrg == null && mounted) {
            // User is no longer in this organisation, navigate to home
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (route) => false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Left organisation successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Transform.scale(
          scale: 1.02,
          child: Card(
            elevation: 8.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.business,
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.organisation.name,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.organisation.memberCount} members',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                            size: 20,
                          ),
                          tooltip: 'More options',
                          onSelected: (value) {
                            if (value == 'info') {
                              _showOrgInfoDialog(context);
                            } else if (value == 'leave') {
                              _showLeaveConfirmation(context);
                            }
                          },
                          itemBuilder:
                              (context) => [
                                PopupMenuItem<String>(
                                  value: 'info',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Information',
                                        style: TextStyle(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'leave',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.exit_to_app_rounded,
                                        color: Colors.orange,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Leave Organisation',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                        ),
                      ],
                    ),
                    if (widget.organisation.description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        widget.organisation.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getRoleColor().withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getRoleColor().withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _getRoleDisplayText(),
                            style: TextStyle(
                              color: _getRoleColor(),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${widget.organisation.projects.length} projects',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getRoleColor() {
    switch (widget.organisation.userRole.toLowerCase()) {
      case 'teacher':
        return Colors.blue;
      case 'student_teacher':
        return Colors.orange;
      case 'member':
      default:
        return Colors.grey;
    }
  }

  String _getRoleDisplayText() {
    switch (widget.organisation.userRole.toLowerCase()) {
      case 'teacher':
        return 'Teacher';
      case 'student_teacher':
        return 'Student Teacher';
      case 'member':
      default:
        return 'Member';
    }
  }

  void _showOrgInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return BlocProvider<OrganisationBloc>(
          create:
              (_) => OrganisationBloc(
                organisationId: widget.organisation.id,
                initialState: widget.organisation,
              ),
          child: OrganisationSettingsDialog(
            orgDescription: widget.organisation.description,
            orgName: widget.organisation.name,
            isTeacher: widget.organisation.userRole == 'teacher',
            organisationId: widget.organisation.id,
            joinCode: widget.organisation.joinCode,
          ),
        );
      },
    );
  }

  void _showLeaveConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
                  'Are you sure you want to leave "${widget.organisation.name}"?',
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
                onPressed:
                    isLeaving
                        ? null
                        : () {
                          setState(() {
                            isLeaving = true;
                          });
                          Navigator.of(
                            context,
                          ).pop(); // Close confirmation dialog
                          context.read<OrganisationsBloc>().add(
                            LeaveOrganisationEvent(
                              organisationId: widget.organisation.id,
                            ),
                          );
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child:
                    isLeaving
                        ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : Text('Leave Organisation'),
              ),
            ],
          ),
    );
  }
}
