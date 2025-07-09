import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Project extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Project({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  String get name => title;

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      title: json['title'] as String? ?? json['name'] as String? ?? '',
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, title, description, createdAt, updatedAt];
}

class ProjectRequest extends Equatable {
  final String id;
  final String title;
  final String description;
  final String requestedBy;
  final String requesterEmail;
  final DateTime requestedAt;
  final List<String> memberEmails;

  const ProjectRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.requestedBy,
    required this.requesterEmail,
    required this.requestedAt,
    required this.memberEmails,
  });

  factory ProjectRequest.fromJson(Map<String, dynamic> json) {
    return ProjectRequest(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      requestedBy: json['requestedBy'] as String,
      requesterEmail: json['requesterEmail'] as String,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      memberEmails:
          (json['memberEmails'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'requestedBy': requestedBy,
      'requesterEmail': requesterEmail,
      'requestedAt': requestedAt.toIso8601String(),
      'memberEmails': memberEmails,
    };
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    requestedBy,
    requesterEmail,
    requestedAt,
    memberEmails,
  ];
}

class MilestoneReviewRequest extends Equatable {
  final String id;
  final String milestoneId;
  final String milestoneName;
  final String projectId;
  final String projectName;
  final bool isOrgWide;
  final DateTime dueDate;
  final DateTime sentForReviewAt;

  const MilestoneReviewRequest({
    required this.id,
    required this.milestoneId,
    required this.milestoneName,
    required this.projectId,
    required this.projectName,
    required this.isOrgWide,
    required this.dueDate,
    required this.sentForReviewAt,
  });

  factory MilestoneReviewRequest.fromJson(Map<String, dynamic> json) {
    return MilestoneReviewRequest(
      id: json['id'] as String,
      milestoneId: json['milestoneId'] as String,
      milestoneName: json['milestoneName'] as String,
      projectId: json['projectId'] as String,
      projectName: json['projectName'] as String,
      isOrgWide: json['isOrgWide'] as bool,
      dueDate:
          json['dueDate'] is String
              ? DateTime.parse(json['dueDate'])
              : (json['dueDate'] as Timestamp).toDate(),
      sentForReviewAt:
          json['sentForReviewAt'] is String
              ? DateTime.parse(json['sentForReviewAt'])
              : (json['sentForReviewAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'milestoneId': milestoneId,
      'milestoneName': milestoneName,
      'projectId': projectId,
      'projectName': projectName,
      'isOrgWide': isOrgWide,
      'dueDate': dueDate.toIso8601String(),
      'sentForReviewAt': sentForReviewAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    milestoneId,
    milestoneName,
    projectId,
    projectName,
    isOrgWide,
    dueDate,
    sentForReviewAt,
  ];
}

class TaskReviewRequest extends Equatable {
  final String id;
  final String taskId;
  final String taskName;
  final String milestoneId;
  final String milestoneName;
  final String projectId;
  final String projectName;
  final DateTime dueDate;
  final DateTime sentForReviewAt;

  const TaskReviewRequest({
    required this.id,
    required this.taskId,
    required this.taskName,
    required this.milestoneId,
    required this.milestoneName,
    required this.projectId,
    required this.projectName,
    required this.dueDate,
    required this.sentForReviewAt,
  });

  factory TaskReviewRequest.fromJson(Map<String, dynamic> json) {
    return TaskReviewRequest(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      taskName: json['taskName'] as String,
      milestoneId: json['milestoneId'] as String,
      milestoneName: json['milestoneName'] as String,
      projectId: json['projectId'] as String,
      projectName: json['projectName'] as String,
      dueDate:
          json['dueDate'] is String
              ? DateTime.parse(json['dueDate'])
              : (json['dueDate'] as Timestamp).toDate(),
      sentForReviewAt:
          json['sentForReviewAt'] is String
              ? DateTime.parse(json['sentForReviewAt'])
              : (json['sentForReviewAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'taskName': taskName,
      'milestoneId': milestoneId,
      'milestoneName': milestoneName,
      'projectId': projectId,
      'projectName': projectName,
      'dueDate': dueDate.toIso8601String(),
      'sentForReviewAt': sentForReviewAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    taskId,
    taskName,
    milestoneId,
    milestoneName,
    projectId,
    projectName,
    dueDate,
    sentForReviewAt,
  ];
}
