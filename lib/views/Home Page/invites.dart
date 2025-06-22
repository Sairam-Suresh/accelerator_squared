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
    "Nullspace robotics centre",
    "BrightSparks tuition centre",
  ];

  var sampleProjectInvites = [
    "Flutter app 1",
    "Swift student challenge 2025",
    "Google devfest showcase",
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: "Organisation Invites",
            subtitle: "You have ${sampleOrgInvites.length} pending organisation invitations",
            icon: Icons.business_outlined,
          ),
          const SizedBox(height: 20),
          
          if (sampleOrgInvites.isEmpty)
            _buildEmptyState(
              icon: Icons.business_outlined,
              title: "No organisation invites",
              subtitle: "You don't have any pending organisation invitations",
            )
          else
            _buildInvitesList(
              invites: sampleOrgInvites,
              onAccept: (index) {
                setState(() {
                  sampleOrgInvites.removeAt(index);
                });
              },
              onDecline: (index) {
                setState(() {
                  sampleOrgInvites.removeAt(index);
                });
              },
            ),
          
          const SizedBox(height: 48),
          
          _buildSectionHeader(
            title: "Project Invites",
            subtitle: "You have ${sampleProjectInvites.length} pending project invitations",
            icon: Icons.folder_outlined,
          ),
          const SizedBox(height: 20),
          
          if (sampleProjectInvites.isEmpty)
            _buildEmptyState(
              icon: Icons.folder_outlined,
              title: "No project invites",
              subtitle: "You don't have any pending project invitations",
            )
          else
            _buildInvitesList(
              invites: sampleProjectInvites,
              onAccept: (index) {
                setState(() {
                  sampleProjectInvites.removeAt(index);
                });
              },
              onDecline: (index) {
                setState(() {
                  sampleProjectInvites.removeAt(index);
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInvitesList({
    required List<String> invites,
    required Function(int) onAccept,
    required Function(int) onDecline,
  }) {
    return Column(
      children: invites.asMap().entries.map((entry) {
        final index = entry.key;
        final invite = entry.value;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.mail_outline,
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invite,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Invitation pending",
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => onAccept(index),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text(
                            "Accept",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onDecline(index),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.error,
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text(
                            "Decline",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
