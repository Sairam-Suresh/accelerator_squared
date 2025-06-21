import 'package:flutter/material.dart';

class OrgStatistics extends StatefulWidget {
  const OrgStatistics({super.key, required this.projectsList});

  final List<String> projectsList;

  @override
  State<OrgStatistics> createState() => _OrgStatisticsState();
}

class _OrgStatisticsState extends State<OrgStatistics> {
  var sampleMilestonesDict = {
    "Milestone 1": ["Completed", "100%"],
    "Milestone 2": ["Incomplete", "75%"],
    "Milestone 3": ["Incomplete", "Pending further review"],
    "Milestone 4": ["Completed", "100%"],
    "Milestone 5": ["Incomplete", "50%"],
    "Milestone 6": ["Completed", "100%"],
    "Milestone 7": ["Completed", "100%"],
    "Milestone 8": ["Completed", "100%"],
  };

  bool isMilestoneCompleted = false;

  List<TableRow> rows = [];
  List<Widget> milestones = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    milestones.add(SizedBox());

    // Takes the names of milestones and adds them to the table
    for (int x = 0; x < sampleMilestonesDict.length; x++) {
      milestones.add(
        Padding(
          padding: EdgeInsets.all(10),
          child: Text(
            sampleMilestonesDict.keys.elementAt(x),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      );
    }

    rows.add(
      TableRow(
        decoration: BoxDecoration(border: Border.all()),
        children: milestones,
      ),
    );

    // Takes the individual milestones of each organization and adds them to the table

    for (int i = 0; i < widget.projectsList.length; i++) {
      List<Widget> tempRow = [];
      tempRow.add(
        Padding(
          padding: EdgeInsets.all(10),
          child: Text(
            widget.projectsList[i],
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );

      // Gets data of each organization's specific milestone and adds it to the table row
      for (int y = 0; y < sampleMilestonesDict.length; y++) {
        List<Widget> tempCellData = [];
        for (
          int z = 0;
          z < sampleMilestonesDict.values.elementAt(y).length;
          z++
        ) {
          tempCellData.add(
            Padding(
              padding: EdgeInsets.all(5),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  sampleMilestonesDict.values.elementAt(y).elementAt(z),
                  textAlign: TextAlign.start,
                ),
              ),
            ),
          );
        }
        tempRow.add(
          Padding(
            padding: const EdgeInsets.all(5),
            child: Column(children: tempCellData),
          ),
        );
      }
      rows.add(
        TableRow(
          decoration: BoxDecoration(border: Border.all()),
          children: tempRow,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Expanded(
          child: Scrollbar(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Table(
                  defaultColumnWidth: FixedColumnWidth(175),
                  border: TableBorder.all(
                    color: Color.fromRGBO(255, 255, 255, 0.4),
                    width: 1.25,
                  ),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: rows,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
