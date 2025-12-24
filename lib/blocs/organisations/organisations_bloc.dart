import 'dart:async';

import 'package:accelerator_squared/util/util.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';
import '../../models/organisation.dart';

part 'organisations_event.dart';
part 'organisations_state.dart';

class OrganisationsBloc extends Bloc<OrganisationsEvent, OrganisationsState> {
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _uidMembershipsSubscription;
  StreamSubscription<QuerySnapshot>? _emailMembershipsSubscription;
  Map<String, StreamSubscription<DocumentSnapshot>> _orgDocumentSubscriptions =
      {};
  Set<String> _currentOrgIds = {};
  bool _isInitialMembershipStream = true;
  bool _isInitialEmailMembershipStream = true;
  Map<String, bool> _isInitialOrgDocumentStream = {};

  OrganisationsBloc() : super(OrganisationsInitial()) {
    on<FetchOrganisationsEvent>((event, emit) async {
      final previousState = state;
      final shouldShowLoading = previousState is! OrganisationsLoaded;
      if (shouldShowLoading) {
        emit(OrganisationsLoading());
      }

      try {
        String uid = auth.currentUser?.uid ?? '';
        String userEmail = auth.currentUser?.email ?? '';

        if (uid.isEmpty) {
          emit(OrganisationsError("User not authenticated"));
          return;
        }

        List<Organisation> organisations = [];

        QuerySnapshot uidMemberships = await firestore
            .collectionGroup('members')
            .where('uid', isEqualTo: uid)
            .get()
            .timeout(const Duration(seconds: 10));

        QuerySnapshot emailMemberships;

        // Always query by email if email is available, to catch memberships
        // that might only be stored with email (not uid)
        if (userEmail.isNotEmpty) {
          emailMemberships = await firestore
              .collectionGroup('members')
              .where('email', isEqualTo: userEmail)
              .get()
              .timeout(const Duration(seconds: 10));
        } else {
          emailMemberships = uidMemberships;
        }

        // Combine both membership queries (duplicates will be handled when deduplicating by orgId)
        List<QueryDocumentSnapshot> allMemberships = [
          ...uidMemberships.docs,
          ...emailMemberships.docs,
        ];

        if (allMemberships.isEmpty) {
          emit(OrganisationsLoaded([]));
          return;
        }

        // Filter memberships to only active status (default to active if missing)
        final activeMemberships =
            allMemberships.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final status = (data['status'] ?? 'active') as String;
              return status == 'active';
            }).toList();

        Set<String> orgIds =
            activeMemberships
                .map((doc) => doc.reference.parent.parent?.id)
                .where((id) => id != null)
                .cast<String>()
                .toSet();

        for (String orgId in orgIds) {
          var data = await loadOrganisationDataById(
            firestore,
            orgId,
            uid,
            userEmail,
          );
          if (data == null) continue;
          organisations.add(data);
        }

        emit(OrganisationsLoaded(organisations));

        // Set up streams for dynamic updates after a microtask delay
        // This ensures the loaded state is emitted first before streams are set up
        Future.microtask(() {
          _setupMembershipStreams(uid, userEmail);
          _setupOrganisationDocumentStreams(orgIds, uid, userEmail);
        });
      } catch (e) {
        if (e.toString().contains('timeout')) {
          emit(
            OrganisationsError(
              "Request timed out. Please check your connection and try again.",
            ),
          );
        } else {
          emit(OrganisationsError(e.toString()));
        }
      }
    });

    on<CreateOrganisationEvent>((event, emit) async {
      emit(OrganisationsLoading());
      try {
        String uid = auth.currentUser?.uid ?? '';
        if (uid.isEmpty) {
          emit(OrganisationsError("User not authenticated"));
          return;
        }
        String orgId = const Uuid().v4();
        DocumentReference orgRef = firestore
            .collection('organisations')
            .doc(orgId);

        // Generate a 6-character join code (uppercase letters and numbers)
        String joinCode = generateJoinCode();

        await orgRef.set({
          'name': event.name,
          'description': event.description,
          'joinCode': joinCode,
        });

        // Get current user's display name
        String? creatorDisplayName;
        try {
          final userDoc = await firestore.collection('users').doc(uid).get();
          if (userDoc.exists) {
            creatorDisplayName = userDoc.data()?['displayName'] as String?;
          }
        } catch (e) {
          // Ignore errors, displayName will be null
        }

        await orgRef.collection('members').doc(uid).set({
          'role': 'teacher',
          'email': auth.currentUser?.email ?? '',
          'uid': uid,
          'displayName': creatorDisplayName,
          'status': 'active',
          'addedAt': FieldValue.serverTimestamp(),
          'addedBy': uid,
        });

        for (String email in event.memberEmails) {
          if (email == auth.currentUser?.email) continue;

          // Get display name for this email if available
          String? memberDisplayName;
          try {
            memberDisplayName = await fetchUserDisplayNameByEmail(
              firestore,
              email,
            );
          } catch (e) {
            // Ignore errors, displayName will be null
          }

          // Try to find the user's UID by email
          String? memberUid;
          try {
            final userQuery = await firestore
                .collection('users')
                .where('email', isEqualTo: email)
                .limit(1)
                .get();
            if (userQuery.docs.isNotEmpty) {
              memberUid = userQuery.docs.first.id;
            }
          } catch (e) {
            // Ignore errors, memberUid will be null
          }

          // Use UID if found, otherwise fallback to email as document ID
          String docId = memberUid ?? email;

          // Create pending member document
          await orgRef.collection('members').doc(docId).set({
            'role': 'member',
            'email': email,
            'displayName': memberDisplayName,
            'status': 'pending',
            'addedAt': FieldValue.serverTimestamp(),
            'addedBy': uid,
            if (memberUid != null) 'uid': memberUid,
          });

          // Create an invite document for this member
          final inviteRef = orgRef.collection('invites').doc();
          await inviteRef.set({
            'orgId': orgId,
            'orgName': event.name,
            'toEmail': email.toLowerCase(),
            'toEmailLower': email.toLowerCase(),
            if (memberUid != null) 'toUid': memberUid,
            'fromUid': uid,
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
            'memberDocId': docId,
          });
        }

        // Wait for the member document to be readable to ensure it's fully written
        await orgRef.collection('members').doc(uid).get();

        add(FetchOrganisationsEvent());
      } catch (e) {
        emit(OrganisationsError(e.toString()));
      }
    });

    on<JoinOrganisationEvent>((event, emit) async {
      emit(OrganisationsLoading());
      try {
        String uid = auth.currentUser?.uid ?? '';
        if (uid.isEmpty) {
          emit(OrganisationsError("User not authenticated"));
          return;
        }

        DocumentReference orgRef = firestore
            .collection('organisations')
            .doc(event.organisationId);

        await orgRef.collection('members').doc(uid).set({
          'role': 'member',
          'email': auth.currentUser?.email ?? '',
          'uid': uid,
          'status': 'active',
          'addedAt': FieldValue.serverTimestamp(),
          'addedBy': uid,
        });

        add(FetchOrganisationsEvent());
      } catch (e) {
        emit(OrganisationsError(e.toString()));
      }
    });

    on<JoinOrganisationByCodeEvent>((event, emit) async {
      final previousState = state;
      emit(OrganisationsLoading());
      try {
        String uid = auth.currentUser?.uid ?? '';
        String userEmail = auth.currentUser?.email ?? '';

        if (uid.isEmpty) {
          emit(OrganisationsError("User not authenticated"));
          return;
        }

        // Find organisation by join code
        QuerySnapshot orgSnapshot =
            await firestore
                .collection('organisations')
                .where('joinCode', isEqualTo: event.joinCode.toUpperCase())
                .get();

        if (orgSnapshot.docs.isEmpty) {
          emit(OrganisationsError("Invalid join code"));
          return;
        }

        String orgId = orgSnapshot.docs.first.id;

        // Check if user is already a member (try by uid first, then email)
        QuerySnapshot memberSnapshot =
            await firestore
                .collection('organisations')
                .doc(orgId)
                .collection('members')
                .where('uid', isEqualTo: uid)
                .get();

        // If not found by uid, try by email
        if (memberSnapshot.docs.isEmpty && userEmail.isNotEmpty) {
          memberSnapshot =
              await firestore
                  .collection('organisations')
                  .doc(orgId)
                  .collection('members')
                  .where('email', isEqualTo: userEmail)
                  .get();
        }

        if (memberSnapshot.docs.isNotEmpty) {
          if (previousState is OrganisationsLoaded) {
            emit(
              OrganisationsLoaded(
                previousState.organisations,
                notificationType: OrganisationsNotificationType.info,
                notificationMessage:
                    "You are already a member of this organisation",
              ),
            );
          } else {
            emit(
              OrganisationsLoaded(
                [],
                notificationType: OrganisationsNotificationType.info,
                notificationMessage:
                    "You are already a member of this organisation",
              ),
            );
            add(FetchOrganisationsEvent());
          }
          return;
        }

        // Get current user's display name
        String? userDisplayName;
        try {
          final userDoc = await firestore.collection('users').doc(uid).get();
          if (userDoc.exists) {
            userDisplayName = userDoc.data()?['displayName'] as String?;
          }
        } catch (e) {
          // Ignore errors, displayName will be null
        }

        // Add user to organisation
        await firestore
            .collection('organisations')
            .doc(orgId)
            .collection('members')
            .doc(uid)
            .set({
              'role': 'member',
              'email': auth.currentUser?.email ?? '',
              'uid': uid,
              'displayName': userDisplayName,
              'status': 'active',
              'addedAt': FieldValue.serverTimestamp(),
              'addedBy': uid,
            });

        add(FetchOrganisationsEvent());
      } catch (e) {
        emit(OrganisationsError(e.toString()));
      }
    });

    on<DeleteOrganisationEvent>((event, emit) async {
      emit(OrganisationsLoading());
      try {
        String uid = auth.currentUser?.uid ?? '';
        if (uid.isEmpty) {
          emit(OrganisationsError("User not authenticated"));
          return;
        }

        // Check if user is a teacher in the organisation
        QuerySnapshot userSnapshot =
            await firestore
                .collection('organisations')
                .doc(event.organisationId)
                .collection('members')
                .where('uid', isEqualTo: uid)
                .get();

        if (userSnapshot.docs.isEmpty) {
          emit(OrganisationsError("User not found in organisation"));
          return;
        }

        Map<String, dynamic> userData =
            userSnapshot.docs.first.data() as Map<String, dynamic>;
        String userRole = userData['role'] ?? 'member';

        if (userRole != 'teacher') {
          emit(
            OrganisationsError("Only full teachers can delete organisations"),
          );
          return;
        }

        // Delete all subcollections first
        List<String> subcollections = [
          'members',
          'projects',
          'projectRequests',
        ];

        for (String subcollection in subcollections) {
          QuerySnapshot subcollectionSnapshot =
              await firestore
                  .collection('organisations')
                  .doc(event.organisationId)
                  .collection(subcollection)
                  .get();

          // Delete all documents in the subcollection
          for (QueryDocumentSnapshot doc in subcollectionSnapshot.docs) {
            await doc.reference.delete();
          }
        }

        // Delete the organisation document
        await firestore
            .collection('organisations')
            .doc(event.organisationId)
            .delete();

        add(FetchOrganisationsEvent());
      } catch (e) {
        emit(OrganisationsError(e.toString()));
      }
    });

    on<LeaveOrganisationEvent>((event, emit) async {
      // Preserve previous state to restore on error
      final previousState = state;
      final shouldShowLoading = previousState is! OrganisationsLoaded;
      if (shouldShowLoading) {
        emit(OrganisationsLoading());
      }

      try {
        String uid = auth.currentUser?.uid ?? '';
        String userEmail = auth.currentUser?.email ?? '';

        if (uid.isEmpty) {
          // Restore previous state on error
          if (previousState is OrganisationsLoaded) {
            emit(previousState);
          } else {
            emit(OrganisationsError("User not authenticated"));
          }
          return;
        }

        // Get the current user's member document
        QuerySnapshot userSnapshot =
            await firestore
                .collection('organisations')
                .doc(event.organisationId)
                .collection('members')
                .where('uid', isEqualTo: uid)
                .get();

        // If not found by uid, try by email
        if (userSnapshot.docs.isEmpty && userEmail.isNotEmpty) {
          userSnapshot =
              await firestore
                  .collection('organisations')
                  .doc(event.organisationId)
                  .collection('members')
                  .where('email', isEqualTo: userEmail)
                  .get();
        }

        if (userSnapshot.docs.isEmpty) {
          // Restore previous state on error
          if (previousState is OrganisationsLoaded) {
            emit(previousState);
          } else {
            emit(OrganisationsError("User not found in organisation"));
          }
          return;
        }

        Map<String, dynamic> userData =
            userSnapshot.docs.first.data() as Map<String, dynamic>;
        String userRole = userData['role'] ?? 'member';
        String userMemberId = userSnapshot.docs.first.id;

        // If user is a teacher, check if they are the last teacher
        if (userRole == 'teacher') {
          QuerySnapshot teachersSnapshot =
              await firestore
                  .collection('organisations')
                  .doc(event.organisationId)
                  .collection('members')
                  .where('role', isEqualTo: 'teacher')
                  .get();

          if (teachersSnapshot.docs.length <= 1) {
            // Emit special state with previous organisations so UI stays intact
            if (previousState is OrganisationsLoaded) {
              emit(
                OrganisationsLeaveBlockedLastTeacher(
                  previousState.organisations,
                ),
              );
            } else {
              emit(
                OrganisationsError(
                  "Cannot leave organisation. You are the last teacher. Please assign another teacher before leaving.",
                ),
              );
            }
            return;
          }
        }

        // Remove the user from the organisation
        await firestore
            .collection('organisations')
            .doc(event.organisationId)
            .collection('members')
            .doc(userMemberId)
            .delete();

        add(FetchOrganisationsEvent());
      } catch (e) {
        // Restore previous state on error
        if (previousState is OrganisationsLoaded) {
          emit(previousState);
        } else {
          emit(OrganisationsError(e.toString()));
        }
      }
    });
  }

  /// Sets up stream subscriptions to listen for membership changes
  void _setupMembershipStreams(String uid, String userEmail) {
    // Cancel existing subscriptions
    _uidMembershipsSubscription?.cancel();
    _emailMembershipsSubscription?.cancel();

    // Reset flags when setting up new streams
    _isInitialMembershipStream = true;
    _isInitialEmailMembershipStream = true;

    // Listen to UID-based memberships
    _uidMembershipsSubscription = firestore
        .collectionGroup('members')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .listen(
          (snapshot) {
            // Skip the first snapshot since we already have the initial data
            if (_isInitialMembershipStream) {
              _isInitialMembershipStream = false;
              return;
            }
            // When memberships change, reload organizations
            add(FetchOrganisationsEvent());
          },
          onError: (error) {
            print('Error in UID memberships stream: $error');
          },
        );

    // Listen to email-based memberships if email is available
    if (userEmail.isNotEmpty) {
      _emailMembershipsSubscription = firestore
          .collectionGroup('members')
          .where('email', isEqualTo: userEmail)
          .snapshots()
          .listen(
            (snapshot) {
              // Skip the first snapshot since we already have the initial data
              if (_isInitialEmailMembershipStream) {
                _isInitialEmailMembershipStream = false;
                return;
              }
              // When memberships change, reload organizations
              add(FetchOrganisationsEvent());
            },
            onError: (error) {
              print('Error in email memberships stream: $error');
            },
          );
    }
  }

  /// Sets up stream subscriptions to listen for organization document changes
  void _setupOrganisationDocumentStreams(
    Set<String> orgIds,
    String uid,
    String userEmail,
  ) {
    // Cancel subscriptions for organizations that are no longer in the list
    final orgIdsToRemove = _currentOrgIds.difference(orgIds);
    for (String orgId in orgIdsToRemove) {
      _orgDocumentSubscriptions[orgId]?.cancel();
      _orgDocumentSubscriptions.remove(orgId);
      _isInitialOrgDocumentStream.remove(orgId);
    }

    // Add subscriptions for new organizations
    for (String orgId in orgIds) {
      if (!_orgDocumentSubscriptions.containsKey(orgId)) {
        // Mark this as an initial stream for this org
        _isInitialOrgDocumentStream[orgId] = true;

        _orgDocumentSubscriptions[orgId] = firestore
            .collection('organisations')
            .doc(orgId)
            .snapshots()
            .listen(
              (snapshot) {
                if (!snapshot.exists) {
                  // Organisation deleted: refresh organisations and clean up
                  add(FetchOrganisationsEvent());
                  _orgDocumentSubscriptions[orgId]?.cancel();
                  _orgDocumentSubscriptions.remove(orgId);
                  _isInitialOrgDocumentStream.remove(orgId);
                  return;
                }

                // Skip the first snapshot since we already have the initial data
                if (_isInitialOrgDocumentStream[orgId] == true) {
                  _isInitialOrgDocumentStream[orgId] = false;
                  return;
                }

                // When an organization document changes, reload organizations
                add(FetchOrganisationsEvent());
              },
              onError: (error) {
                print(
                  'Error in organisation document stream for $orgId: $error',
                );
              },
            );
      } else {
        // Organization already has a subscription, make sure it's not marked as initial
        _isInitialOrgDocumentStream[orgId] = false;
      }
    }

    _currentOrgIds = orgIds;
  }

  @override
  Future<void> close() {
    _uidMembershipsSubscription?.cancel();
    _emailMembershipsSubscription?.cancel();
    for (var subscription in _orgDocumentSubscriptions.values) {
      subscription.cancel();
    }
    _orgDocumentSubscriptions.clear();
    return super.close();
  }
}
