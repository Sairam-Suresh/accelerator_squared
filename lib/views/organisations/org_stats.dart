import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:accelerator_squared/blocs/projects/projects_bloc.dart';
import 'package:accelerator_squared/models/projects.dart';

class OrgStatistics extends StatefulWidget {
  const OrgStatistics({
    super.key, 
    required this.projects,
    required this.organisationId,
  });

  final List<Project> projects;
  final String organisationId;

  @override
  State<OrgStatistics> createState() => _OrgStatisticsState();
}

class _OrgStatisticsState extends State<OrgStatistics> {
  @override
  void initState() {
    super.initState();
    // Fetch projects with milestones data
    context.read<ProjectsBloc>().add(FetchProjectsEvent(widget.organisationId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectsBloc, ProjectsState>(
      builder: (context, projectsState) {
        if (projectsState is ProjectsLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (projectsState is ProjectsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading data: ${projectsState.message}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<ProjectsBloc>().add(FetchProjectsEvent(widget.organisationId));
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        if (projectsState is ProjectsLoaded) {
          return _buildContent(projectsState.projects);
        }
        
        // Fallback: convert Project to ProjectWithDetails for compatibility
        final fallbackProjects = widget.projects.map((p) => ProjectWithDetails(
          id: p.id,
          data: {'name': p.name, 'title': p.title, 'description': p.description},
          milestones: [],
          comments: [],
        )).toList();
        
        return _buildContent(fallbackProjects);
      },
    );
  }

  Widget _buildContent(List<ProjectWithDetails> projects) {
    // Get organization-wide milestones (milestones that exist in ALL projects)
    final orgWideMilestones = _getOrganizationWideMilestones(projects);
    
    // Calculate summary stats
    int totalProjects = projects.length;
    int totalMilestones = orgWideMilestones.length;
    int completedMilestones = _getCompletedMilestonesCount(orgWideMilestones, projects);

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
                          ...orgWideMilestones.map((m) => DataColumn(label: Text(m['name'] ?? 'Unknown'))),
                        ],
                        rows: projects.map((project) {
                          return DataRow(
                            cells: [
                              DataCell(Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                    child: Icon(Icons.folder, color: Theme.of(context).colorScheme.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              )),
                              ...orgWideMilestones.map((orgMilestone) {
                                final milestoneStatus = _getMilestoneStatusForProject(orgMilestone, project);
                                final isCompleted = milestoneStatus['isCompleted'] ?? false;
                                final status = isCompleted ? "Completed" : "Incomplete";
                                
                                return DataCell(Center(
                                  child: Chip(
                                    label: Text(status),
                                    backgroundColor: isCompleted
                                        ? Colors.green.shade100
                                        : Colors.orange.shade100,
                                    labelStyle: TextStyle(
                                      color: isCompleted
                                          ? Colors.green.shade800
                                          : Colors.orange.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ));
                              }),
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
          backgroundColor: (color ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.15),
          child: Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }

  /// Gets milestones that exist in ALL projects (organization-wide milestones)
  /// These are identified by having the same sharedId across all projects
  List<Map<String, dynamic>> _getOrganizationWideMilestones(List<ProjectWithDetails> projects) {
    if (projects.isEmpty) return [];
    
    // Collect all milestones from all projects
    final allMilestones = <Map<String, dynamic>>[];
    for (final project in projects) {
      allMilestones.addAll(project.milestones);
    }
    
    // Count how many times each sharedId appears
    final sharedIdCounts = <String, int>{};
    for (final milestone in allMilestones) {
      final sharedId = milestone['sharedId'];
      if (sharedId != null && sharedId.toString().isNotEmpty) {
        sharedIdCounts[sharedId] = (sharedIdCounts[sharedId] ?? 0) + 1;
      }
    }
    
    // Only include milestones that appear in every project
    final orgWideSharedIds = sharedIdCounts.entries
        .where((entry) => entry.value == projects.length)
        .map((entry) => entry.key)
        .toSet();
    
    // Get one representative milestone for each org-wide sharedId
    final orgWideMilestones = <Map<String, dynamic>>[];
    final seenSharedIds = <String>{};
    
    for (final milestone in allMilestones) {
      final sharedId = milestone['sharedId'];
      if (sharedId != null && 
          orgWideSharedIds.contains(sharedId) && 
          !seenSharedIds.contains(sharedId)) {
        seenSharedIds.add(sharedId);
        orgWideMilestones.add(milestone);
      }
    }
    
    return orgWideMilestones;
  }

  /// Gets the completion status of a specific milestone for a specific project
  Map<String, dynamic> _getMilestoneStatusForProject(
    Map<String, dynamic> orgMilestone, 
    ProjectWithDetails project
  ) {
    final sharedId = orgMilestone['sharedId'];
    if (sharedId == null) {
      return {'isCompleted': false};
    }
    
    // Find the milestone in this project with the same sharedId
    final projectMilestone = project.milestones.firstWhere(
      (m) => m['sharedId'] == sharedId,
      orElse: () => <String, dynamic>{},
    );
    
    if (projectMilestone.isEmpty) {
      return {'isCompleted': false};
    }
    
    final isCompleted = projectMilestone['isCompleted'] ?? false;
    
    return {
      'isCompleted': isCompleted,
    };
  }

  /// Counts how many organization-wide milestones are completed across all projects
  int _getCompletedMilestonesCount(
    List<Map<String, dynamic>> orgWideMilestones,
    List<ProjectWithDetails> projects
  ) {
    if (projects.isEmpty) return 0;
    
    int completedCount = 0;
    
    for (final orgMilestone in orgWideMilestones) {
      // Check if this milestone is completed in ALL projects
      bool completedInAllProjects = true;
      
      for (final project in projects) {
        final status = _getMilestoneStatusForProject(orgMilestone, project);
        if (!(status['isCompleted'] ?? false)) {
          completedInAllProjects = false;
          break;
        }
      }
      
      if (completedInAllProjects) {
        completedCount++;
      }
    }
    
    return completedCount;
  }
}
