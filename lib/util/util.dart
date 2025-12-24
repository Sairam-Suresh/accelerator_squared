import 'dart:math';

import 'package:accelerator_squared/models/organisation.dart';
import 'package:accelerator_squared/models/projects.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Fetches user display name from Firestore users collection by UID
Future<String?> fetchUserDisplayNameByUid(
  FirebaseFirestore firestore,
  String uid,
) async {
  try {
    if (uid.isEmpty) return null;
    final userDoc = await firestore.collection('users').doc(uid).get();
    if (userDoc.exists) {
      final data = userDoc.data();
      return data?['displayName'] as String?;
    }
    return null;
  } catch (e) {
    print('Error fetching display name for UID $uid: $e');
    return null;
  }
}

/// Fetches user display name from Firestore users collection by email
Future<String?> fetchUserDisplayNameByEmail(
  FirebaseFirestore firestore,
  String email,
) async {
  try {
    if (email.isEmpty) return null;
    final userQuery = await firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (userQuery.docs.isNotEmpty) {
      final data = userQuery.docs.first.data();
      return data['displayName'] as String?;
    }
    return null;
  } catch (e) {
    print('Error fetching display name for email $email: $e');
    return null;
  }
}

/// Fetches user data (displayName, photoUrl) from Firestore by UID
Future<Map<String, dynamic>?> fetchUserDataByUid(
  FirebaseFirestore firestore,
  String uid,
) async {
  try {
    if (uid.isEmpty) return null;
    final userDoc = await firestore.collection('users').doc(uid).get();
    if (userDoc.exists) {
      return userDoc.data();
    }
    return null;
  } catch (e) {
    print('Error fetching user data for UID $uid: $e');
    return null;
  }
}

/// Fetches user data (displayName, photoUrl) from Firestore by email
Future<Map<String, dynamic>?> fetchUserDataByEmail(
  FirebaseFirestore firestore,
  String email,
) async {
  try {
    if (email.isEmpty) return null;
    final userQuery = await firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (userQuery.docs.isNotEmpty) {
      return userQuery.docs.first.data();
    }
    return null;
  } catch (e) {
    print('Error fetching user data for email $email: $e');
    return null;
  }
}

/// Batch fetches user display names for multiple UIDs
Future<Map<String, String?>> batchFetchUserDisplayNamesByUids(
  FirebaseFirestore firestore,
  List<String> uids,
) async {
  final Map<String, String?> result = {};
  if (uids.isEmpty) return result;

  try {
    // Filter out empty UIDs
    final validUids = uids.where((uid) => uid.isNotEmpty).toList();
    if (validUids.isEmpty) return result;

    // Batch fetch users (Firestore allows up to 10 items in 'whereIn', so we need to chunk)
    const batchSize = 10;
    for (int i = 0; i < validUids.length; i += batchSize) {
      final batch = validUids.skip(i).take(batchSize).toList();
      final userQuery = await firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: batch)
          .get();

      for (var doc in userQuery.docs) {
        final data = doc.data();
        result[doc.id] = data['displayName'] as String?;
      }
    }

    // Fill in nulls for UIDs that weren't found
    for (var uid in validUids) {
      if (!result.containsKey(uid)) {
        result[uid] = null;
      }
    }
  } catch (e) {
    print('Error batch fetching display names: $e');
    // Fill in nulls for all UIDs on error
    for (var uid in uids) {
      if (uid.isNotEmpty && !result.containsKey(uid)) {
        result[uid] = null;
      }
    }
  }
  return result;
}

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

    // Query by uid first
    QuerySnapshot uidMembersSnapshot = await firestore
        .collection('organisations')
        .doc(orgId)
        .collection('members')
        .where('uid', isEqualTo: uid)
        .get()
        .timeout(const Duration(seconds: 5));

    QuerySnapshot emailMembersSnapshot;
    
    // Always query by email if available, to catch memberships that might
    // only be stored with email (not uid) in the document
    if (userEmail.isNotEmpty) {
      emailMembersSnapshot = await firestore
          .collection('organisations')
          .doc(orgId)
          .collection('members')
          .where('email', isEqualTo: userEmail)
          .get()
          .timeout(const Duration(seconds: 5));
    } else {
      emailMembersSnapshot = uidMembersSnapshot;
    }

    // Use the first available membership document (prefer uid match, but fallback to email)
    QuerySnapshot membersSnapshot = uidMembersSnapshot.docs.isNotEmpty
        ? uidMembersSnapshot
        : emailMembersSnapshot;

    if (membersSnapshot.docs.isEmpty) {
      // User is not a member of this organization, return null
      return null;
    }

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
  } catch (e) {
    // Silently handle individual organisation loading errors to prevent one bad org from breaking the entire list
    print('Error loading organisation $orgId: $e');
    return null;
  }
}
