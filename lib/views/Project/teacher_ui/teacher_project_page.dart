import 'package:accelerator_squared/views/Project/project_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TeacherProjectPage extends StatefulWidget {
  const TeacherProjectPage({
    super.key,
    required this.orgName,
    required this.sampleProjectDescriptions,
    required this.sampleProjectList,
  });

  final String orgName;

  final List sampleProjectList;
  final List sampleProjectDescriptions;

  @override
  State<TeacherProjectPage> createState() => _TeacherProjectPageState();
}

class _TeacherProjectPageState extends State<TeacherProjectPage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: GridView.count(
        childAspectRatio: 1.5,
        crossAxisCount: 3,
        children: List.generate(widget.sampleProjectList.length, (index) {
          return ProjectCard(
            sampleProjectDescriptions: widget.sampleProjectDescriptions,
            sampleProjectList: widget.sampleProjectList,
            index: index,
          );
        }),
      ),
    );
  }
}
