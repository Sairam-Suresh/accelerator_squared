import 'package:flutter/material.dart';
import 'package:accelerator_squared/models/projects.dart';

class OrgStatistics extends StatefulWidget {
  const OrgStatistics({super.key, required this.projects});

  final List<Project> projects;

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

  @override
  Widget build(BuildContext context) {
    // Calculate summary stats
    int totalProjects = widget.projects.length;
    int totalMilestones = sampleMilestonesDict.length;
    int completedMilestones = sampleMilestonesDict.values
        .where((v) => v[0] == "Completed").length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSummaryTile(context, "Projects", totalProjects.toString(), Icons.folder_rounded),
                    _buildSummaryTile(context, "Milestones", totalMilestones.toString(), Icons.flag_rounded),
                    _buildSummaryTile(context, "Completed", completedMilestones.toString(), Icons.check_circle_rounded, color: Colors.green),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // DataTable
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: 800),
                      child: DataTable(
                        columnSpacing: 24,
                        dataRowMinHeight: 56,
                        dataRowMaxHeight: 80,
                        columns: [
                          DataColumn(label: Text("Project")),
                          ...sampleMilestonesDict.keys.map((m) => DataColumn(label: Text(m))),
                        ],
                        rows: widget.projects.map((project) {
                          return DataRow(
                            cells: [
                              DataCell(Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    child: Icon(Icons.folder, color: Theme.of(context).colorScheme.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              )),
                              ...sampleMilestonesDict.entries.map((entry) {
                                final status = entry.value[0];
                                final percent = entry.value[1];
                                return DataCell(Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Chip(
                                      label: Text(status),
                                      backgroundColor: status == "Completed"
                                          ? Colors.green.shade100
                                          : Colors.orange.shade100,
                                      labelStyle: TextStyle(
                                        color: status == "Completed"
                                            ? Colors.green.shade800
                                            : Colors.orange.shade800,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(percent, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                  ],
                                ));
                              }).toList(),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTile(BuildContext context, String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: (color ?? Theme.of(context).colorScheme.primary).withOpacity(0.15),
          child: Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
