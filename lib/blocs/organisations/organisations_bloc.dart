import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';
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
            organisations.add(
              Organisation(
                name: data['name'] ?? '',
                description: data['description'] ?? '',
                students: [], // Adjust this if students data is nested
                projects: [], // Adjust this if projects data is nested
              ),
            );
          }
        }

        emit(OrganisationsLoaded(organisations));
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
