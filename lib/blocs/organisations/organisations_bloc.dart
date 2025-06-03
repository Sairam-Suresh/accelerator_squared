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
          QuerySnapshot membersSnapshot =
              await firestore
                  .collection('organisations')
                  .doc(doc.id)
                  .collection('members')
                  .where(FieldPath.documentId, isEqualTo: uid)
                  .get();

          if (membersSnapshot.docs.isNotEmpty) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

            // Fetch projects subcollection for this organisation
            QuerySnapshot projectsSnapshot =
                await firestore
                    .collection('organisations')
                    .doc(doc.id)
                    .collection('projects')
                    .get();

            List<Project> projects =
                projectsSnapshot.docs.map((projectDoc) {
                  final projectData = projectDoc.data() as Map<String, dynamic>;
                  // Add id field if not present in Firestore
                  return Project(
                    id: projectDoc.id,
                    name: projectData['Name'] ?? '',
                    description: projectData['Description'] ?? '',
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

            organisations.add(
              Organisation(
                name: data['name'] ?? '',
                description: data['description'] ?? '',
                students: [], // Adjust this if students data is nested
                projects: projects,
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
        await orgRef.set({
          'name': event.name,
          'description': event.description,
        });
        // Add the current user to the members subcollection
        await orgRef.collection('members').doc(uid).set({'role': 'owner'});
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
