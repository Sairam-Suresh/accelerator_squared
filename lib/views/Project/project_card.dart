import 'package:accelerator_squared/models/projects.dart';
import 'package:accelerator_squared/views/Project/project_details.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProjectCard extends StatefulWidget {
  const ProjectCard({
    super.key,
    required this.sampleProjectDescriptions,
    required this.sampleProjectList,
    required this.index,
  });

  final List sampleProjectList;
  final List sampleProjectDescriptions;
  final int index;

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
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
        child: Padding(
          padding: EdgeInsets.all(10),
          child: ListTile(
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) {
                    return ProjectDetails(
                      projectName: widget.sampleProjectList[widget.index],
                      projectDescription:
                          widget.sampleProjectDescriptions[widget.index],
                    );
                  },
                ),
              );
            },
            title: Text(
              widget.sampleProjectList[widget.index],
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              widget.sampleProjectDescriptions[widget.index],
              maxLines: 5,
            ),
          ),
        ),
      ),
    );
  }
}

// New ProjectCard class that accepts Project objects directly
class ProjectCardNew extends StatelessWidget {
  final Project project;

  const ProjectCardNew({super.key, required this.project});

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
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          child: InkWell(
            splashFactory: InkSparkle.splashFactory,
            borderRadius: BorderRadius.circular(16), // Same as Card
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) {
                    return ProjectDetails(
                      projectName: project.name,
                      projectDescription: project.description,
                    );
                  },
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    project.name,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(project.description, maxLines: 5),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
