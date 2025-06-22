part of 'organisations_bloc.dart';

@immutable
sealed class OrganisationsEvent {}

class CreateOrganisationEvent extends OrganisationsEvent {
  final String name;
  final String description;
  final List<String> memberEmails;

  CreateOrganisationEvent({
    required this.name,
    required this.description,
    required this.memberEmails,
  });
}

class CreateProjectEvent extends OrganisationsEvent {
  final String organisationId;
  final String title;
  final String description;

  CreateProjectEvent({
    required this.organisationId,
    required this.title,
    required this.description,
  });
}
