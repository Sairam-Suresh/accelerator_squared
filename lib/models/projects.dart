import 'package:equatable/equatable.dart';

class Project extends Equatable {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Project({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, name, description, createdAt, updatedAt];
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
      memberEmails: (json['memberEmails'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
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
  List<Object?> get props => [id, title, description, requestedBy, requesterEmail, requestedAt, memberEmails];
}
