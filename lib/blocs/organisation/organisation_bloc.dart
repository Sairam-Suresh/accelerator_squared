import 'dart:async';

import 'package:accelerator_squared/models/organisation.dart';
import 'package:accelerator_squared/models/projects.dart';
import 'package:accelerator_squared/util/util.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

part 'organisation_event.dart';
part 'organisation_state.dart';

class OrganisationBloc extends Bloc<OrganisationEvent, OrganisationState> {
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String _organisationId;
  final Organisation? _initialState;
  StreamSubscription<DocumentSnapshot>? _memberRoleSubscription;
  String? _currentMemberDocId;
  StreamSubscription<DocumentSnapshot>? _orgDocSubscription;

  OrganisationBloc({required String organisationId, Organisation? initialState})
    : _organisationId = organisationId,
      _initialState = initialState,
      super(OrganisationInitial()) {
    on<FetchOrganisationEvent>((event, emit) async {
      // If we have initial data, use it directly without showing loading state
      if (event.initialData != null) {
        emit(OrganisationLoaded.fromOrganisationObject(event.initialData!));
        // Set up stream subscription for role changes even with initial data
        // Schedule it as a microtask to avoid blocking the emit
        Future.microtask(() {
          _setupMemberRoleStreamIfNeeded();
          _setupOrganisationDeletionStream();
        });
        return;
      }

      // Only show loading state if we don't have initial data
      emit(OrganisationLoading());

      try {
        String uid = auth.currentUser?.uid ?? '';
        String userEmail = auth.currentUser?.email ?? '';

        if (uid.isEmpty) {
          emit(OrganisationError("User not authenticated"));
          return;
        }

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
          emit(
            OrganisationError(
              "It cannot be possible to call an Organisation that doesn't exist. Please check your organisation ID.",
            ),
          ); // TODO: Validate if organisations == [] here
          return;
        }

        // Find the member document ID for this organisation
        QueryDocumentSnapshot? memberDoc;
        for (var doc in allMemberships) {
          final docPath = doc.reference.path;
          if (docPath.contains('/organisations/$_organisationId/members/')) {
            memberDoc = doc;
            break;
          }
        }

        final organisation = (await loadOrganisationDataById(
          firestore,
          organisationId,
          uid,
          userEmail,
        ))!;

        emit(
          OrganisationLoaded.fromOrganisationObject(organisation),
        );

        // Set up stream subscriptions
        if (memberDoc != null) {
          _currentMemberDocId = memberDoc.id;
          _setupMemberRoleStream();
        }
        _setupOrganisationDeletionStream();
      } catch (e) {
        if (e.toString().contains('timeout')) {
          emit(
            OrganisationError(
              "Request timed out. Please check your connection and try again.",
            ),
          );
        } else {
          emit(OrganisationError(e.toString()));
        }
      }
    });

    on<_OrganisationDeletedInternalEvent>((event, emit) async {
      emit(OrganisationDeleted());
    });

    on<CreateProjectEvent>((event, emit) async {
      emit(OrganisationLoading());
      try {
        String uid = auth.currentUser?.uid ?? '';
        if (uid.isEmpty) {
          emit(OrganisationError("User not authenticated"));
          return;
        }

        QuerySnapshot userSnapshot =
            await firestore
                .collection('organisations')
                .doc(_organisationId)
                .collection('members')
                .where('uid', isEqualTo: uid)
                .get();

        // If not found by uid, try by email
        if (userSnapshot.docs.isEmpty &&
            auth.currentUser?.email != null &&
            auth.currentUser!.email!.isNotEmpty) {
          userSnapshot =
              await firestore
                  .collection('organisations')
                  .doc(_organisationId)
                  .collection('members')
                  .where('email', isEqualTo: auth.currentUser!.email)
                  .get();
        }

        if (userSnapshot.docs.isEmpty) {
          emit(OrganisationError("User not found in organisation"));
          return;
        }

        Map<String, dynamic> userData =
            userSnapshot.docs.first.data() as Map<String, dynamic>;
        String userRole = userData['role'] ?? 'member';

        if (userRole != 'teacher' && userRole != 'student_teacher') {
          emit(
            OrganisationError(
              "Only teachers and student teachers can create projects directly. Please submit a project request instead.",
            ),
          );
          return;
        }

        // Verify that all member emails exist in the organisation
        List<String> verifiedMemberEmails = [];
        for (String email in event.memberEmails) {
          QuerySnapshot memberSnapshot =
              await firestore
                  .collection('organisations')
                  .doc(_organisationId)
                  .collection('members')
                  .where('email', isEqualTo: email)
                  .get();

          if (memberSnapshot.docs.isNotEmpty) {
            Map<String, dynamic> memberData =
                memberSnapshot.docs.first.data() as Map<String, dynamic>;
            String memberRole = memberData['role'] ?? 'member';

            if (memberRole != 'teacher') {
              verifiedMemberEmails.add(email);
            }
          }
        }

        if (verifiedMemberEmails.isEmpty) {
          emit(
            OrganisationError(
              "You must add at least 1 non-teacher member to the project",
            ),
          );
          return;
        }

        String projectId = const Uuid().v4();
        DocumentReference projectRef = firestore
            .collection('organisations')
            .doc(_organisationId)
            .collection('projects')
            .doc(projectId);

        await projectRef.set({
          'title': event.title,
          'description': event.description,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdBy': uid,
        });

        await projectRef.collection('members').doc(uid).set({
          'role': 'teacher',
          'email': auth.currentUser?.email ?? '',
          'uid': uid,
          'status': 'active',
          'addedAt': FieldValue.serverTimestamp(),
        });

        // Add all teachers and student_teachers from the organisation to the project
        QuerySnapshot allTeachersSnapshot = await firestore
            .collection('organisations')
            .doc(_organisationId)
            .collection('members')
            .where('role', whereIn: ['teacher', 'student_teacher'])
            .get();

        // Track added identifiers (UIDs and emails) to avoid duplicates
        Set<String> addedUids = {uid}; // Creator is already added
        Set<String> addedEmails = {auth.currentUser?.email ?? ''}; // Creator's email

        for (var teacherDoc in allTeachersSnapshot.docs) {
          final teacherData = teacherDoc.data() as Map<String, dynamic>;
          final teacherRole = teacherData['role'] ?? 'member';
          final teacherEmail = teacherData['email'] ?? '';
          final teacherUid = teacherData['uid'] as String?;

          // Skip if already added (creator) - check by UID or email
          if ((teacherUid != null && teacherUid.isNotEmpty && addedUids.contains(teacherUid)) ||
              (teacherEmail.isNotEmpty && addedEmails.contains(teacherEmail))) {
            continue;
          }

          // Use UID as document ID if available, otherwise use email
          String docId = (teacherUid != null && teacherUid.isNotEmpty) ? teacherUid : teacherEmail;

          await projectRef.collection('members').doc(docId).set({
            'role': teacherRole, // Preserve the role (teacher or student_teacher)
            'email': teacherEmail,
            'status': 'active',
            'addedAt': FieldValue.serverTimestamp(),
            if (teacherUid != null && teacherUid.isNotEmpty) 'uid': teacherUid,
          });

          // Track added identifiers
          if (teacherUid != null && teacherUid.isNotEmpty) {
            addedUids.add(teacherUid);
          }
          if (teacherEmail.isNotEmpty) {
            addedEmails.add(teacherEmail);
          }
        }

        // Add the verified member emails to the project
        for (String email in verifiedMemberEmails) {
          // Try to find the user's UID by email
          String? memberUid;
          try {
            final methods = await auth.fetchSignInMethodsForEmail(email);
            if (methods.isNotEmpty) {
              final userQuery =
                  await firestore
                      .collection('users')
                      .where('email', isEqualTo: email)
                      .limit(1)
                      .get();
              if (userQuery.docs.isNotEmpty) {
                memberUid = userQuery.docs.first.id;
              }
            }
          } catch (e) {
            // Ignore errors, fallback to email as ID
          }
          String docId = memberUid ?? email;
          await projectRef.collection('members').doc(docId).set({
            'role': 'member',
            'email': email,
            'status': 'active',
            'addedAt': FieldValue.serverTimestamp(),
            if (memberUid != null) 'uid': memberUid,
          });
        }

        // Copy existing organisation-wide milestones to the new project
        // Add a small delay to ensure the project document is fully written
        await Future.delayed(Duration(milliseconds: 100));
        await _copyOrgWideMilestonesToNewProject(_organisationId, projectId);

        // Add another small delay to ensure milestones are written before fetching
        await Future.delayed(Duration(milliseconds: 100));

        add(FetchOrganisationEvent());
      } catch (e) {
        emit(OrganisationError(e.toString()));
      }
    });

    on<SubmitProjectRequestEvent>((event, emit) async {
      emit(OrganisationLoading());
      try {
        String uid = auth.currentUser?.uid ?? '';
        if (uid.isEmpty) {
          emit(OrganisationError("User not authenticated"));
          return;
        }

        List<String> filteredMemberEmails = [];
        for (String email in event.memberEmails) {
          QuerySnapshot memberSnapshot =
              await firestore
                  .collection('organisations')
                  .doc(_organisationId)
                  .collection('members')
                  .where('email', isEqualTo: email)
                  .get();

          if (memberSnapshot.docs.isNotEmpty) {
            Map<String, dynamic> memberData =
                memberSnapshot.docs.first.data() as Map<String, dynamic>;
            String memberRole = memberData['role'] ?? 'member';

            if (memberRole != 'teacher') {
              filteredMemberEmails.add(email);
            }
          } else {
            filteredMemberEmails.add(email);
          }
        }

        String requestId = const Uuid().v4();
        DocumentReference requestRef = firestore
            .collection('organisations')
            .doc(_organisationId)
            .collection('projectRequests')
            .doc(requestId);

        await requestRef.set({
          'title': event.title,
          'description': event.description,
          'requestedBy': auth.currentUser?.displayName ?? '',
          'requesterEmail': auth.currentUser?.email ?? '',
          'requestedAt': FieldValue.serverTimestamp(),
          'memberEmails': filteredMemberEmails,
        });

        add(FetchOrganisationEvent());
      } catch (e) {
        emit(OrganisationError(e.toString()));
      }
    });

    on<ApproveProjectRequestEvent>((event, emit) async {
      emit(OrganisationLoading());
      try {
        String uid = auth.currentUser?.uid ?? '';
        if (uid.isEmpty) {
          emit(OrganisationError("User not authenticated"));
          return;
        }

        QuerySnapshot userSnapshot =
            await firestore
                .collection('organisations')
                .doc(_organisationId)
                .collection('members')
                .where('uid', isEqualTo: uid)
                .get();

        if (userSnapshot.docs.isEmpty) {
          emit(OrganisationError("User not found in organisation"));
          return;
        }

        Map<String, dynamic> userData =
            userSnapshot.docs.first.data() as Map<String, dynamic>;
        String userRole = userData['role'] ?? 'member';

        if (userRole != 'teacher') {
          emit(OrganisationError("Only teachers can approve project requests"));
          return;
        }

        DocumentSnapshot requestDoc =
            await firestore
                .collection('organisations')
                .doc(_organisationId)
                .collection('projectRequests')
                .doc(event.requestId)
                .get();

        if (!requestDoc.exists) {
          emit(OrganisationError("Project request not found"));
          return;
        }

        Map<String, dynamic> requestData =
            requestDoc.data() as Map<String, dynamic>;
        String projectId = const Uuid().v4();
        DocumentReference projectRef = firestore
            .collection('organisations')
            .doc(_organisationId)
            .collection('projects')
            .doc(projectId);

        await projectRef.set({
          'title': requestData['title'],
          'description': requestData['description'],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdBy': uid,
        });

        await projectRef.collection('members').doc(uid).set({
          'role': 'teacher',
          'email': auth.currentUser?.email ?? '',
          'uid': uid,
          'status': 'active',
          'addedAt': FieldValue.serverTimestamp(),
        });

        // Add all teachers and student_teachers from the organisation to the project
        QuerySnapshot allTeachersSnapshot = await firestore
            .collection('organisations')
            .doc(_organisationId)
            .collection('members')
            .where('role', whereIn: ['teacher', 'student_teacher'])
            .get();

        // Track added identifiers (UIDs and emails) to avoid duplicates
        Set<String> addedUids = {uid}; // Approving teacher is already added
        Set<String> addedEmails = {auth.currentUser?.email ?? ''}; // Approving teacher's email

        for (var teacherDoc in allTeachersSnapshot.docs) {
          final teacherData = teacherDoc.data() as Map<String, dynamic>;
          final teacherRole = teacherData['role'] ?? 'member';
          final teacherEmail = teacherData['email'] ?? '';
          final teacherUid = teacherData['uid'] as String?;

          // Skip if already added (approving teacher) - check by UID or email
          if ((teacherUid != null && teacherUid.isNotEmpty && addedUids.contains(teacherUid)) ||
              (teacherEmail.isNotEmpty && addedEmails.contains(teacherEmail))) {
            continue;
          }

          // Use UID as document ID if available, otherwise use email
          String docId = (teacherUid != null && teacherUid.isNotEmpty) ? teacherUid : teacherEmail;

          await projectRef.collection('members').doc(docId).set({
            'role': teacherRole, // Preserve the role (teacher or student_teacher)
            'email': teacherEmail,
            'status': 'active',
            'addedAt': FieldValue.serverTimestamp(),
            if (teacherUid != null && teacherUid.isNotEmpty) 'uid': teacherUid,
          });

          // Track added identifiers
          if (teacherUid != null && teacherUid.isNotEmpty) {
            addedUids.add(teacherUid);
          }
          if (teacherEmail.isNotEmpty) {
            addedEmails.add(teacherEmail);
          }
        }

        await firestore
            .collection('organisations')
            .doc(_organisationId)
            .collection('projectRequests')
            .doc(event.requestId)
            .delete();

        add(FetchOrganisationEvent());
      } catch (e) {
        emit(OrganisationError(e.toString()));
      }
    });

    on<RejectProjectRequestEvent>((event, emit) async {
      emit(OrganisationLoading());
      try {
        String uid = auth.currentUser?.uid ?? '';
        if (uid.isEmpty) {
          emit(OrganisationError("User not authenticated"));
          return;
        }

        QuerySnapshot userSnapshot =
            await firestore
                .collection('organisations')
                .doc(_organisationId)
                .collection('members')
                .where('uid', isEqualTo: uid)
                .get();

        if (userSnapshot.docs.isEmpty) {
          emit(OrganisationError("User not found in organisation"));
          return;
        }

        Map<String, dynamic> userData =
            userSnapshot.docs.first.data() as Map<String, dynamic>;
        String userRole = userData['role'] ?? 'member';

        if (userRole != 'teacher') {
          emit(OrganisationError("Only teachers can reject project requests"));
          return;
        }

        await firestore
            .collection('organisations')
            .doc(_organisationId)
            .collection('projectRequests')
            .doc(event.requestId)
            .delete();

        add(FetchOrganisationEvent());
      } catch (e) {
        emit(OrganisationError(e.toString()));
      }
    });

    on<RefreshJoinCodeEvent>((event, emit) async {
      emit(OrganisationLoading());
      try {
        String uid = auth.currentUser?.uid ?? '';
        if (uid.isEmpty) {
          emit(OrganisationError("User not authenticated"));
          return;
        }

        // Check if user is a teacher in the organisation
        QuerySnapshot userSnapshot =
            await firestore
                .collection('organisations')
                .doc(_organisationId)
                .collection('members')
                .where('uid', isEqualTo: uid)
                .get();

        if (userSnapshot.docs.isEmpty) {
          emit(OrganisationError("User not found in organisation"));
          return;
        }

        Map<String, dynamic> userData =
            userSnapshot.docs.first.data() as Map<String, dynamic>;
        String userRole = userData['role'] ?? 'member';

        if (userRole != 'teacher') {
          emit(OrganisationError("Only teachers can refresh join codes"));
          return;
        }

        // Generate new join code
        String newJoinCode = generateJoinCode();

        // Update the organisation document
        await firestore.collection('organisations').doc(_organisationId).update(
          {'joinCode': newJoinCode},
        );

        add(FetchOrganisationEvent());
      } catch (e) {
        emit(OrganisationError(e.toString()));
      }
    });

    on<DeleteProjectEvent>((event, emit) async {
      emit(OrganisationLoading());
      try {
        String uid = auth.currentUser?.uid ?? '';
        if (uid.isEmpty) {
          emit(OrganisationError("User not authenticated"));
          return;
        }

        // Check if user is a teacher in the organisation
        QuerySnapshot userSnapshot =
            await firestore
                .collection('organisations')
                .doc(_organisationId)
                .collection('members')
                .where('uid', isEqualTo: uid)
                .get();

        if (userSnapshot.docs.isEmpty) {
          emit(OrganisationError("User not found in organisation"));
          return;
        }

        Map<String, dynamic> userData =
            userSnapshot.docs.first.data() as Map<String, dynamic>;
        String userRole = userData['role'] ?? 'member';

        if (userRole != 'teacher') {
          emit(OrganisationError("Only teachers can delete projects"));
          return;
        }

        // Delete the project and all its subcollections
        await firestore
            .collection('organisations')
            .doc(_organisationId)
            .collection('projects')
            .doc(event.projectId)
            .delete();

        add(FetchOrganisationEvent());
      } catch (e) {
        emit(OrganisationError(e.toString()));
      }
    });

    on<ChangeMemberRoleEvent>((event, emit) async {
      emit(OrganisationLoading());
      try {
        String uid = auth.currentUser?.uid ?? '';
        String userEmail = auth.currentUser?.email ?? '';
        if (uid.isEmpty) {
          emit(OrganisationError("User not authenticated"));
          return;
        }

        // Check if user has permission to change roles
        QuerySnapshot userSnapshot =
            await firestore
                .collection('organisations')
                .doc(_organisationId)
                .collection('members')
                .where('uid', isEqualTo: uid)
                .get();

        // If not found by uid, try by email
        if (userSnapshot.docs.isEmpty && userEmail.isNotEmpty) {
          userSnapshot =
              await firestore
                  .collection('organisations')
                  .doc(_organisationId)
                  .collection('members')
                  .where('email', isEqualTo: userEmail)
                  .get();
        }

        if (userSnapshot.docs.isEmpty) {
          emit(OrganisationError("User not found in organisation"));
          return;
        }

        Map<String, dynamic> userData =
            userSnapshot.docs.first.data() as Map<String, dynamic>;
        String userRole = userData['role'] ?? 'member';

        if (userRole != 'teacher' && userRole != 'student_teacher') {
          emit(
            OrganisationError(
              "Only teachers and student teachers can change member roles",
            ),
          );
          return;
        }

        // Update the member's role
        await firestore
            .collection('organisations')
            .doc(_organisationId)
            .collection('members')
            .doc(event.memberId)
            .update({'role': event.newRole});

        add(FetchOrganisationEvent());
      } catch (e) {
        emit(OrganisationError(e.toString()));
      }
    });

    on<RemoveMemberEvent>((event, emit) async {
      emit(OrganisationLoading());
      try {
        String uid = auth.currentUser?.uid ?? '';
        if (uid.isEmpty) {
          emit(OrganisationError("User not authenticated"));
          return;
        }

        // Check if user has permission to remove members
        QuerySnapshot userSnapshot =
            await firestore
                .collection('organisations')
                .doc(_organisationId)
                .collection('members')
                .where('uid', isEqualTo: uid)
                .get();

        if (userSnapshot.docs.isEmpty) {
          emit(OrganisationError("User not found in organisation"));
          return;
        }

        Map<String, dynamic> userData =
            userSnapshot.docs.first.data() as Map<String, dynamic>;
        String userRole = userData['role'] ?? 'member';

        if (userRole != 'teacher' && userRole != 'student_teacher') {
          emit(
            OrganisationError(
              "Only teachers and student teachers can remove members",
            ),
          );
          return;
        }

        // Remove the member
        await firestore
            .collection('organisations')
            .doc(_organisationId)
            .collection('members')
            .doc(event.memberId)
            .delete();

        add(FetchOrganisationEvent());
      } catch (e) {
        emit(OrganisationError(e.toString()));
      }
    });

    on<UpdateOrganisationEvent>((event, emit) async {
      emit(OrganisationLoading());
      try {
        String uid = auth.currentUser?.uid ?? '';
        String userEmail = auth.currentUser?.email ?? '';

        if (uid.isEmpty) {
          emit(OrganisationError("User not authenticated"));
          return;
        }

        // Check if user is a teacher or student teacher
        QuerySnapshot userSnapshot =
            await firestore
                .collection('organisations')
                .doc(_organisationId)
                .collection('members')
                .where('uid', isEqualTo: uid)
                .get();

        // If not found by uid, try by email
        if (userSnapshot.docs.isEmpty && userEmail.isNotEmpty) {
          userSnapshot =
              await firestore
                  .collection('organisations')
                  .doc(_organisationId)
                  .collection('members')
                  .where('email', isEqualTo: userEmail)
                  .get();
        }

        if (userSnapshot.docs.isEmpty) {
          emit(OrganisationError("User not found in organisation"));
          return;
        }

        Map<String, dynamic> userData =
            userSnapshot.docs.first.data() as Map<String, dynamic>;
        String userRole = userData['role'] ?? 'member';

        if (userRole != 'teacher' && userRole != 'student_teacher') {
          emit(
            OrganisationError(
              "Only teachers and student teachers can update organisation information",
            ),
          );
          return;
        }

        // Update the organisation document
        await firestore.collection('organisations').doc(_organisationId).update(
          {'name': event.name, 'description': event.description},
        );

        add(FetchOrganisationEvent());
      } catch (e) {
        emit(OrganisationError(e.toString()));
      }
    });

    on<SubmitMilestoneReviewRequestEvent>((event, emit) async {
      emit(OrganisationLoading());
      try {
        String uid = auth.currentUser?.uid ?? '';
        if (uid.isEmpty) {
          emit(OrganisationError("User not authenticated"));
          return;
        }
        String requestId = const Uuid().v4();
        DocumentReference requestRef = firestore
            .collection('organisations')
            .doc(_organisationId)
            .collection('milestoneReviewRequests')
            .doc(requestId);

        await requestRef.set({
          'id': requestId,
          'milestoneId': event.milestoneId,
          'milestoneName': event.milestoneName,
          'projectId': event.projectId,
          'projectName': event.projectName,
          'isOrgWide': event.isOrgWide,
          'dueDate': event.dueDate,
          'sentForReviewAt': FieldValue.serverTimestamp(),
        });

        // Update the milestone's pendingReview attribute in the project
        await firestore
            .collection('organisations')
            .doc(_organisationId)
            .collection('projects')
            .doc(event.projectId)
            .collection('milestones')
            .doc(event.milestoneId)
            .update({'pendingReview': true});

        add(FetchOrganisationEvent());
      } catch (e) {
        emit(OrganisationError(e.toString()));
      }
    });

    on<UnsendMilestoneReviewRequestEvent>((event, emit) async {
      emit(OrganisationLoading());
      try {
        // Find and delete the milestone review request for this milestone
        final query =
            await firestore
                .collection('organisations')
                .doc(_organisationId)
                .collection('milestoneReviewRequests')
                .where('milestoneId', isEqualTo: event.milestoneId)
                .where('projectId', isEqualTo: event.projectId)
                .get();
        for (final doc in query.docs) {
          await doc.reference.delete();
        }
        // Set pendingReview to false on the milestone
        await firestore
            .collection('organisations')
            .doc(_organisationId)
            .collection('projects')
            .doc(event.projectId)
            .collection('milestones')
            .doc(event.milestoneId)
            .update({'pendingReview': false});
        add(FetchOrganisationEvent());
      } catch (e) {
        emit(OrganisationError(e.toString()));
      }
    });

    on<UpdateUserRoleEvent>((event, emit) {
      final currentState = state;
      if (currentState is OrganisationLoaded && currentState.userRole != event.newRole) {
        // Create a new state with updated role
        final updatedState = OrganisationLoaded(
          id: currentState.id,
          name: currentState.name,
          description: currentState.description,
          students: currentState.students,
          projects: currentState.projects,
          projectRequests: currentState.projectRequests,
          milestoneReviewRequests: currentState.milestoneReviewRequests,
          memberCount: currentState.memberCount,
          userRole: event.newRole,
          joinCode: currentState.joinCode,
        );
        emit(updatedState);
      }
    });

    if (_initialState != null) {
      add(FetchOrganisationEvent(initialData: _initialState));
    } else {
      add(FetchOrganisationEvent());
    }
  }

  /// Sets up a stream subscription if the member document ID is not yet known
  Future<void> _setupMemberRoleStreamIfNeeded() async {
    if (_currentMemberDocId != null) {
      _setupMemberRoleStream();
      return;
    }

    // Try to find the member document ID
    try {
      String uid = auth.currentUser?.uid ?? '';
      String userEmail = auth.currentUser?.email ?? '';

      if (uid.isEmpty) return;

      QuerySnapshot uidMembersSnapshot = await firestore
          .collection('organisations')
          .doc(_organisationId)
          .collection('members')
          .where('uid', isEqualTo: uid)
          .get()
          .timeout(const Duration(seconds: 5));

      QuerySnapshot emailMembersSnapshot;
      if (userEmail.isNotEmpty) {
        emailMembersSnapshot = await firestore
            .collection('organisations')
            .doc(_organisationId)
            .collection('members')
            .where('email', isEqualTo: userEmail)
            .get()
            .timeout(const Duration(seconds: 5));
      } else {
        emailMembersSnapshot = uidMembersSnapshot;
      }

      QuerySnapshot membersSnapshot = uidMembersSnapshot.docs.isNotEmpty
          ? uidMembersSnapshot
          : emailMembersSnapshot;

      if (membersSnapshot.docs.isNotEmpty) {
        _currentMemberDocId = membersSnapshot.docs.first.id;
        _setupMemberRoleStream();
      }
    } catch (e) {
      // Silently handle errors
      print('Error setting up member role stream: $e');
    }
  }

  /// Sets up a stream subscription to listen for changes to the user's member role
  void _setupMemberRoleStream() {
    // Cancel existing subscription if any
    _memberRoleSubscription?.cancel();

    if (_currentMemberDocId == null) return;

    final memberDocRef = firestore
        .collection('organisations')
        .doc(_organisationId)
        .collection('members')
        .doc(_currentMemberDocId);

    // Track if this is the first snapshot to skip it (initial state already loaded)
    bool isFirstSnapshot = true;

    _memberRoleSubscription = memberDocRef.snapshots().listen(
      (snapshot) {
        if (!snapshot.exists) return;

        final memberData = snapshot.data();
        if (memberData == null) return;

        final newRole = memberData['role'] ?? 'member';

        // Skip the first snapshot since we already have the initial data
        // This prevents the stream from triggering an update on the initial load
        if (isFirstSnapshot) {
          isFirstSnapshot = false;
          return;
        }

        // Compare against the current state's role to avoid unnecessary updates
        final currentState = state;
        if (currentState is OrganisationLoaded) {
          // Only update if the role actually changed
          if (currentState.userRole != newRole) {
            // Dispatch an event to update the role
            add(UpdateUserRoleEvent(newRole: newRole));
          }
        }
      },
      onError: (error) {
        // Silently handle stream errors to prevent crashes
        print('Error in member role stream: $error');
      },
    );
  }

  /// Listens to the organisation document and emits OrganisationDeleted if removed
  void _setupOrganisationDeletionStream() {
    _orgDocSubscription?.cancel();
    _orgDocSubscription = firestore
        .collection('organisations')
        .doc(_organisationId)
        .snapshots()
        .listen(
      (snapshot) {
        if (!snapshot.exists) {
          // Organisation document deleted; inform UI to navigate away
          add(_OrganisationDeletedInternalEvent());
        }
      },
      onError: (_) {},
    );
  }

  @override
  Future<void> close() {
    _memberRoleSubscription?.cancel();
    _orgDocSubscription?.cancel();
    return super.close();
  }

  /// Copies existing organisation-wide milestones to a new project
  Future<void> _copyOrgWideMilestonesToNewProject(
    String orgId,
    String newProjectId,
  ) async {
    try {
      print(
        '[OrganisationBloc] Copying org-wide milestones to new project: $newProjectId',
      );

      // Get all existing projects in the organisation (excluding the new one)
      final projectsSnapshot =
          await firestore
              .collection('organisations')
              .doc(orgId)
              .collection('projects')
              .where(FieldPath.documentId, isNotEqualTo: newProjectId)
              .get();

      print(
        '[OrganisationBloc] Found ${projectsSnapshot.docs.length} existing projects',
      );

      if (projectsSnapshot.docs.isEmpty) {
        print('[OrganisationBloc] No existing projects, nothing to copy');
        return; // No existing projects, nothing to copy
      }

      // Collect all milestones from all existing projects
      final allMilestones = <Map<String, dynamic>>[];
      for (final projectDoc in projectsSnapshot.docs) {
        final milestonesSnapshot =
            await firestore
                .collection('organisations')
                .doc(orgId)
                .collection('projects')
                .doc(projectDoc.id)
                .collection('milestones')
                .get();

        print(
          '[OrganisationBloc] Project ${projectDoc.id} has ${milestonesSnapshot.docs.length} milestones',
        );

        for (final milestoneDoc in milestonesSnapshot.docs) {
          final milestoneData = milestoneDoc.data();
          milestoneData['projectId'] = projectDoc.id;
          allMilestones.add(milestoneData);
        }
      }

      print(
        '[OrganisationBloc] Total milestones collected: ${allMilestones.length}',
      );

      // Find sharedId values that appear in every existing project
      final sharedIdCounts = <String, int>{};
      for (final milestone in allMilestones) {
        final sharedId = milestone['sharedId'];
        if (sharedId != null && sharedId.toString().isNotEmpty) {
          sharedIdCounts[sharedId] = (sharedIdCounts[sharedId] ?? 0) + 1;
        }
      }

      print('[OrganisationBloc] SharedId counts: $sharedIdCounts');

      // Only include milestones that appear in every existing project (org-wide)
      final orgWideSharedIds =
          sharedIdCounts.entries
              .where((entry) => entry.value == projectsSnapshot.docs.length)
              .map((entry) => entry.key)
              .toSet();

      print('[OrganisationBloc] Org-wide sharedIds: $orgWideSharedIds');

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

      // Copy each org-wide milestone to the new project
      print(
        '[OrganisationBloc] Copying ${orgWideMilestones.length} org-wide milestones to new project',
      );
      for (final milestone in orgWideMilestones) {
        final milestoneData = Map<String, dynamic>.from(milestone);
        // Remove projectId as it's not part of the milestone document
        milestoneData.remove('projectId');
        // Ensure new project's milestones start as incomplete and not pending review
        milestoneData['isCompleted'] = false;
        milestoneData['pendingReview'] = false;

        print(
          '[OrganisationBloc] Copying milestone: ${milestone['name']} with sharedId: ${milestone['sharedId']}',
        );

        await firestore
            .collection('organisations')
            .doc(orgId)
            .collection('projects')
            .doc(newProjectId)
            .collection('milestones')
            .doc(milestone['sharedId'])
            .set(milestoneData);
      }

      // If no org-wide milestones found, copy all milestones from the first project as a fallback
      if (orgWideMilestones.isEmpty && allMilestones.isNotEmpty) {
        print(
          '[OrganisationBloc] No org-wide milestones found, copying all milestones from first project as fallback',
        );
        final firstProjectMilestones =
            allMilestones
                .where((m) => m['projectId'] == projectsSnapshot.docs.first.id)
                .toList();

        for (final milestone in firstProjectMilestones) {
          final milestoneData = Map<String, dynamic>.from(milestone);
          milestoneData.remove('projectId');

          // Generate a new sharedId for these milestones
          final newSharedId = const Uuid().v4();
          milestoneData['sharedId'] = newSharedId;
          // Ensure new project's milestones start as incomplete and not pending review
          milestoneData['isCompleted'] = false;
          milestoneData['pendingReview'] = false;

          print(
            '[OrganisationBloc] Copying fallback milestone: ${milestone['name']} with new sharedId: $newSharedId',
          );

          await firestore
              .collection('organisations')
              .doc(orgId)
              .collection('projects')
              .doc(newProjectId)
              .collection('milestones')
              .doc(newSharedId)
              .set(milestoneData);
        }
      }

      print(
        '[OrganisationBloc] Successfully copied ${orgWideMilestones.length} milestones to new project',
      );
    } catch (e) {
      print('Error copying org-wide milestones: $e');
      // Don't throw - this shouldn't fail project creation
    }
  }
}
