import 'package:flutter/material.dart';
import 'package:side_sheet_material3/side_sheet_material3.dart';
import 'package:url_launcher/url_launcher.dart';

class ProjectDetails extends StatefulWidget {
  ProjectDetails({
    super.key,
    required this.projectName,
    required this.projectDescription,
  });

  String projectName;
  String projectDescription;

  @override
  State<ProjectDetails> createState() => _ProjectDetailsState();
}

class _ProjectDetailsState extends State<ProjectDetails> {
  Future<void> _launchUrl() async {
    if (!await launchUrl(
      Uri.parse('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
    )) {
      throw Exception("hyperlink broken");
    }
  }

  var sampleMilestoneList = ['Milestone 1', 'Milestone 2'];
  var sampleMilestoneDescriptions = [
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat',
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Project', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.projectName,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 60),
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 2,
                  child: Text(
                    widget.projectDescription,
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                SizedBox(height: 25),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 4,
                  child: ElevatedButton(
                    onPressed: () {},
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(10, 20, 10, 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder, size: 30),
                          SizedBox(width: 20),
                          Text(
                            "View project files",
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 4,
                  child: ElevatedButton(
                    onPressed: () {},
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(10, 20, 10, 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 30),
                          SizedBox(width: 20),
                          Text(
                            "Upload deliverables",
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30),
                Text("Project brief", style: TextStyle(fontSize: 30)),
                SizedBox(height: 15),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 4,
                  child: ElevatedButton(
                    onPressed: () {
                      //_launchUrl();
                    },
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(10, 20, 10, 20),
                      child: Text(
                        "View project brief",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Divider(),
                SizedBox(height: 10),
                ListView.builder(
                  itemBuilder: (context, index) {
                    return Card(
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: ListTile(
                          onTap: () async {
                            await showModalSideSheet(
                              context,
                              body: Padding(
                                padding: EdgeInsets.all(10),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sampleMilestoneList[index],
                                      style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Divider(),
                                    SizedBox(height: 10),
                                    Text(
                                      "Assigned by placeholder",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    Text(
                                      "Due on placeholder",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    Text(
                                      "Inside Project 1",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    SizedBox(height: 15),
                                    Text(sampleMilestoneDescriptions[index]),
                                    SizedBox(height: 15),
                                    TextButton(
                                      onPressed: () {},
                                      child: Padding(
                                        padding: EdgeInsets.fromLTRB(
                                          10,
                                          20,
                                          10,
                                          20,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.arrow_back),
                                            SizedBox(width: 10),
                                            Text("Send for review"),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Divider(),
                                    SizedBox(height: 10),
                                  ],
                                ),
                              ),
                              header: "Milestone",
                              addCloseIconButton: false,
                              addBackIconButton: true,
                            );
                          },
                          title: Text(
                            sampleMilestoneList[index],
                            style: TextStyle(fontSize: 20),
                          ),
                          subtitle: Text(
                            sampleMilestoneDescriptions[index],
                            maxLines: 1,
                          ),
                        ),
                      ),
                    );
                  },
                  itemCount: sampleMilestoneList.length,
                  shrinkWrap: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
