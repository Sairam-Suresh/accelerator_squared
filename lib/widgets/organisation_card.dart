import 'package:accelerator_squared/models/organisation.dart';
import 'package:accelerator_squared/views/Project/project_page.dart';
import 'package:flutter/material.dart';

class OrganisationCard extends StatelessWidget {
  const OrganisationCard({super.key, required this.organisation});

  final Organisation organisation;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: InkWell(
        borderRadius: BorderRadius.circular(16), // Same as Card
        onTap: () {
          // Handle card tap
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectPage(orgName: organisation.name),
            ),
          );
        },
        splashFactory: InkSparkle.splashFactory,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                organisation.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                organisation.description,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
