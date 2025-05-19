import 'package:accelerator_squared/views/Project/project_details.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProjectCard extends StatefulWidget {
  ProjectCard({
    super.key,
    required this.sampleProjectDescriptions,
    required this.sampleProjectList,
    required this.index,
  });

  List sampleProjectList;
  List sampleProjectDescriptions;
  int index;

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
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
    );
  }
}
