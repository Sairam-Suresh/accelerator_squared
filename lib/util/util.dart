import 'dart:math';

import 'package:accelerator_squared/models/organisation.dart';
import 'package:accelerator_squared/models/projects.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

String generateJoinCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random();
  return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
}

Future<Organisation?> loadOrganisationDataById(
  FirebaseFirestore firestore,
  String orgId,
  String uid,
  String userEmail,
) async {
  try {
    DocumentSnapshot orgDoc = await firestore
        .collection('organisations')
        .doc(orgId)
        .get()
        .timeout(const Duration(seconds: 5));

    if (!orgDoc.exists) return null;

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
      Map<String, dynamic> memberData =
          membersSnapshot.docs.first.data() as Map<String, dynamic>;
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

      List<QuerySnapshot> results = await Future.wait(
        subcollectionQueries,
      ).timeout(const Duration(seconds: 10));
      QuerySnapshot projectsSnapshot = results[0];
      QuerySnapshot projectRequestsSnapshot = results[1];
      QuerySnapshot membersCountSnapshot = results[2];

      List<Project> projects =
          projectsSnapshot.docs.map((projectDoc) {
            final projectData = projectDoc.data() as Map<String, dynamic>;
            projectData['id'] =
                projectDoc.id; // Add the document ID to the data
            return Project.fromJson(projectData);
          }).toList();

      List<ProjectRequest> projectRequests =
          projectRequestsSnapshot.docs.map((requestDoc) {
            final requestData = requestDoc.data() as Map<String, dynamic>;
            requestData['id'] =
                requestDoc.id; // Add the document ID to the data
            return ProjectRequest.fromJson(requestData);
          }).toList();

      List<MilestoneReviewRequest> milestoneReviewRequests = [];
      QuerySnapshot milestoneReviewRequestsSnapshot =
          await firestore
              .collection('organisations')
              .doc(orgId)
              .collection('milestoneReviewRequests')
              .get();
      for (var requestDoc in milestoneReviewRequestsSnapshot.docs) {
        final requestData = requestDoc.data() as Map<String, dynamic>;
        requestData['id'] = requestDoc.id; // Add the document ID to the data
        milestoneReviewRequests.add(
          MilestoneReviewRequest.fromJson(requestData),
        );
      }

      return Organisation(
        id: orgId,
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        students: [],
        projects: projects,
        projectRequests: projectRequests,
        memberCount: membersCountSnapshot.docs.length,
        userRole: userRole,
        joinCode: data['joinCode'] ?? '',
        milestoneReviewRequests: milestoneReviewRequests,
      );
    }
  } catch (e) {
    // Silently handle individual organisation loading errors to prevent one bad org from breaking the entire list
  }

  throw "";
}
