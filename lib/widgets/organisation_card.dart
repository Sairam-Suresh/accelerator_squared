import 'dart:math';

import 'package:accelerator_squared/icons.dart';
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
  var random = Random();

  var randomIcon1 = Icons.error;
  var randomIcon2 = Icons.error;
  var randomIcon3 = Icons.error;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    var shuffledIcons = List.from(materialIcons)..shuffle(random);
    randomIcon1 = shuffledIcons[0];
    randomIcon2 = shuffledIcons[1];
    randomIcon3 = shuffledIcons[2];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: InkWell(
        borderRadius: BorderRadius.circular(16), // Same as Card
        onTap: () {
          // Handle card tap
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ProjectPage(orgName: widget.organisation.name),
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
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Opacity(opacity: 0.4, child: Icon(randomIcon1, size: 80)),
                  SizedBox(width: 40),
                  Opacity(opacity: 0.4, child: Icon(randomIcon2, size: 80)),
                  SizedBox(width: 40),
                  Opacity(opacity: 0.4, child: Icon(randomIcon3, size: 80)),
                ],
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
