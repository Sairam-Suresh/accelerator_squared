import 'package:accelerator_squared/models/organisation.dart';
import 'package:accelerator_squared/views/Project/project_page.dart';
import 'package:flutter/material.dart';

class OrganisationCard extends StatefulWidget {
  const OrganisationCard({super.key, required this.organisation});

  final Organisation organisation;

  @override
  State<OrganisationCard> createState() => _OrganisationCardState();
}

class _OrganisationCardState extends State<OrganisationCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),

        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withAlpha(175),
            blurRadius: 5,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(16), // Same as Card
          onTap: () {
            // Handle card tap
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ProjectPage(
                      organisationId: widget.organisation.id,
                      orgName: widget.organisation.name,
                      orgDescription: widget.organisation.description,
                      projects: widget.organisation.projects,
                      projectRequests: widget.organisation.projectRequests,
                      userRole: widget.organisation.userRole,
                    ),
              ),
            );
          },
          splashFactory: InkSparkle.splashFactory,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  widget.organisation.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.organisation.description,
                  style: const TextStyle(fontSize: 18),
                ),
                SizedBox(height: 10),
                Divider(thickness: 2),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text("${widget.organisation.memberCount} members", style: TextStyle(fontSize: 14)),
                    VerticalDivider(),
                    Text("${widget.organisation.projects.length} projects", style: TextStyle(fontSize: 14)),
                  ],
                ),
                Spacer(),
                Text("Status: ${_getRoleDisplayName(widget.organisation.userRole)}", style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
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
}
