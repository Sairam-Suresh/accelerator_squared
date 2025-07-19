import 'package:accelerator_squared/blocs/organisation/organisation_bloc.dart';
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
          emit(OrganisationsLoaded([]));
          return;
        }

        Set<String> orgIds =
            allMemberships
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

        await orgRef.collection('members').doc(uid).set({
          'role': 'teacher',
          'email': auth.currentUser?.email ?? '',
          'uid': uid,
          'status': 'active',
          'addedAt': FieldValue.serverTimestamp(),
          'addedBy': uid,
        });

        for (String email in event.memberEmails) {
          if (email == auth.currentUser?.email) continue;
          // TODO: Lookup UID by email if possible. For now, use email as fallback for doc ID.
          await orgRef.collection('members').doc(email).set({
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
          emit(
            OrganisationsError("You are already a member of this organisation"),
          );
          return;
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
      emit(OrganisationsLoading());
      try {
        String uid = auth.currentUser?.uid ?? '';
        String userEmail = auth.currentUser?.email ?? '';

        if (uid.isEmpty) {
          emit(OrganisationsError("User not authenticated"));
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
          emit(OrganisationsError("User not found in organisation"));
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
            emit(
              OrganisationsError(
                "Cannot leave organisation. You are the last teacher. Please assign another teacher before leaving.",
              ),
            );
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
  }
}
