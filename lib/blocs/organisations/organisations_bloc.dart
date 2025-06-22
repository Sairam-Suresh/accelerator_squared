import 'dart:math';
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
          emit(OrganisationsLoaded(organisations));
          return;
        }

        Set<String> orgIds = allMemberships
            .map((doc) => doc.reference.parent.parent?.id)
            .where((id) => id != null)
            .cast<String>()
            .toSet();

        List<Future<void>> organisationFutures = [];
        
        for (String orgId in orgIds) {
          organisationFutures.add(_loadOrganisationDataById(orgId, uid, userEmail, organisations));
        }

        await Future.wait(organisationFutures).timeout(const Duration(seconds: 15));

        emit(OrganisationsLoaded(organisations));
      } catch (e) {
        if (e.toString().contains('timeout')) {
          emit(OrganisationsError("Request timed out. Please check your connection and try again."));
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
        String joinCode = _generateJoinCode();

        await orgRef.set({
          'name': event.name,
          'description': event.description,
          'joinCode': joinCode,
        });

        await orgRef.collection('members').doc().set({
          'role': 'teacher',
          'email': auth.currentUser?.email ?? '',
          'uid': uid,
          'status': 'active',
          'addedAt': FieldValue.serverTimestamp(),
          'addedBy': uid,
        });

        for (String email in event.memberEmails) {
          if (email == auth.currentUser?.email) continue;

          await orgRef.collection('members').doc().set({
            'role': 'member',
            'email': email,
            'status': 'active',
            'addedAt': FieldValue.serverTimestamp(),
            'addedBy': uid,
          });
        }

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

        QuerySnapshot userSnapshot = await firestore
            .collection('organisations')
            .doc(event.organisationId)
            .collection('members')
            .where('uid', isEqualTo: uid)
            .get();

        if (userSnapshot.docs.isEmpty) {
          emit(OrganisationsError("User not found in organisation"));
          return;
        }

        Map<String, dynamic> userData = userSnapshot.docs.first.data() as Map<String, dynamic>;
        String userRole = userData['role'] ?? 'member';

        if (userRole != 'teacher') {
          emit(OrganisationsError("Only teachers can create projects directly. Please submit a project request instead."));
          return;
        }

        String projectId = const Uuid().v4();
        DocumentReference projectRef = firestore
            .collection('organisations')
            .doc(event.organisationId)
            .collection('projects')
            .doc(projectId);

        await projectRef.set({
          'title': event.title,
          'description': event.description,
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

        List<String> filteredMemberEmails = [];
        for (String email in event.memberEmails) {
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
            filteredMemberEmails.add(email);
          }
        }

        String requestId = const Uuid().v4();
        DocumentReference requestRef = firestore
            .collection('organisations')
            .doc(event.organisationId)
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

        QuerySnapshot userSnapshot = await firestore
            .collection('organisations')
            .doc(event.organisationId)
            .collection('members')
            .where('uid', isEqualTo: uid)
            .get();

        if (userSnapshot.docs.isEmpty) {
          emit(OrganisationsError("User not found in organisation"));
          return;
        }

        Map<String, dynamic> userData = userSnapshot.docs.first.data() as Map<String, dynamic>;
        String userRole = userData['role'] ?? 'member';

        if (userRole != 'teacher') {
          emit(OrganisationsError("Only teachers can approve project requests"));
          return;
        }

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
            .doc(event.organisationId)
            .collection('projectRequests')
            .doc(event.requestId)
            .delete();

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

        QuerySnapshot userSnapshot = await firestore
            .collection('organisations')
            .doc(event.organisationId)
            .collection('members')
            .where('uid', isEqualTo: uid)
            .get();

        if (userSnapshot.docs.isEmpty) {
          emit(OrganisationsError("User not found in organisation"));
          return;
        }

        Map<String, dynamic> userData = userSnapshot.docs.first.data() as Map<String, dynamic>;
        String userRole = userData['role'] ?? 'member';

        if (userRole != 'teacher') {
          emit(OrganisationsError("Only teachers can reject project requests"));
          return;
        }

        await firestore
            .collection('organisations')
            .doc(event.organisationId)
            .collection('projectRequests')
            .doc(event.requestId)
            .delete();

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

        await orgRef.collection('members').doc().set({
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

    on<RefreshJoinCodeEvent>((event, emit) async {
      emit(OrganisationsLoading());
      try {
        String uid = auth.currentUser?.uid ?? '';
        if (uid.isEmpty) {
          emit(OrganisationsError("User not authenticated"));
          return;
        }

        // Check if user is a teacher in the organisation
        QuerySnapshot userSnapshot = await firestore
            .collection('organisations')
            .doc(event.organisationId)
            .collection('members')
            .where('uid', isEqualTo: uid)
            .get();

        if (userSnapshot.docs.isEmpty) {
          emit(OrganisationsError("User not found in organisation"));
          return;
        }

        Map<String, dynamic> userData = userSnapshot.docs.first.data() as Map<String, dynamic>;
        String userRole = userData['role'] ?? 'member';

        if (userRole != 'teacher') {
          emit(OrganisationsError("Only teachers can refresh join codes"));
          return;
        }

        // Generate new join code
        String newJoinCode = _generateJoinCode();

        // Update the organisation document
        await firestore
            .collection('organisations')
            .doc(event.organisationId)
            .update({
          'joinCode': newJoinCode,
        });

        add(FetchOrganisationsEvent());
      } catch (e) {
        emit(OrganisationsError(e.toString()));
      }
    });

    on<JoinOrganisationByCodeEvent>((event, emit) async {
      emit(OrganisationsLoading());
      try {
        String uid = auth.currentUser?.uid ?? '';
        String userEmail = auth.currentUser?.email ?? '';
        
        if (uid.isEmpty) {
          emit(OrganisationsError("User not authenticated"));
          return;
        }

        // Find organisation by join code
        QuerySnapshot orgSnapshot = await firestore
            .collection('organisations')
            .where('joinCode', isEqualTo: event.joinCode.toUpperCase())
            .get();

        if (orgSnapshot.docs.isEmpty) {
          emit(OrganisationsError("Invalid join code"));
          return;
        }

        String orgId = orgSnapshot.docs.first.id;

        // Check if user is already a member (try by uid first, then email)
        QuerySnapshot memberSnapshot = await firestore
            .collection('organisations')
            .doc(orgId)
            .collection('members')
            .where('uid', isEqualTo: uid)
            .get();

        // If not found by uid, try by email
        if (memberSnapshot.docs.isEmpty && userEmail.isNotEmpty) {
          memberSnapshot = await firestore
              .collection('organisations')
              .doc(orgId)
              .collection('members')
              .where('email', isEqualTo: userEmail)
              .get();
        }

        if (memberSnapshot.docs.isNotEmpty) {
          emit(OrganisationsError("You are already a member of this organisation"));
          return;
        }

        // Add user to organisation
        await firestore
            .collection('organisations')
            .doc(orgId)
            .collection('members')
            .doc()
            .set({
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

    on<DeleteProjectEvent>((event, emit) async {
      emit(OrganisationsLoading());
      try {
        String uid = auth.currentUser?.uid ?? '';
        if (uid.isEmpty) {
          emit(OrganisationsError("User not authenticated"));
          return;
        }

        // Check if user is a teacher in the organisation
        QuerySnapshot userSnapshot = await firestore
            .collection('organisations')
            .doc(event.organisationId)
            .collection('members')
            .where('uid', isEqualTo: uid)
            .get();

        if (userSnapshot.docs.isEmpty) {
          emit(OrganisationsError("User not found in organisation"));
          return;
        }

        Map<String, dynamic> userData = userSnapshot.docs.first.data() as Map<String, dynamic>;
        String userRole = userData['role'] ?? 'member';

        if (userRole != 'teacher') {
          emit(OrganisationsError("Only teachers can delete projects"));
          return;
        }

        // Delete the project and all its subcollections
        await firestore
            .collection('organisations')
            .doc(event.organisationId)
            .collection('projects')
            .doc(event.projectId)
            .delete();

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
        QuerySnapshot userSnapshot = await firestore
            .collection('organisations')
            .doc(event.organisationId)
            .collection('members')
            .where('uid', isEqualTo: uid)
            .get();

        if (userSnapshot.docs.isEmpty) {
          emit(OrganisationsError("User not found in organisation"));
          return;
        }

        Map<String, dynamic> userData = userSnapshot.docs.first.data() as Map<String, dynamic>;
        String userRole = userData['role'] ?? 'member';

        if (userRole != 'teacher') {
          emit(OrganisationsError("Only teachers can delete organisations"));
          return;
        }

        // Delete all subcollections first
        List<String> subcollections = ['members', 'projects', 'projectRequests'];
        
        for (String subcollection in subcollections) {
          QuerySnapshot subcollectionSnapshot = await firestore
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

    on<ChangeMemberRoleEvent>((event, emit) async {
      emit(OrganisationsLoading());
      try {
        String uid = auth.currentUser?.uid ?? '';
        if (uid.isEmpty) {
          emit(OrganisationsError("User not authenticated"));
          return;
        }

        // Check if user has permission to change roles
        QuerySnapshot userSnapshot = await firestore
            .collection('organisations')
            .doc(event.organisationId)
            .collection('members')
            .where('uid', isEqualTo: uid)
            .get();

        if (userSnapshot.docs.isEmpty) {
          emit(OrganisationsError("User not found in organisation"));
          return;
        }

        Map<String, dynamic> userData = userSnapshot.docs.first.data() as Map<String, dynamic>;
        String userRole = userData['role'] ?? 'member';

        if (userRole != 'teacher' && userRole != 'student_teacher') {
          emit(OrganisationsError("Only teachers and student teachers can change member roles"));
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
        });

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

        // Check if user has permission to remove members
        QuerySnapshot userSnapshot = await firestore
            .collection('organisations')
            .doc(event.organisationId)
            .collection('members')
            .where('uid', isEqualTo: uid)
            .get();

        if (userSnapshot.docs.isEmpty) {
          emit(OrganisationsError("User not found in organisation"));
          return;
        }

        Map<String, dynamic> userData = userSnapshot.docs.first.data() as Map<String, dynamic>;
        String userRole = userData['role'] ?? 'member';

        if (userRole != 'teacher' && userRole != 'student_teacher') {
          emit(OrganisationsError("Only teachers and student teachers can remove members"));
          return;
        }

        // Remove the member
        await firestore
            .collection('organisations')
            .doc(event.organisationId)
            .collection('members')
            .doc(event.memberId)
            .delete();

        add(FetchOrganisationsEvent());
      } catch (e) {
        emit(OrganisationsError(e.toString()));
      }
    });

    on<LeaveOrganisationEvent>((event, emit) async {
      emit(OrganisationsLoading());
      try {
        String uid = auth.currentUser?.uid ?? '';
        if (uid.isEmpty) {
          emit(OrganisationsError("User not authenticated"));
          return;
        }

        // Get the current user's member document
        QuerySnapshot userSnapshot = await firestore
            .collection('organisations')
            .doc(event.organisationId)
            .collection('members')
            .where('uid', isEqualTo: uid)
            .get();

        if (userSnapshot.docs.isEmpty) {
          emit(OrganisationsError("User not found in organisation"));
          return;
        }

        Map<String, dynamic> userData = userSnapshot.docs.first.data() as Map<String, dynamic>;
        String userRole = userData['role'] ?? 'member';
        String userMemberId = userSnapshot.docs.first.id;

        // If user is a teacher, check if they are the last teacher
        if (userRole == 'teacher') {
          QuerySnapshot teachersSnapshot = await firestore
              .collection('organisations')
              .doc(event.organisationId)
              .collection('members')
              .where('role', isEqualTo: 'teacher')
              .get();

          if (teachersSnapshot.docs.length <= 1) {
            emit(OrganisationsError("Cannot leave organisation. You are the last teacher. Please assign another teacher before leaving."));
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
        emit(OrganisationsError(e.toString()));
      }
    });

    on<UpdateOrganisationEvent>((event, emit) async {
      emit(OrganisationsLoading());
      try {
        String uid = auth.currentUser?.uid ?? '';
        String userEmail = auth.currentUser?.email ?? '';
        
        if (uid.isEmpty) {
          emit(OrganisationsError("User not authenticated"));
          return;
        }

        // Check if user is a teacher or student teacher
        QuerySnapshot userSnapshot = await firestore
            .collection('organisations')
            .doc(event.organisationId)
            .collection('members')
            .where('uid', isEqualTo: uid)
            .get();

        // If not found by uid, try by email
        if (userSnapshot.docs.isEmpty && userEmail.isNotEmpty) {
          userSnapshot = await firestore
              .collection('organisations')
              .doc(event.organisationId)
              .collection('members')
              .where('email', isEqualTo: userEmail)
              .get();
        }

        if (userSnapshot.docs.isEmpty) {
          emit(OrganisationsError("User not found in organisation"));
          return;
        }

        Map<String, dynamic> userData = userSnapshot.docs.first.data() as Map<String, dynamic>;
        String userRole = userData['role'] ?? 'member';

        if (userRole != 'teacher' && userRole != 'student_teacher') {
          emit(OrganisationsError("Only teachers and student teachers can update organisation information"));
          return;
        }

        // Update the organisation document
        await firestore
            .collection('organisations')
            .doc(event.organisationId)
            .update({
              'name': event.name,
              'description': event.description,
            });

        add(FetchOrganisationsEvent());
      } catch (e) {
        emit(OrganisationsError(e.toString()));
      }
    });
  }

  Future<void> _loadOrganisationDataById(
    String orgId,
    String uid,
    String userEmail,
    List<Organisation> organisations,
  ) async {
    try {
      DocumentSnapshot orgDoc = await firestore
          .collection('organisations')
          .doc(orgId)
          .get()
          .timeout(const Duration(seconds: 5));

      if (!orgDoc.exists) return;

      QuerySnapshot membersSnapshot = await firestore
          .collection('organisations')
          .doc(orgId)
          .collection('members')
          .where('uid', isEqualTo: uid)
          .get()
          .timeout(const Duration(seconds: 5));

      if (membersSnapshot.docs.isEmpty && userEmail.isNotEmpty) {
        membersSnapshot = await firestore
            .collection('organisations')
            .doc(orgId)
            .collection('members')
            .where('email', isEqualTo: userEmail)
            .get()
            .timeout(const Duration(seconds: 5));
      }

      if (membersSnapshot.docs.isNotEmpty) {
        Map<String, dynamic> data = orgDoc.data() as Map<String, dynamic>;
        Map<String, dynamic> memberData = membersSnapshot.docs.first.data() as Map<String, dynamic>;
        String userRole = memberData['role'] ?? 'member';

        List<Future<QuerySnapshot>> subcollectionQueries = [
          firestore
              .collection('organisations')
              .doc(orgId)
              .collection('projects')
              .get(),
          firestore
              .collection('organisations')
              .doc(orgId)
              .collection('projectRequests')
              .get(),
          firestore
              .collection('organisations')
              .doc(orgId)
              .collection('members')
              .get(),
        ];

        List<QuerySnapshot> results = await Future.wait(subcollectionQueries).timeout(const Duration(seconds: 10));
        QuerySnapshot projectsSnapshot = results[0];
        QuerySnapshot projectRequestsSnapshot = results[1];
        QuerySnapshot membersCountSnapshot = results[2];

        List<Project> projects = projectsSnapshot.docs.map((projectDoc) {
          final projectData = projectDoc.data() as Map<String, dynamic>;
          return Project(
            id: projectDoc.id,
            name: projectData['title'] ?? projectData['Name'] ?? '',
            description: projectData['description'] ?? projectData['Description'] ?? '',
            createdAt: projectData['createdAt'] != null
                ? (projectData['createdAt'] is String
                    ? DateTime.parse(projectData['createdAt'])
                    : (projectData['createdAt'] as Timestamp).toDate())
                : DateTime.now(),
            updatedAt: projectData['updatedAt'] != null
                ? (projectData['updatedAt'] is String
                    ? DateTime.parse(projectData['updatedAt'])
                    : (projectData['updatedAt'] as Timestamp).toDate())
                : DateTime.now(),
          );
        }).toList();

        List<ProjectRequest> projectRequests = projectRequestsSnapshot.docs.map((requestDoc) {
          final requestData = requestDoc.data() as Map<String, dynamic>;
          return ProjectRequest(
            id: requestDoc.id,
            title: requestData['title'] ?? '',
            description: requestData['description'] ?? '',
            requestedBy: requestData['requestedBy'] ?? '',
            requesterEmail: requestData['requesterEmail'] ?? '',
            requestedAt: requestData['requestedAt'] != null
                ? (requestData['requestedAt'] is String
                    ? DateTime.parse(requestData['requestedAt'])
                    : (requestData['requestedAt'] as Timestamp).toDate())
                : DateTime.now(),
            memberEmails: (requestData['memberEmails'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
          );
        }).toList();

        organisations.add(
          Organisation(
            id: orgId,
            name: data['name'] ?? '',
            description: data['description'] ?? '',
            students: [],
            projects: projects,
            projectRequests: projectRequests,
            memberCount: membersCountSnapshot.docs.length,
            userRole: userRole,
            joinCode: data['joinCode'] ?? '',
          ),
        );
      }
    } catch (e) {
      // Silently handle individual organisation loading errors to prevent one bad org from breaking the entire list
    }
  }

  String _generateJoinCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
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
