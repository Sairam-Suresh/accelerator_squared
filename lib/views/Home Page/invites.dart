import 'package:flutter/material.dart';

class OrgInvitesPage extends StatefulWidget {
  const OrgInvitesPage({super.key});

  @override
  State<OrgInvitesPage> createState() => _OrgInvitesPageState();
}

class _OrgInvitesPageState extends State<OrgInvitesPage> {
  var sampleOrgInvites = [
    "NUS High School of Science and Mathematics",
    "Anglo-Chinese School (Independent)",
    "Nullspace robotics",
    "brightSparks tuition centre",
  ];

  var sampleProjectInvites = [
    "Flutter app 1",
    "Swift student challenge 2025",
    "Google devfest showcase",
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Organization invites",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          SizedBox(
            width: MediaQuery.of(context).size.width - 150,
            height: MediaQuery.of(context).size.height / 2 - 105,
            child: ListView.separated(
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    Card(
                      child: ListTile(
                        title: Text(
                          sampleOrgInvites[index],
                          style: TextStyle(fontSize: 20),
                        ),
                        subtitle: Row(
                          children: [
                            Text("34 members"),
                            VerticalDivider(),
                            Text("5 projects"),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {},
                          label: Text(
                            "Accept",
                            style: TextStyle(color: Colors.green),
                          ),
                          icon: Icon(Icons.check, color: Colors.green),
                        ),
                        SizedBox(height: 5),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              sampleOrgInvites.removeAt(index);
                            });
                          },
                          label: Text(
                            "Decline",
                            style: TextStyle(color: Colors.red),
                          ),
                          icon: Icon(Icons.cancel, color: Colors.red),
                        ),
                      ],
                    ),
                  ],
                );
              },
              separatorBuilder: (context, index) {
                return SizedBox(height: 10);
              },
              itemCount: sampleOrgInvites.length,
              shrinkWrap: true,
            ),
          ),
          SizedBox(height: 20),
          Text(
            "Project invites",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          SizedBox(
            width: MediaQuery.of(context).size.width - 150,
            height: MediaQuery.of(context).size.height / 2 - 105,
            child: ListView.separated(
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    Card(
                      child: ListTile(
                        title: Text(
                          sampleProjectInvites[index],
                          style: TextStyle(fontSize: 20),
                        ),
                        subtitle: Row(
                          children: [
                            Text("34 members"),
                            VerticalDivider(),
                            Text("5 projects"),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {},
                          label: Text(
                            "Accept",
                            style: TextStyle(color: Colors.green),
                          ),
                          icon: Icon(Icons.check, color: Colors.green),
                        ),
                        SizedBox(height: 5),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              sampleProjectInvites.removeAt(index);
                            });
                          },
                          label: Text(
                            "Decline",
                            style: TextStyle(color: Colors.red),
                          ),
                          icon: Icon(Icons.cancel, color: Colors.red),
                        ),
                      ],
                    ),
                  ],
                );
              },
              separatorBuilder: (context, index) {
                return SizedBox(height: 10);
              },
              itemCount: sampleProjectInvites.length,
              shrinkWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
