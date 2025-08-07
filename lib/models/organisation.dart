import 'package:accelerator_squared/models/projects.dart';

class Organisation {
  final String id;
  final String name;
  final String description;
  final List<StudentInOrganisation> students;
  final List<Project> projects;
  final List<ProjectRequest> projectRequests;
  final List<MilestoneReviewRequest> milestoneReviewRequests;
  final int memberCount;
  final String userRole; // 'teacher', 'student_teacher', or 'member'
  final String joinCode; // 6-character join code

  Organisation({
    required this.id,
    required this.name,
    required this.description,
    required this.students,
    required this.projects,
    required this.projectRequests,
    required this.milestoneReviewRequests,
    required this.memberCount,
    required this.userRole,
    required this.joinCode,
  });
}

enum UserInOrganisationType { student, teacher, studentTeacher }

class Student {
  final String name;
  final String email;
  final Uri? photoUrl;

  const Student({
    required this.name,
    required this.email,
    required this.photoUrl,
  });
}

class StudentInOrganisation extends Student {
  final UserInOrganisationType type;

  const StudentInOrganisation({
    required super.name,
    required super.email,
    required super.photoUrl,
    required this.type,
  });
}
