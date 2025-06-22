import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';
import '../../models/organisation.dart';
import '../../models/projects.dart';

part 'organisations_event.dart';
part 'organisations_state.dart';

class OrganisationsBloc extends Bloc<OrganisationsEvent, OrganisationsState> {
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  OrganisationsBloc() : super(OrganisationsInitial()) {
    on<FetchOrganisationsEvent>((event, emit) async {
      emit(OrganisationsLoading());
      try {
        // Get the current user's UID
        String uid = auth.currentUser?.uid ?? '';
        if (uid.isEmpty) {
          emit(OrganisationsError("User not authenticated"));
          return;
        }

        // Fetch all documents in the organisations collection
        QuerySnapshot organisationsSnapshot =
            await firestore.collection('organisations').get();

        // Filter organisations where the members subcollection contains the UID
        List<Organisation> organisations = [];
        for (var doc in organisationsSnapshot.docs) {
          // Find the user by UID field or email
          QuerySnapshot membersSnapshot =
              await firestore
                  .collection('organisations')
                  .doc(doc.id)
                  .collection('members')
                  .where('uid', isEqualTo: uid)
                  .get();

          // If not found by UID, search by email
          if (membersSnapshot.docs.isEmpty) {
            membersSnapshot = await firestore
                .collection('organisations')
                .doc(doc.id)
                .collection('members')
                .where('email', isEqualTo: auth.currentUser?.email)
                .get();
          }

          if (membersSnapshot.docs.isNotEmpty) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            
            // Get the current user's role in this organization
            String userRole = 'member'; // default
            if (membersSnapshot.docs.isNotEmpty) {
              Map<String, dynamic> memberData = membersSnapshot.docs.first.data() as Map<String, dynamic>;
              userRole = memberData['role'] ?? 'member';
            }

            // Fetch projects subcollection for this organisation
            QuerySnapshot projectsSnapshot =
                await firestore
                    .collection('organisations')
                    .doc(doc.id)
                    .collection('projects')
                    .get();

            // Fetch project requests subcollection for this organisation
            QuerySnapshot projectRequestsSnapshot =
                await firestore
                    .collection('organisations')
                    .doc(doc.id)
                    .collection('projectRequests')
                    .get();

            // Fetch members count for this organisation
            QuerySnapshot membersCountSnapshot =
                await firestore
                    .collection('organisations')
                    .doc(doc.id)
                    .collection('members')
                    .get();

            List<Project> projects =
                projectsSnapshot.docs.map((projectDoc) {
                  final projectData = projectDoc.data() as Map<String, dynamic>;
                  // Add id field if not present in Firestore
                  return Project(
                    id: projectDoc.id,
                    name: projectData['title'] ?? projectData['Name'] ?? '',
                    description: projectData['description'] ?? projectData['Description'] ?? '',
                    createdAt:
                        projectData['createdAt'] != null
                            ? (projectData['createdAt'] is String
                                ? DateTime.parse(projectData['createdAt'])
                                : (projectData['createdAt'] as Timestamp)
                                    .toDate())
                            : DateTime.now(),
                    updatedAt:
                        projectData['updatedAt'] != null
                            ? (projectData['updatedAt'] is String
                                ? DateTime.parse(projectData['updatedAt'])
                                : (projectData['updatedAt'] as Timestamp)
                                    .toDate())
                            : DateTime.now(),
                  );
                }).toList();

            List<ProjectRequest> projectRequests =
                projectRequestsSnapshot.docs.map((requestDoc) {
                  final requestData = requestDoc.data() as Map<String, dynamic>;
                  return ProjectRequest(
                    id: requestDoc.id,
                    title: requestData['title'] ?? '',
                    description: requestData['description'] ?? '',
                    requestedBy: requestData['requestedBy'] ?? '',
                    requesterEmail: requestData['requesterEmail'] ?? '',
                    requestedAt:
                        requestData['requestedAt'] != null
                            ? (requestData['requestedAt'] is String
                                ? DateTime.parse(requestData['requestedAt'])
                                : (requestData['requestedAt'] as Timestamp)
                                    .toDate())
                            : DateTime.now(),
                    memberEmails: (requestData['memberEmails'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
                  );
                }).toList();

            organisations.add(
              Organisation(
                id: doc.id,
                name: data['name'] ?? '',
                description: data['description'] ?? '',
                students: [], // Adjust this if students data is nested
                projects: projects,
                projectRequests: projectRequests,
                memberCount: membersCountSnapshot.docs.length,
                userRole: userRole,
              ),
            );
          }
        }

        emit(OrganisationsLoaded(organisations));
      } catch (e) {
        emit(OrganisationsError(e.toString()));
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
        // Generate a random UUID for the organisation document ID
        String orgId = const Uuid().v4();
        DocumentReference orgRef = firestore
            .collection('organisations')
            .doc(orgId);

        // Create the organization document
        await orgRef.set({
          'name': event.name,
          'description': event.description,
        });

        // Add the current user to the members subcollection
        await orgRef.collection('members').doc().set({
          'role': 'teacher',
          'email': auth.currentUser?.email ?? '',
          'uid': uid,
          'status': 'active',
          'addedAt': FieldValue.serverTimestamp(),
          'addedBy': uid,
        });

        // Add other members to the organization
        for (String email in event.memberEmails) {
          // Skip if the email is the same as the teacher
          if (email == auth.currentUser?.email) continue;

          // Create a document with the member's email
          await orgRef.collection('members').doc().set({
            'role': 'member',
            'email': email,
            'status': 'active',
            'addedAt': FieldValue.serverTimestamp(),
            'addedBy': uid,
          });
        }

        // Fetch the updated list
        add(FetchOrganisationsEvent());
      } catch (e) {
        emit(OrganisationsError(e.toString()));
      }
    });

    on<CreateProjectEvent>((event, emit) async {
      emit(OrganisationsLoading());
      try {
        String uid = auth.currentUser?.uid ?? '';
        if (uid.isEmpty) {
          emit(OrganisationsError("User not authenticated"));
          return;
        }

        // Check if user is a teacher (only teachers can create projects directly)
        QuerySnapshot userSnapshot = await firestore
            .collection('organisations')
            .doc(event.organisationId)
            .collection('members')
            .where('uid', isEqualTo: uid)
            .get();

        if (userSnapshot.docs.isEmpty) {
          emit(OrganisationsError("User not found in organization"));
          return;
        }

        Map<String, dynamic> userData = userSnapshot.docs.first.data() as Map<String, dynamic>;
        String userRole = userData['role'] ?? 'member';

        if (userRole != 'teacher') {
          emit(OrganisationsError("Only teachers can create projects directly. Please submit a project request instead."));
          return;
        }

        // Generate a random UUID for the project document ID
        String projectId = const Uuid().v4();
        DocumentReference projectRef = firestore
            .collection('organisations')
            .doc(event.organisationId)
            .collection('projects')
            .doc(projectId);

        // Create the project document
        await projectRef.set({
          'title': event.title,
          'description': event.description,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdBy': uid,
        });

        // Add the current user to the project members subcollection
        await projectRef.collection('members').doc().set({
          'role': 'teacher',
          'email': auth.currentUser?.email ?? '',
          'uid': uid,
          'status': 'active',
          'addedAt': FieldValue.serverTimestamp(),
        });

        // Fetch the updated list
        add(FetchOrganisationsEvent());
      } catch (e) {
        emit(OrganisationsError(e.toString()));
      }
    });

    on<SubmitProjectRequestEvent>((event, emit) async {
      emit(OrganisationsLoading());
      try {
        String uid = auth.currentUser?.uid ?? '';
        if (uid.isEmpty) {
          emit(OrganisationsError("User not authenticated"));
          return;
        }

        // Filter out teachers from member emails (teachers cannot be added to projects)
        List<String> filteredMemberEmails = [];
        for (String email in event.memberEmails) {
          // Check if the email belongs to a teacher
          QuerySnapshot memberSnapshot = await firestore
              .collection('organisations')
              .doc(event.organisationId)
              .collection('members')
              .where('email', isEqualTo: email)
              .get();

          if (memberSnapshot.docs.isNotEmpty) {
            Map<String, dynamic> memberData = memberSnapshot.docs.first.data() as Map<String, dynamic>;
            String memberRole = memberData['role'] ?? 'member';
            
            if (memberRole != 'teacher') {
              filteredMemberEmails.add(email);
            }
          } else {
            // If member not found in organization, assume they're not a teacher
            filteredMemberEmails.add(email);
          }
        }

        // Generate a random UUID for the project request document ID
        String requestId = const Uuid().v4();
        DocumentReference requestRef = firestore
            .collection('organisations')
            .doc(event.organisationId)
            .collection('projectRequests')
            .doc(requestId);

        // Create the project request document
        await requestRef.set({
          'title': event.title,
          'description': event.description,
          'requestedBy': uid,
          'requesterEmail': auth.currentUser?.email ?? '',
          'requestedAt': FieldValue.serverTimestamp(),
          'memberEmails': filteredMemberEmails,
        });

        // Fetch the updated list
        add(FetchOrganisationsEvent());
      } catch (e) {
        emit(OrganisationsError(e.toString()));
      }
    });

    on<ApproveProjectRequestEvent>((event, emit) async {
      emit(OrganisationsLoading());
      try {
        String uid = auth.currentUser?.uid ?? '';
        if (uid.isEmpty) {
          emit(OrganisationsError("User not authenticated"));
          return;
        }

        // Get the project request details
        DocumentSnapshot requestDoc = await firestore
            .collection('organisations')
            .doc(event.organisationId)
            .collection('projectRequests')
            .doc(event.requestId)
            .get();

        if (!requestDoc.exists) {
          emit(OrganisationsError("Project request not found"));
          return;
        }

        Map<String, dynamic> requestData = requestDoc.data() as Map<String, dynamic>;
        List<String> memberEmails = (requestData['memberEmails'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [];

        // Create the actual project
        String projectId = const Uuid().v4();
        DocumentReference projectRef = firestore
            .collection('organisations')
            .doc(event.organisationId)
            .collection('projects')
            .doc(projectId);

        await projectRef.set({
          'title': requestData['title'],
          'description': requestData['description'],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdBy': requestData['requestedBy'],
          'approvedBy': uid,
          'approvedAt': FieldValue.serverTimestamp(),
        });

        // Get requester's role in organization
        QuerySnapshot requesterSnapshot = await firestore
            .collection('organisations')
            .doc(event.organisationId)
            .collection('members')
            .where('uid', isEqualTo: requestData['requestedBy'])
            .get();

        String requesterRole = 'member';
        if (requesterSnapshot.docs.isNotEmpty) {
          Map<String, dynamic> requesterData = requesterSnapshot.docs.first.data() as Map<String, dynamic>;
          requesterRole = requesterData['role'] ?? 'member';
        }

        // Add the requester to the project members with appropriate role
        String projectRole = requesterRole == 'teacher' ? 'teacher' : 
                           requesterRole == 'student_teacher' ? 'student_teacher' : 'member';
        
        await projectRef.collection('members').doc().set({
          'role': projectRole,
          'email': requestData['requesterEmail'],
          'uid': requestData['requestedBy'],
          'status': 'active',
          'addedAt': FieldValue.serverTimestamp(),
        });

        // Add all additional member emails with appropriate roles
        for (final email in memberEmails) {
          // Get member's role in organization
          QuerySnapshot memberSnapshot = await firestore
              .collection('organisations')
              .doc(event.organisationId)
              .collection('members')
              .where('email', isEqualTo: email)
              .get();

          String memberRole = 'member';
          String memberUid = '';
          if (memberSnapshot.docs.isNotEmpty) {
            Map<String, dynamic> memberData = memberSnapshot.docs.first.data() as Map<String, dynamic>;
            memberRole = memberData['role'] ?? 'member';
            memberUid = memberData['uid'] ?? '';
          }

          // Determine project role (teachers cannot be added to projects)
          String projectMemberRole = memberRole == 'student_teacher' ? 'student_teacher' : 'member';

          await projectRef.collection('members').doc().set({
            'role': projectMemberRole,
            'email': email,
            'uid': memberUid,
            'status': 'active',
            'addedAt': FieldValue.serverTimestamp(),
          });
        }

        // Delete the project request after approval
        await firestore
            .collection('organisations')
            .doc(event.organisationId)
            .collection('projectRequests')
            .doc(event.requestId)
            .delete();

        // Fetch the updated list
        add(FetchOrganisationsEvent());
      } catch (e) {
        emit(OrganisationsError(e.toString()));
      }
    });

    on<RejectProjectRequestEvent>((event, emit) async {
      emit(OrganisationsLoading());
      try {
        String uid = auth.currentUser?.uid ?? '';
        if (uid.isEmpty) {
          emit(OrganisationsError("User not authenticated"));
          return;
        }

        // Delete the project request
        await firestore
            .collection('organisations')
            .doc(event.organisationId)
            .collection('projectRequests')
            .doc(event.requestId)
            .delete();

        // Fetch the updated list
        add(FetchOrganisationsEvent());
      } catch (e) {
        emit(OrganisationsError(e.toString()));
      }
    });

    on<ChangeMemberRoleEvent>((event, emit) async {
      emit(OrganisationsLoading());
      try {
        String uid = auth.currentUser?.uid ?? '';
        if (uid.isEmpty) {
          emit(OrganisationsError("User not authenticated"));
          return;
        }

        // Get current user's role to check permissions
        QuerySnapshot currentUserSnapshot = await firestore
            .collection('organisations')
            .doc(event.organisationId)
            .collection('members')
            .where('uid', isEqualTo: uid)
            .get();

        if (currentUserSnapshot.docs.isEmpty) {
          emit(OrganisationsError("User not found in organization"));
          return;
        }

        Map<String, dynamic> currentUserData = currentUserSnapshot.docs.first.data() as Map<String, dynamic>;
        String currentUserRole = currentUserData['role'] ?? 'member';

        // Get target member's current role
        DocumentSnapshot targetMemberDoc = await firestore
            .collection('organisations')
            .doc(event.organisationId)
            .collection('members')
            .doc(event.memberId)
            .get();

        if (!targetMemberDoc.exists) {
          emit(OrganisationsError("Member not found"));
          return;
        }

        Map<String, dynamic> targetMemberData = targetMemberDoc.data() as Map<String, dynamic>;
        String targetMemberRole = targetMemberData['role'] ?? 'member';

        // Check permissions based on role hierarchy
        bool canChangeRole = false;
        if (currentUserRole == 'teacher') {
          // Teachers can change any role
          canChangeRole = true;
        } else if (currentUserRole == 'student_teacher') {
          // Student teachers can only change members to student_teacher or student_teacher to member
          canChangeRole = (targetMemberRole == 'member' && event.newRole == 'student_teacher') ||
                         (targetMemberRole == 'student_teacher' && event.newRole == 'member');
        }

        if (!canChangeRole) {
          emit(OrganisationsError("Insufficient permissions to change this role"));
          return;
        }

        // Update the member's role
        await firestore
            .collection('organisations')
            .doc(event.organisationId)
            .collection('members')
            .doc(event.memberId)
            .update({
          'role': event.newRole,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': uid,
        });

        // Fetch the updated list
        add(FetchOrganisationsEvent());
      } catch (e) {
        emit(OrganisationsError(e.toString()));
      }
    });

    on<RemoveMemberEvent>((event, emit) async {
      emit(OrganisationsLoading());
      try {
        String uid = auth.currentUser?.uid ?? '';
        if (uid.isEmpty) {
          emit(OrganisationsError("User not authenticated"));
          return;
        }

        // Get current user's role to check permissions
        QuerySnapshot currentUserSnapshot = await firestore
            .collection('organisations')
            .doc(event.organisationId)
            .collection('members')
            .where('uid', isEqualTo: uid)
            .get();

        if (currentUserSnapshot.docs.isEmpty) {
          emit(OrganisationsError("User not found in organization"));
          return;
        }

        Map<String, dynamic> currentUserData = currentUserSnapshot.docs.first.data() as Map<String, dynamic>;
        String currentUserRole = currentUserData['role'] ?? 'member';

        // Get target member's current role
        DocumentSnapshot targetMemberDoc = await firestore
            .collection('organisations')
            .doc(event.organisationId)
            .collection('members')
            .doc(event.memberId)
            .get();

        if (!targetMemberDoc.exists) {
          emit(OrganisationsError("Member not found"));
          return;
        }

        Map<String, dynamic> targetMemberData = targetMemberDoc.data() as Map<String, dynamic>;
        String targetMemberRole = targetMemberData['role'] ?? 'member';

        // Check permissions based on role hierarchy
        bool canRemove = false;
        if (currentUserRole == 'teacher') {
          // Teachers can remove anyone except other teachers
          canRemove = targetMemberRole != 'teacher';
        } else if (currentUserRole == 'student_teacher') {
          // Student teachers can only remove members
          canRemove = targetMemberRole == 'member';
        }

        if (!canRemove) {
          emit(OrganisationsError("Insufficient permissions to remove this member"));
          return;
        }

        // Remove the member
        await firestore
            .collection('organisations')
            .doc(event.organisationId)
            .collection('members')
            .doc(event.memberId)
            .delete();

        // Fetch the updated list
        add(FetchOrganisationsEvent());
      } catch (e) {
        emit(OrganisationsError(e.toString()));
      }
    });
  }
}

class FetchOrganisationsEvent extends OrganisationsEvent {}

class OrganisationsLoading extends OrganisationsState {}

class OrganisationsLoaded extends OrganisationsState {
  final List<Organisation> organisations;

  OrganisationsLoaded(this.organisations);
}

class OrganisationsError extends OrganisationsState {
  final String message;

  OrganisationsError(this.message);
}
