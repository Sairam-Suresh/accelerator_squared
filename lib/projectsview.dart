import 'package:flutter/material.dart';

class ProjectPage extends StatefulWidget {
  ProjectPage({super.key, required this.orgName});

  String orgName;

  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  var sampleProjectList = ['Project 1', 'Project 2', 'Project 3'];
  var sampleProjectDescriptions = [
    'This project is killing me',
    'Why did i decide to do this',
    'save me',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.orgName,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemBuilder: (context, index) {
                    return Card(
                      child: ListTile(
                        title: Text(
                          sampleProjectList[index],
                          style: TextStyle(fontSize: 24),
                        ),
                        subtitle: Text(sampleProjectDescriptions[index]),
                      ),
                    );
                  },
                  itemCount: sampleProjectList.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
