import 'package:accelerator_squared/models/projects.dart';

class Organisation {
  final String name;
  final String description;
  final List<StudentInOrganisation> students;
  final List<Project> projects;

  Organisation({
    required this.name,
    required this.description,
    required this.students,
    required this.projects,
  });
}

enum UserInOrganisationType { student, teacher, studentteacher }

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
