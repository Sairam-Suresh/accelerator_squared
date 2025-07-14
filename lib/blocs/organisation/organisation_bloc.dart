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

  OrganisationBloc({required String organisationId, Organisation? initialState})
    : _organisationId = organisationId,
      _initialState = initialState,
      super(OrganisationInitial()) {
    on<FetchOrganisationEvent>((event, emit) async {
      emit(OrganisationLoading());

      if (event.initialData != null) {
        emit(OrganisationLoaded.fromOrganisationObject(event.initialData!));
        return;
      }

      try {
        String uid = auth.currentUser?.uid ?? '';
        String userEmail = auth.currentUser?.email ?? '';

        if (uid.isEmpty) {
          emit(OrganisationError("User not authenticated"));
          return;
        }

        List<Organisation> organisations = [];

        QuerySnapshot uidMemberships = await firestore
            .collectionGroup('members')
            .where('uid', isEqualTo: uid)
            .get()
            .timeout(const Duration(seconds: 10));

        QuerySnapshot emailMemberships;

        if (uidMemberships.docs.isEmpty && userEmail.isNotEmpty) {
          emailMemberships = await firestore
              .collectionGroup('members')
              .where('email', isEqualTo: userEmail)
              .get()
              .timeout(const Duration(seconds: 10));
        } else {
          emailMemberships = uidMemberships;
        }

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

        emit(
          OrganisationLoaded.fromOrganisationObject(
            await loadOrganisationDataById(
              firestore,
              organisationId,
              uid,
              userEmail,
              organisations,
            ),
          ),
        );
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

        await projectRef.collection('members').doc().set({
          'role': 'teacher',
          'email': auth.currentUser?.email ?? '',
          'uid': uid,
          'status': 'active',
          'addedAt': FieldValue.serverTimestamp(),
        });

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

    on<SubmitTaskReviewRequestEvent>((event, emit) async {
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
            .collection('taskReviewRequests')
            .doc(requestId);

        await requestRef.set({
          'id': requestId,
          'taskId': event.taskId,
          'taskName': event.taskName,
          'milestoneId': event.milestoneId,
          'milestoneName': event.milestoneName,
          'projectId': event.projectId,
          'projectName': event.projectName,
          'dueDate': event.dueDate,
          'sentForReviewAt': FieldValue.serverTimestamp(),
        });

        // Update the task's pendingReview attribute in the project
        await firestore
            .collection('organisations')
            .doc(_organisationId)
            .collection('projects')
            .doc(event.projectId)
            .collection('tasks')
            .doc(event.taskId)
            .update({'pendingReview': true});

        add(FetchOrganisationEvent());
      } catch (e) {
        emit(OrganisationError(e.toString()));
      }
    });

    on<UnsendTaskReviewRequestEvent>((event, emit) async {
      emit(OrganisationLoading());
      try {
        // Find and delete the task review request for this task
        final query =
            await firestore
                .collection('organisations')
                .doc(_organisationId)
                .collection('taskReviewRequests')
                .where('taskId', isEqualTo: event.taskId)
                .where('projectId', isEqualTo: event.projectId)
                .get();
        for (final doc in query.docs) {
          await doc.reference.delete();
        }
        // Set pendingReview to false on the task
        await firestore
            .collection('organisations')
            .doc(_organisationId)
            .collection('projects')
            .doc(event.projectId)
            .collection('tasks')
            .doc(event.taskId)
            .update({'pendingReview': false});
        add(FetchOrganisationEvent());
      } catch (e) {
        emit(OrganisationError(e.toString()));
      }
    });

    on<AcceptTaskReviewRequestEvent>((event, emit) async {
      emit(OrganisationLoading());
      try {
        // Remove the task review request
        final query =
            await firestore
                .collection('organisations')
                .doc(_organisationId)
                .collection('taskReviewRequests')
                .where('taskId', isEqualTo: event.taskId)
                .where('projectId', isEqualTo: event.projectId)
                .get();
        for (final doc in query.docs) {
          await doc.reference.delete();
        }
        // Mark the task as completed
        await firestore
            .collection('organisations')
            .doc(_organisationId)
            .collection('projects')
            .doc(event.projectId)
            .collection('tasks')
            .doc(event.taskId)
            .update({'isCompleted': true, 'pendingReview': false});
        add(FetchOrganisationEvent());
      } catch (e) {
        emit(OrganisationError(e.toString()));
      }
    });

    on<DeclineTaskReviewRequestEvent>((event, emit) async {
      emit(OrganisationLoading());
      try {
        // Remove the task review request
        final query =
            await firestore
                .collection('organisations')
                .doc(_organisationId)
                .collection('taskReviewRequests')
                .where('taskId', isEqualTo: event.taskId)
                .where('projectId', isEqualTo: event.projectId)
                .get();
        for (final doc in query.docs) {
          await doc.reference.delete();
        }
        // Set pendingReview to false on the task
        await firestore
            .collection('organisations')
            .doc(_organisationId)
            .collection('projects')
            .doc(event.projectId)
            .collection('tasks')
            .doc(event.taskId)
            .update({'pendingReview': false});
        // Optionally, store feedback somewhere if needed
        add(FetchOrganisationEvent());
      } catch (e) {
        emit(OrganisationError(e.toString()));
      }
    });

    if (_initialState != null) {
      add(FetchOrganisationEvent(initialData: _initialState));
    } else {
      add(FetchOrganisationEvent());
    }
  }
}
