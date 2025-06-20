import 'package:flutter/material.dart';

class JoinOrganisationDialog extends StatefulWidget {
  const JoinOrganisationDialog({super.key, required this.orgcodecontroller});

  final TextEditingController orgcodecontroller;

  @override
  State<JoinOrganisationDialog> createState() => _JoinOrganisationDialogState();
}

class _JoinOrganisationDialogState extends State<JoinOrganisationDialog> {
  var sampleOrgTitles = [
    "SST Inc",
    "SST Hack Club",
    "NUS High Rejects",
    "sigma club",
  ];
  var sampleOrgDescriptions = [
    "The ict talent development programme of the school of science and technology, singapore. lorem ipsum dolor sit amet",
    "A rip off of sst inc, surely this is able to do better than it and lorem ipsum dolor sit amet, hirhg iurhfiuwrhf uiwhfouhw",
    "Bums",
    "we love not doing work 100",
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      content: SizedBox(
        width: MediaQuery.of(context).size.width / 2,
        height: MediaQuery.of(context).size.height / 1.5,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Join organisation",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Center(
              child: TextField(
                controller: widget.orgcodecontroller,
                decoration: InputDecoration(
                  hintText: "Enter join code",
                  label: Text("Organisation code"),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sampleOrgTitles[index],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            sampleOrgDescriptions[index],
                            style: TextStyle(fontSize: 14),
                            maxLines: 1,
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          Text("17 members"),
                          VerticalDivider(),
                          Text("4 projects"),
                        ],
                      ),
                    ),
                  );
                },
                itemCount: sampleOrgDescriptions.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
