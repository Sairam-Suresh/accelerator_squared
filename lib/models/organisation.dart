import 'package:accelerator_squared/models/projects.dart';

class Organisation {
  final String id;
  final String name;
  final String description;
  final List<StudentInOrganisation> students;
  final List<Project> projects;
  final List<ProjectRequest> projectRequests;
  final int memberCount;
  final String userRole; // 'teacher', 'student_teacher', or 'member'

  Organisation({
    required this.id,
    required this.name,
    required this.description,
    required this.students,
    required this.projects,
    required this.projectRequests,
    required this.memberCount,
    required this.userRole,
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
