import 'package:flutter/material.dart';

class OrgStatisticsDialog extends StatefulWidget {
  OrgStatisticsDialog({super.key, required this.projectsList});

  List<String> projectsList;

  @override
  State<OrgStatisticsDialog> createState() => _OrgStatisticsDialogState();
}

class _OrgStatisticsDialogState extends State<OrgStatisticsDialog> {
  var sampleMilestonesList = [
    "Milestone 1",
    "Milestone 2",
    "Milestone 3",
    "Milestone 4",
  ];

  bool isMilestoneCompleted = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        "Organisation statistics",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width / 2,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListView.builder(
              itemBuilder: (context, index) {
                return Card(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                    child: Row(
                      children: [
                        Text(
                          widget.projectsList[index],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        SizedBox(width: 30),
                        Container(
                          height: 100,
                          width: MediaQuery.of(context).size.width / 3,
                          child: ListView.separated(
                            separatorBuilder: (context, index) {
                              return SizedBox(width: 20);
                            },
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(sampleMilestonesList[index]),
                                  SizedBox(height: 10),
                                  Checkbox(
                                    value: isMilestoneCompleted,
                                    onChanged: (value) {},
                                  ),
                                ],
                              );
                            },
                            itemCount: sampleMilestonesList.length,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              itemCount: widget.projectsList.length,
              shrinkWrap: true,
            ),
          ],
        ),
      ),
    );
  }
}
