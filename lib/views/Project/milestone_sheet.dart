import 'package:flutter/material.dart';
import 'package:side_sheet_material3/side_sheet_material3.dart';

class MilestoneSheet extends StatefulWidget {
  const MilestoneSheet({
    super.key,
    required this.sampleMilestoneList,
    required this.sampleMilestoneDescriptions,
    required this.sampleTasksList,
    required this.index,
  });

  final List sampleMilestoneList;
  final List sampleMilestoneDescriptions;
  final List sampleTasksList;
  final int index;

  @override
  State<MilestoneSheet> createState() => _MilestoneSheetState();
}

class _MilestoneSheetState extends State<MilestoneSheet> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.sampleMilestoneList[widget.index],
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Divider(),
        SizedBox(height: 10),
        Text("Assigned by placeholder", style: TextStyle(fontSize: 18)),
        Text("Due on placeholder", style: TextStyle(fontSize: 18)),
        Text("Inside Project 1", style: TextStyle(fontSize: 18)),
        SizedBox(height: 15),
        Text(widget.sampleMilestoneDescriptions[widget.index]),
        SizedBox(height: 15),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Padding(
            padding: EdgeInsets.fromLTRB(10, 20, 10, 20),
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
        Text(
          "Tasks",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            itemBuilder: (context, index) {
              return Card(
                child: ListTile(
                  onTap: () async {
                    Navigator.of(context).pop();

                    await showModalSideSheet(
                      context,
                      body: Padding(
                        padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.sampleTasksList[index],
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(widget.sampleMilestoneDescriptions[index]),
                            SizedBox(height: 10),
                            Divider(),
                            SizedBox(height: 10),
                            Text("Due on X April 2025"),
                            SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                var navigator = Navigator.of(context);
                                navigator.pop();
                              },
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                                child: Row(
                                  children: [
                                    Icon(Icons.check),
                                    SizedBox(width: 10),
                                    Text("Mark as completed"),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Divider(),
                            SizedBox(height: 10),
                            // Text(
                            //   "Comments",
                            //   style: TextStyle(
                            //     fontSize: 22,
                            //     fontWeight:
                            //         FontWeight
                            //             .bold,
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                      header: "Sample task view",
                    );
                  },
                  title: Text(widget.sampleTasksList[index]),
                  subtitle: Text(
                    widget.sampleMilestoneDescriptions[index],
                    maxLines: 2,
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) {
              return SizedBox(height: 10);
            },
            itemCount: widget.sampleTasksList.length,
          ),
        ),
      ],
    );
  }
}
