import 'dart:math';

import 'package:accelerator_squared/models/organisation.dart';
import 'package:accelerator_squared/models/projects.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

String generateJoinCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random();
  return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
}

Future<Organisation> loadOrganisationDataById(
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

    if (!orgDoc.exists) throw Exception('Organisation not found');

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
            return Project(
              id: projectDoc.id,
              title: projectData['title'] ?? projectData['Name'] ?? '',
              description:
                  projectData['description'] ??
                  projectData['Description'] ??
                  '',
              createdAt:
                  projectData['createdAt'] != null
                      ? (projectData['createdAt'] is String
                          ? DateTime.parse(projectData['createdAt'])
                          : (projectData['createdAt'] as Timestamp).toDate())
                      : DateTime.now(),
              updatedAt:
                  projectData['updatedAt'] != null
                      ? (projectData['updatedAt'] is String
                          ? DateTime.parse(projectData['updatedAt'])
                          : (projectData['updatedAt'] as Timestamp).toDate())
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
                          : (requestData['requestedAt'] as Timestamp).toDate())
                      : DateTime.now(),
              memberEmails:
                  (requestData['memberEmails'] as List<dynamic>?)
                      ?.map((e) => e as String)
                      .toList() ??
                  [],
            );
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
        milestoneReviewRequests.add(
          MilestoneReviewRequest.fromJson(requestData),
        );
      }

      List<TaskReviewRequest> taskReviewRequests = [];
      QuerySnapshot taskReviewRequestsSnapshot =
          await firestore
              .collection('organisations')
              .doc(orgId)
              .collection('taskReviewRequests')
              .get();
      for (var requestDoc in taskReviewRequestsSnapshot.docs) {
        final requestData = requestDoc.data() as Map<String, dynamic>;
        taskReviewRequests.add(TaskReviewRequest.fromJson(requestData));
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
        taskReviewRequests: taskReviewRequests,
      );
    }
  } catch (e) {
    throw e;
    // Silently handle individual organisation loading errors to prevent one bad org from breaking the entire list
  }

  throw Exception('Failed to load organisation data');
}
