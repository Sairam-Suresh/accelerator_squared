import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:accelerator_squared/util/snackbar_helper.dart';

class OrgInvitesPage extends StatefulWidget {
  const OrgInvitesPage({super.key});

  @override
  State<OrgInvitesPage> createState() => _OrgInvitesPageState();
}

class _OrgInvitesPageState extends State<OrgInvitesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Set<String> _acceptingInvitePaths = <String>{};

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<User?>(
            stream: _auth.userChanges(),
            builder: (context, userSnap) {
              final user = userSnap.data;
              final currentUid = user?.uid;
              final currentEmail = user?.email;

              if (currentUid == null && currentEmail == null) {
                return _buildSectionHeader(
                  title: "Organisation Invites",
                  subtitle: "Sign in to view invites",
                  icon: Icons.business_outlined,
                );
              }

              final String? emailLower = currentEmail?.toLowerCase();

              // Build composite filter: status == 'pending' AND (toUid == uid OR toEmail == emailLower)
              Filter recipientsFilter;
              if (currentUid != null && emailLower != null) {
                recipientsFilter = Filter.or(
                  Filter('toUid', isEqualTo: currentUid),
                  Filter('toEmail', isEqualTo: emailLower),
                );
              } else if (currentUid != null) {
                recipientsFilter = Filter('toUid', isEqualTo: currentUid);
              } else {
                recipientsFilter = Filter('toEmail', isEqualTo: emailLower);
              }

              final compositeFilter = Filter.and(
                Filter('status', isEqualTo: 'pending'),
                recipientsFilter,
              );

              final invitesStream =
                  _firestore
                      .collectionGroup('invites')
                      .where(compositeFilter)
                      .snapshots();

              return StreamBuilder<QuerySnapshot>(
                stream: invitesStream,
                builder: (context, snapshot) {
                  final bool isLoading =
                      snapshot.connectionState == ConnectionState.waiting;

                  if (snapshot.hasError) {
                    // Log error to console for web debugging
                    debugPrint('Invites fetch error: ${snapshot.error}');
                    if (snapshot.stackTrace != null) {
                      debugPrint('Invites fetch stack: ${snapshot.stackTrace}');
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          title: "Organisation Invites",
                          subtitle: "Couldn't load invites",
                          icon: Icons.business_outlined,
                        ),
                        const SizedBox(height: 20),
                        _buildEmptyState(
                          icon: Icons.error_outline,
                          title: "Error",
                          subtitle:
                              "An error occurred while loading invites: ${snapshot.error}",
                        ),
                      ],
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  // Debug: log mode and results
                  debugPrint(
                    'Invites query mode: uid=${currentUid != null}, email=${emailLower != null}, results=${docs.length}',
                  );

                  final invites =
                      docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return {
                          'inviteDocPath': doc.reference.path,
                          'orgId': data['orgId'] as String? ?? '',
                          'orgName':
                              data['orgName'] as String? ?? 'Organisation',
                          'memberDocId': data['memberDocId'] as String? ?? '',
                        };
                      }).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        title: "Organisation Invites",
                        subtitle:
                            isLoading
                                ? "Loading your invitations..."
                                : "You have ${invites.length} pending organisation invitations",
                        icon: Icons.business_outlined,
                      ),
                      const SizedBox(height: 20),
                      if (isLoading)
                        _buildLoadingInvitesList()
                      else if (invites.isEmpty)
                        _buildEmptyState(
                          icon: Icons.business_outlined,
                          title: "No organisation invites",
                          subtitle:
                              "You don't have any pending organisation invitations",
                        )
                      else
                        _buildInvitesList(
                          invites: invites,
                          onAccept: (index) => _acceptInvite(invites[index]),
                          onDecline: (index) => _declineInvite(invites[index]),
                          acceptingPaths: _acceptingInvitePaths,
                        ),
                    ],
                  );
                },
              );
            },
          ),

          // const SizedBox(height: 48),

          // _buildSectionHeader(
          //   title: "Project Invites",
          //   subtitle: "Project invites coming soon",
          //   icon: Icons.folder_outlined,
          // ),
          // const SizedBox(height: 20),
          // _buildEmptyState(
          //   icon: Icons.folder_outlined,
          //   title: "No project invites",
          //   subtitle: "You don't have any pending project invitations",
          // ),
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
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
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
    required List<Map<String, dynamic>> invites,
    required Function(int) onAccept,
    required Function(int) onDecline,
    Set<String> acceptingPaths = const <String>{},
  }) {
    return Column(
      children:
          invites.asMap().entries.map((entry) {
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
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.mail_outline,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  invite['orgName'] as String? ??
                                      'Organisation',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Invitation pending",
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed:
                                acceptingPaths.contains(
                                      invite['inviteDocPath'] as String,
                                    )
                                    ? null
                                    : () => onAccept(index),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 20,
                              ),
                            ),
                            icon:
                                acceptingPaths.contains(
                                      invite['inviteDocPath'] as String,
                                    )
                                    ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(Icons.check, size: 18),
                            label:
                                acceptingPaths.contains(
                                      invite['inviteDocPath'] as String,
                                    )
                                    ? const Text(
                                      "Accepting...",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                    : const Text(
                                      "Accept",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () => onDecline(index),
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).colorScheme.error,
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.error,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 20,
                              ),
                            ),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text(
                              "Decline",
                              style: TextStyle(fontWeight: FontWeight.w600),
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

  Widget _buildLoadingInvitesList() {
    // Simple skeleton/loading list
    return Column(
      children:
          List.generate(3, (index) => index).map((_) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 14,
                              width: 200,
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 12,
                              width: 140,
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Future<void> _acceptInvite(Map<String, dynamic> invite) async {
    try {
      final String path = invite['inviteDocPath'] as String;
      setState(() {
        _acceptingInvitePaths.add(path);
      });
      final user = _auth.currentUser;
      if (user == null) return;

      final String orgId = invite['orgId'] as String;
      final String memberDocId = invite['memberDocId'] as String;

      // Update member status to active and set uid
      await _firestore
          .collection('organisations')
          .doc(orgId)
          .collection('members')
          .doc(memberDocId)
          .set({
            'uid': user.uid,
            'email': user.email,
            'status': 'active',
          }, SetOptions(merge: true));

      // Update invite status to accepted
      await _firestore.doc(invite['inviteDocPath'] as String).set({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        SnackBarHelper.showSuccess(context, message: 'Joined organisation');
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          message: 'Error accepting invite: $e',
        );
      }
    } finally {
      final String path = invite['inviteDocPath'] as String;
      if (mounted) {
        setState(() {
          _acceptingInvitePaths.remove(path);
        });
      }
    }
  }

  Future<void> _declineInvite(Map<String, dynamic> invite) async {
    try {
      final String orgId = invite['orgId'] as String;
      final String memberDocId = invite['memberDocId'] as String;

      // Mark invite declined
      await _firestore.doc(invite['inviteDocPath'] as String).set({
        'status': 'declined',
        'declinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Remove pending member doc
      await _firestore
          .collection('organisations')
          .doc(orgId)
          .collection('members')
          .doc(memberDocId)
          .delete();

      if (mounted) {
        SnackBarHelper.showSuccess(context, message: 'Invite declined');
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          message: 'Error declining invite: $e',
        );
      }
    }
  }
}
