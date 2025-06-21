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
                      orgName: widget.organisation.name,
                      orgDescription: widget.organisation.description,
                      // orgDescription: widget.organisation.description,
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
                    Text("56 members", style: TextStyle(fontSize: 14)),
                    VerticalDivider(),
                    Text("9 projects", style: TextStyle(fontSize: 14)),
                  ],
                ),
                Spacer(),
                Text("Status: Teacher", style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
