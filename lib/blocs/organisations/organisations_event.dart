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
